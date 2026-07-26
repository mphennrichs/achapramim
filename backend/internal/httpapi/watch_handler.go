package httpapi

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"strings"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/mphennrichs/achapramim/backend/internal/auth"
	"github.com/mphennrichs/achapramim/backend/internal/db/sqlcgen"
	"github.com/mphennrichs/achapramim/backend/internal/scan"
)

type WatchHandler struct {
	pool   *pgxpool.Pool
	runner *scan.Runner
}

func NewWatchHandler(pool *pgxpool.Pool, runner *scan.Runner) *WatchHandler {
	return &WatchHandler{pool: pool, runner: runner}
}

type watchRequest struct {
	Name                      string   `json:"name"`
	TargetPriceCents          int64    `json:"target_price_cents"`
	TolerancePercent          string   `json:"tolerance_percent"`
	MaxOffers                 int32    `json:"max_offers"`
	PriceDropThresholdPercent string   `json:"price_drop_threshold_percent"`
	Keywords                  []string `json:"keywords"`
	BlockedWords              []string `json:"blocked_words"`
	Marketplaces              []string `json:"marketplaces"`
	// City/State são opcionais — omitidos ou vazios, o Scan usa o padrão
	// global (Configurações Globais). Ver resolveRegion em scan/runner.go.
	City  *string `json:"city"`
	State *string `json:"state"`
	// "any" (padrão) ou "all" — ver keyword_match_mode na migration 000009 e
	// containsAllKeywords em scan/classification.go.
	KeywordMatchMode string `json:"keyword_match_mode"`
}

type setActiveRequest struct {
	Active bool `json:"active"`
}

type watchResponse struct {
	ID                        string   `json:"id"`
	UserID                    string   `json:"user_id"`
	Name                      string   `json:"name"`
	TargetPriceCents          int64    `json:"target_price_cents"`
	TolerancePercent          string   `json:"tolerance_percent"`
	MaxOffers                 int32    `json:"max_offers"`
	PriceDropThresholdPercent string   `json:"price_drop_threshold_percent"`
	Active                    bool     `json:"active"`
	Keywords                  []string `json:"keywords"`
	BlockedWords              []string `json:"blocked_words"`
	Marketplaces              []string `json:"marketplaces"`
	City                      *string  `json:"city"`
	State                     *string  `json:"state"`
	KeywordMatchMode          string   `json:"keyword_match_mode"`
	// Preenchidos só na listagem admin (GET /api/watches?all=true) — o dono
	// de um Watch é irrelevante nas demais respostas (o próprio User já sabe
	// quais Watches são seus).
	OwnerName  *string `json:"owner_name,omitempty"`
	OwnerEmail *string `json:"owner_email,omitempty"`
}

