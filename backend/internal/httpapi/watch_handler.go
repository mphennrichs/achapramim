package httpapi

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/mphennrichs/achapramim/backend/internal/auth"
	"github.com/mphennrichs/achapramim/backend/internal/db/sqlcgen"
)

type WatchHandler struct {
	pool *pgxpool.Pool
}

func NewWatchHandler(pool *pgxpool.Pool) *WatchHandler {
	return &WatchHandler{pool: pool}
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
	})
	if err != nil {
		writeError(w, http.StatusBadRequest, "failed to create watch: "+err.Error())
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
	})
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

	ctx := r.Context()
	watchID := parseUUID(chi.URLParam(r, "id"))

	tx, err := h.pool.Begin(ctx)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal error")
		return
	}
	defer tx.Rollback(ctx)

	q := sqlcgen.New(tx)

	existing, err := q.GetWatchByID(ctx, watchID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			writeError(w, http.StatusNotFound, "watch not found")
			return
		}
		writeError(w, http.StatusInternalServerError, "internal error")
		return
	}
	if uuidString(existing.UserID) != claims.UserID && !auth.IsAdmin(claims) {
		writeError(w, http.StatusNotFound, "watch not found")
		return
	}

	watch, err := q.UpdateWatch(ctx, sqlcgen.UpdateWatchParams{
		ID:                        watchID,
		Name:                      req.Name,
		TargetPriceCents:          req.TargetPriceCents,
		TolerancePercent:          tolerance,
		MaxOffers:                 req.MaxOffers,
		PriceDropThresholdPercent: threshold,
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

	watch, err := q.GetWatchByID(ctx, parseUUID(chi.URLParam(r, "id")))
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			writeError(w, http.StatusNotFound, "watch not found")
			return
		}
		writeError(w, http.StatusInternalServerError, "internal error")
		return
	}

	if uuidString(watch.UserID) != claims.UserID && !auth.IsAdmin(claims) {
		writeError(w, http.StatusNotFound, "watch not found")
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

	var watches []sqlcgen.Watch
	var err error
	if r.URL.Query().Get("all") == "true" && auth.IsAdmin(claims) {
		watches, err = q.ListAllWatchesGroupedByUser(ctx)
	} else {
		watches, err = q.ListWatchesByUser(ctx, parseUUID(claims.UserID))
	}
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

	existing, err := q.GetWatchByID(ctx, watchID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			writeError(w, http.StatusNotFound, "watch not found")
			return
		}
		writeError(w, http.StatusInternalServerError, "internal error")
		return
	}
	if uuidString(existing.UserID) != claims.UserID && !auth.IsAdmin(claims) {
		writeError(w, http.StatusNotFound, "watch not found")
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

	existing, err := q.GetWatchByID(ctx, watchID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			writeError(w, http.StatusNotFound, "watch not found")
			return
		}
		writeError(w, http.StatusInternalServerError, "internal error")
		return
	}
	if uuidString(existing.UserID) != claims.UserID && !auth.IsAdmin(claims) {
		writeError(w, http.StatusNotFound, "watch not found")
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
	}, nil
}