// Create cria um Watch para o User autenticado, junto de suas keywords,
// palavras bloqueadas e marketplaces, em uma única transação.
func (h *WatchHandler) Create(w http.ResponseWriter, r *http.Request) {
	claims, ok := auth.FromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "missing claims")
		return
	}

	var req watchRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	tolerance, err := pgNumeric(req.TolerancePercent)
	if err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	threshold, err := pgNumeric(req.PriceDropThresholdPercent)
	if err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	keywordMatchMode, err := parseKeywordMatchMode(req.KeywordMatchMode)
	if err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	if err := validateKeywords(req.Keywords); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}

	ctx := r.Context()
	tx, err := h.pool.Begin(ctx)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal error")
		return
	}
	defer tx.Rollback(ctx)

	q := sqlcgen.New(tx)

	watch, err := q.CreateWatch(ctx, sqlcgen.CreateWatchParams{
		UserID:                    parseUUID(claims.UserID),
		Name:                      req.Name,
		TargetPriceCents:          req.TargetPriceCents,
		TolerancePercent:          tolerance,
		MaxOffers:                 req.MaxOffers,
		PriceDropThresholdPercent: threshold,
		KeywordMatchMode:          keywordMatchMode,
		City:                      req.City,
		State:                     req.State,
	})
	if err != nil {
		writeError(w, http.StatusBadRequest, "failed to create watch: "+err.Error())
		return
	}

	// Seed global de palavras bloqueadas (Configurações Globais) é somado às
	// informadas pelo usuário na criação — nunca substitui, só complementa
	// (união, sem duplicatas). Só se aplica na criação, não em Update.
	req.BlockedWords, err = mergeWithDefaultBlockedWords(ctx, q, req.BlockedWords)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal error")
		return
	}

	if err := writeWatchChildren(ctx, q, watch.ID, req); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}

	if err := tx.Commit(ctx); err != nil {
		writeError(w, http.StatusInternalServerError, "internal error")
		return
	}

	// Primeiro Scan de cada marketplace roda imediatamente ao criar o
	// Alerta, em vez de esperar o próximo tick do Scheduler (até
	// ScanPollInterval de atraso) — os seguintes seguem o intervalo
	// aleatório normal configurado por marketplace (ver
	// RunWatchMarketplaceAndReschedule). Em goroutine própria com contexto
	// independente do request HTTP: a resposta não deve esperar o Scan
	// (chamadas de rede a Fetchers podem levar dezenas de segundos), e o
	// ctx do request morre assim que a resposta é enviada.
	for _, slug := range req.Marketplaces {
		go h.runner.RunWatchMarketplaceAndReschedule(context.Background(), watch, slug)
	}

	writeJSON(w, http.StatusCreated, watchResponse{
		ID:                        uuidString(watch.ID),
		UserID:                    uuidString(watch.UserID),
		Name:                      watch.Name,
		TargetPriceCents:          watch.TargetPriceCents,
		TolerancePercent:          numericString(watch.TolerancePercent),
		MaxOffers:                 watch.MaxOffers,
		PriceDropThresholdPercent: numericString(watch.PriceDropThresholdPercent),
		Active:                    watch.Active,
		Keywords:                  req.Keywords,
		BlockedWords:              req.BlockedWords,
		Marketplaces:              req.Marketplaces,
		City:                      watch.City,
		State:                     watch.State,
		KeywordMatchMode:          string(watch.KeywordMatchMode),
	})
}

// parseKeywordMatchMode valida o modo informado, com "any" como padrão
// quando o campo vem vazio (compatibilidade com clientes antigos que ainda
// não enviam esse campo).
func parseKeywordMatchMode(raw string) (sqlcgen.KeywordMatchMode, error) {
	switch raw {
	case "", string(sqlcgen.KeywordMatchModeAny):
		return sqlcgen.KeywordMatchModeAny, nil
	case string(sqlcgen.KeywordMatchModeAll):
		return sqlcgen.KeywordMatchModeAll, nil
	default:
		return "", errors.New("invalid keyword_match_mode: " + raw)
	}
}

// validateKeywords exige ao menos uma keyword não-vazia: no modo 'any' ela
// vira um filtro de inclusão (matchesAnyKeyword em scan/classification.go) —
// um Watch sem nenhuma keyword nunca excluiria anúncio nenhum por keyword,
// tornando o filtro inócuo e o campo sem sentido em qualquer modo.
func validateKeywords(keywords []string) error {
	for _, kw := range keywords {
		if strings.TrimSpace(kw) != "" {
			return nil
		}
	}
	return errors.New("at least one keyword is required")
}

// mergeWithDefaultBlockedWords retorna a união (sem duplicatas) entre as
// palavras bloqueadas informadas pelo usuário e o seed global (admin,
// Configurações Globais) — comparação case-insensitive para não duplicar
// "Quebrado" com "quebrado".
func mergeWithDefaultBlockedWords(ctx context.Context, q *sqlcgen.Queries, userWords []string) ([]string, error) {
	defaults, err := q.ListDefaultBlockedWords(ctx)
	if err != nil {
		return nil, err
	}

	seen := make(map[string]bool, len(userWords)+len(defaults))
	merged := make([]string, 0, len(userWords)+len(defaults))
	for _, term := range userWords {
		key := strings.ToLower(term)
		if !seen[key] {
			seen[key] = true
			merged = append(merged, term)
		}
	}
	for _, d := range defaults {
		key := strings.ToLower(d.Term)
		if !seen[key] {
			seen[key] = true
			merged = append(merged, d.Term)
		}
	}
	return merged, nil
}

// writeWatchChildren insere keywords, palavras bloqueadas e marketplaces de
// um Watch recém-criado. Assume listas vazias (Watch novo, sem filhos
// prévios) — não é reaproveitado para edição.
func writeWatchChildren(ctx context.Context, q *sqlcgen.Queries, watchID pgtype.UUID, req watchRequest) error {
	for _, term := range req.Keywords {
		if _, err := q.AddWatchKeyword(ctx, sqlcgen.AddWatchKeywordParams{WatchID: watchID, Term: term}); err != nil {
			return errors.New("failed to add keyword: " + err.Error())
		}
	}
	for _, term := range req.BlockedWords {
		if _, err := q.AddWatchBlockedWord(ctx, sqlcgen.AddWatchBlockedWordParams{WatchID: watchID, Term: term}); err != nil {
			return errors.New("failed to add blocked word: " + err.Error())
		}
	}
	for _, slug := range req.Marketplaces {
		if err := q.AddWatchMarketplace(ctx, sqlcgen.AddWatchMarketplaceParams{WatchID: watchID, MarketplaceSlug: slug}); err != nil {
			return errors.New("failed to add marketplace: " + err.Error())
		}
	}
	return nil
}

// Update substitui os campos escalares de um Watch e a totalidade de suas
// keywords, palavras bloqueadas e marketplaces (replace completo, não
// merge). O dono pode editar o próprio Watch; o admin pode editar o de
// qualquer User.
func (h *WatchHandler) Update(w http.ResponseWriter, r *http.Request) {
	claims, ok := auth.FromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "missing claims")
		return
	}

	var req watchRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	tolerance, err := pgNumeric(req.TolerancePercent)
	if err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	threshold, err := pgNumeric(req.PriceDropThresholdPercent)
	if err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	keywordMatchMode, err := parseKeywordMatchMode(req.KeywordMatchMode)
	if err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	if err := validateKeywords(req.Keywords); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}

	ctx := r.Context()
	watchID := parseUUID(chi.URLParam(r, "id"))

	tx, err := h.pool.Begin(ctx)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal error")
		return
	}
	defer tx.Rollback(ctx)

	q := sqlcgen.New(tx)

	if _, ok := getOwnedWatch(ctx, w, q, watchID, claims); !ok {
		return
	}

	watch, err := q.UpdateWatch(ctx, sqlcgen.UpdateWatchParams{
		ID:                        watchID,
		Name:                      req.Name,
		TargetPriceCents:          req.TargetPriceCents,
		TolerancePercent:          tolerance,
		MaxOffers:                 req.MaxOffers,
		PriceDropThresholdPercent: threshold,
		KeywordMatchMode:          keywordMatchMode,
		City:                      req.City,
		State:                     req.State,
	})
	if err != nil {
		writeError(w, http.StatusBadRequest, "failed to update watch: "+err.Error())
		return
	}

	if err := q.DeleteAllWatchKeywords(ctx, watchID); err != nil {
		writeError(w, http.StatusInternalServerError, "internal error")
		return
	}
	if err := q.DeleteAllWatchBlockedWords(ctx, watchID); err != nil {
		writeError(w, http.StatusInternalServerError, "internal error")
		return
	}
	if err := q.DeleteAllWatchMarketplaces(ctx, watchID); err != nil {
		writeError(w, http.StatusInternalServerError, "internal error")
		return
	}
	if err := writeWatchChildren(ctx, q, watchID, req); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}

	if err := tx.Commit(ctx); err != nil {
		writeError(w, http.StatusInternalServerError, "internal error")
		return
	}

	writeJSON(w, http.StatusOK, watchResponse{
		ID:                        uuidString(watch.ID),
		UserID:                    uuidString(watch.UserID),
		Name:                      watch.Name,
		TargetPriceCents:          watch.TargetPriceCents,
		TolerancePercent:          numericString(watch.TolerancePercent),
		MaxOffers:                 watch.MaxOffers,
		PriceDropThresholdPercent: numericString(watch.PriceDropThresholdPercent),
		Active:                    watch.Active,
		Keywords:                  req.Keywords,
		BlockedWords:              req.BlockedWords,
		Marketplaces:              req.Marketplaces,
		City:                      watch.City,
		State:                     watch.State,
		KeywordMatchMode:          string(watch.KeywordMatchMode),
	})
}

// Get retorna um Watch por ID. O dono sempre pode ver o próprio Watch;
// qualquer outro User (exceto admin) recebe 404 para não vazar a existência
// do recurso.
func (h *WatchHandler) Get(w http.ResponseWriter, r *http.Request) {
	claims, ok := auth.FromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "missing claims")
		return
	}

	ctx := r.Context()
	q := sqlcgen.New(h.pool)

	watch, ok := getOwnedWatch(ctx, w, q, parseUUID(chi.URLParam(r, "id")), claims)
	if !ok {
		return
	}

	resp, err := loadWatchResponse(ctx, q, watch)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal error")
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

// List retorna os Watches do User autenticado. Admin pode pedir todos os
// Watches de todos os Users via ?all=true (agrupados por User, para
// auditoria).
func (h *WatchHandler) List(w http.ResponseWriter, r *http.Request) {
	claims, ok := auth.FromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "missing claims")
		return
	}

	ctx := r.Context()
	q := sqlcgen.New(h.pool)

	if r.URL.Query().Get("all") == "true" && auth.IsAdmin(claims) {
		rows, err := q.ListAllWatchesWithOwner(ctx)
		if err != nil {
			writeError(w, http.StatusInternalServerError, "internal error")
			return
		}
		resp := make([]watchResponse, 0, len(rows))
		for _, row := range rows {
			watch := sqlcgen.Watch{
				ID:                        row.ID,
				UserID:                    row.UserID,
				Name:                      row.Name,
				TargetPriceCents:          row.TargetPriceCents,
				TolerancePercent:          row.TolerancePercent,
				MaxOffers:                 row.MaxOffers,
				PriceDropThresholdPercent: row.PriceDropThresholdPercent,
				Active:                    row.Active,
				NextScanAt:                row.NextScanAt,
				CreatedAt:                 row.CreatedAt,
				UpdatedAt:                 row.UpdatedAt,
				City:                      row.City,
				State:                     row.State,
				KeywordMatchMode:          row.KeywordMatchMode,
			}
			wr, err := loadWatchResponse(ctx, q, watch)
			if err != nil {
				writeError(w, http.StatusInternalServerError, "internal error")
				return
			}
			wr.OwnerName = &row.OwnerName
			wr.OwnerEmail = &row.OwnerEmail
			resp = append(resp, wr)
		}
		writeJSON(w, http.StatusOK, resp)
		return
	}

	watches, err := q.ListWatchesByUser(ctx, parseUUID(claims.UserID))
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal error")
		return
	}

	resp := make([]watchResponse, 0, len(watches))
	for _, watch := range watches {
		wr, err := loadWatchResponse(ctx, q, watch)
		if err != nil {
			writeError(w, http.StatusInternalServerError, "internal error")
			return
		}
		resp = append(resp, wr)
	}
	writeJSON(w, http.StatusOK, resp)
}

// SetActive ativa/inativa um Watch. O dono pode operar o próprio Watch; o
// admin pode operar o Watch de qualquer User.
func (h *WatchHandler) SetActive(w http.ResponseWriter, r *http.Request) {
	claims, ok := auth.FromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "missing claims")
		return
	}

	var req setActiveRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	ctx := r.Context()
	q := sqlcgen.New(h.pool)
	watchID := parseUUID(chi.URLParam(r, "id"))

	if _, ok := getOwnedWatch(ctx, w, q, watchID, claims); !ok {
		return
	}

	watch, err := q.SetWatchActive(ctx, sqlcgen.SetWatchActiveParams{ID: watchID, Active: req.Active})
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal error")
		return
	}

	resp, err := loadWatchResponse(ctx, q, watch)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal error")
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

// TriggerScan roda um Scan de cada marketplace do Watch imediatamente,
// fora do ciclo normal do Scheduler — admin-only (ver router.go), para
// diagnosticar/forçar atualização de um Watch específico sem esperar o
// próximo agendamento. Síncrono (não em goroutine): o admin que disparou
// quer ver o resultado na hora, diferente do primeiro Scan automático na
// criação do Watch (que não deve atrasar a resposta HTTP de criação). Um
// marketplace falhando não impede os demais de rodar.
func (h *WatchHandler) TriggerScan(w http.ResponseWriter, r *http.Request) {
	claims, ok := auth.FromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "missing claims")
		return
	}

	ctx := r.Context()
	q := sqlcgen.New(h.pool)
	watchID := parseUUID(chi.URLParam(r, "id"))

	watch, ok := getOwnedWatch(ctx, w, q, watchID, claims)
	if !ok {
		return
	}

	marketplaces, err := q.ListWatchMarketplaces(ctx, watchID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal error")
		return
	}

	var scanErrors []string
	for _, slug := range marketplaces {
		if err := h.runner.RunWatchMarketplace(ctx, watch, slug); err != nil {
			scanErrors = append(scanErrors, slug+": "+err.Error())
		}
	}
	if len(scanErrors) > 0 {
		writeError(w, http.StatusInternalServerError, "scan failed: "+strings.Join(scanErrors, "; "))
		return
	}

	resp, err := loadWatchResponse(ctx, q, watch)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal error")
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

// Delete remove um Watch permanentemente, junto de todo o histórico
// vinculado (Scans, Offers, Histórico de Preço, Notifications) via cascade.
// O dono pode excluir o próprio Watch; o admin pode excluir o de qualquer
// User.
func (h *WatchHandler) Delete(w http.ResponseWriter, r *http.Request) {
	claims, ok := auth.FromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "missing claims")
		return
	}

	ctx := r.Context()
	q := sqlcgen.New(h.pool)
	watchID := parseUUID(chi.URLParam(r, "id"))

	if _, ok := getOwnedWatch(ctx, w, q, watchID, claims); !ok {
		return
	}

	if err := q.DeleteWatch(ctx, watchID); err != nil {
		writeError(w, http.StatusInternalServerError, "internal error")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func loadWatchResponse(ctx context.Context, q *sqlcgen.Queries, watch sqlcgen.Watch) (watchResponse, error) {
	keywordRows, err := q.ListWatchKeywords(ctx, watch.ID)
	if err != nil {
		return watchResponse{}, err
	}
	blockedRows, err := q.ListWatchBlockedWords(ctx, watch.ID)
	if err != nil {
		return watchResponse{}, err
	}
	marketplaces, err := q.ListWatchMarketplaces(ctx, watch.ID)
	if err != nil {
		return watchResponse{}, err
	}

	keywords := make([]string, len(keywordRows))
	for i, k := range keywordRows {
		keywords[i] = k.Term
	}
	blockedWords := make([]string, len(blockedRows))
	for i, b := range blockedRows {
		blockedWords[i] = b.Term
	}

	return watchResponse{
		ID:                        uuidString(watch.ID),
		UserID:                    uuidString(watch.UserID),
		Name:                      watch.Name,
		TargetPriceCents:          watch.TargetPriceCents,
		TolerancePercent:          numericString(watch.TolerancePercent),
		MaxOffers:                 watch.MaxOffers,
		PriceDropThresholdPercent: numericString(watch.PriceDropThresholdPercent),
		Active:                    watch.Active,
		Keywords:                  keywords,
		BlockedWords:              blockedWords,
		Marketplaces:              marketplaces,
		City:                      watch.City,
		State:                     watch.State,
		KeywordMatchMode:          string(watch.KeywordMatchMode),
	}, nil
}
