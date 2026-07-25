package httpapi

import (
	"encoding/json"
	"net/http"
	"strings"

	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/mphennrichs/achapramim/backend/internal/db/sqlcgen"
)

type ScanSettingsHandler struct {
	pool    *pgxpool.Pool
	queries *sqlcgen.Queries
}

func NewScanSettingsHandler(pool *pgxpool.Pool) *ScanSettingsHandler {
	return &ScanSettingsHandler{pool: pool, queries: sqlcgen.New(pool)}
}

type marketplaceScanIntervalRequest struct {
	MarketplaceSlug    string `json:"marketplace_slug"`
	MinIntervalMinutes int32  `json:"min_interval_minutes"`
	MaxIntervalMinutes int32  `json:"max_interval_minutes"`
}

type marketplaceScanIntervalResponse struct {
	MarketplaceSlug    string `json:"marketplace_slug"`
	MinIntervalMinutes int32  `json:"min_interval_minutes"`
	MaxIntervalMinutes int32  `json:"max_interval_minutes"`
}

type scanSettingsRequest struct {
	MinIntervalMinutes   int32                            `json:"min_interval_minutes"`
	MaxIntervalMinutes   int32                            `json:"max_interval_minutes"`
	DefaultCity          string                           `json:"default_city"`
	DefaultState         string                           `json:"default_state"`
	DefaultBlockedWords  []string                         `json:"default_blocked_words"`
	MarketplaceIntervals []marketplaceScanIntervalRequest `json:"marketplace_intervals"`
}

type scanSettingsResponse struct {
	MinIntervalMinutes   int32                             `json:"min_interval_minutes"`
	MaxIntervalMinutes   int32                             `json:"max_interval_minutes"`
	DefaultCity          string                            `json:"default_city"`
	DefaultState         string                            `json:"default_state"`
	DefaultBlockedWords  []string                          `json:"default_blocked_words"`
	MarketplaceIntervals []marketplaceScanIntervalResponse `json:"marketplace_intervals"`
}

// Get retorna a configuração global: intervalo de Scan (padrão e por
// marketplace), região padrão (usada quando um Watch não define
// city/state próprios) e o seed global de palavras bloqueadas (copiado
// para todo Watch novo na criação).
func (h *ScanSettingsHandler) Get(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	settings, err := h.queries.GetScanSettings(ctx)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal error")
		return
	}
	blockedWords, err := h.queries.ListDefaultBlockedWords(ctx)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal error")
		return
	}
	marketplaceIntervals, err := h.queries.ListMarketplaceScanSettings(ctx)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal error")
		return
	}
	writeJSON(w, http.StatusOK, toScanSettingsResponse(settings, blockedWords, marketplaceIntervals))
}

// Update altera a configuração global. Só admin acessa esta rota (ver
// router.go); afeta o agendamento e a região de busca padrão de todos os
// Watches do sistema, e o seed usado em novos Watches a partir de agora
// (não retroage sobre Watches já criados).
func (h *ScanSettingsHandler) Update(w http.ResponseWriter, r *http.Request) {
	var req scanSettingsRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	if req.MinIntervalMinutes < 1 {
		writeError(w, http.StatusBadRequest, "min_interval_minutes must be at least 1")
		return
	}
	if req.MaxIntervalMinutes < req.MinIntervalMinutes {
		writeError(w, http.StatusBadRequest, "max_interval_minutes must be >= min_interval_minutes")
		return
	}
	if req.DefaultCity == "" || req.DefaultState == "" {
		writeError(w, http.StatusBadRequest, "default_city and default_state are required")
		return
	}
	for _, mi := range req.MarketplaceIntervals {
		if mi.MinIntervalMinutes < 1 {
			writeError(w, http.StatusBadRequest, "marketplace min_interval_minutes must be at least 1")
			return
		}
		if mi.MaxIntervalMinutes < mi.MinIntervalMinutes {
			writeError(w, http.StatusBadRequest, "marketplace max_interval_minutes must be >= min_interval_minutes")
			return
		}
	}

	ctx := r.Context()
	tx, err := h.pool.Begin(ctx)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal error")
		return
	}
	defer tx.Rollback(ctx)

	q := sqlcgen.New(tx)

	settings, err := q.UpdateScanSettings(ctx, sqlcgen.UpdateScanSettingsParams{
		MinIntervalMinutes: req.MinIntervalMinutes,
		MaxIntervalMinutes: req.MaxIntervalMinutes,
		DefaultCity:        req.DefaultCity,
		DefaultState:       req.DefaultState,
	})
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal error")
		return
	}

	if err := q.ReplaceDefaultBlockedWords(ctx); err != nil {
		writeError(w, http.StatusInternalServerError, "internal error")
		return
	}
	blockedWords := make([]sqlcgen.DefaultBlockedWord, 0, len(req.DefaultBlockedWords))
	seen := make(map[string]bool, len(req.DefaultBlockedWords))
	for _, term := range req.DefaultBlockedWords {
		key := strings.ToLower(term)
		if seen[key] {
			continue
		}
		seen[key] = true
		word, err := q.AddDefaultBlockedWord(ctx, term)
		if err != nil {
			writeError(w, http.StatusBadRequest, "failed to add default blocked word: "+err.Error())
			return
		}
		blockedWords = append(blockedWords, word)
	}

	marketplaceSlugs := make([]string, len(req.MarketplaceIntervals))
	for i, mi := range req.MarketplaceIntervals {
		marketplaceSlugs[i] = mi.MarketplaceSlug
	}
	if err := q.DeleteMarketplaceScanSettingsNotIn(ctx, marketplaceSlugs); err != nil {
		writeError(w, http.StatusInternalServerError, "internal error")
		return
	}
	marketplaceIntervals := make([]sqlcgen.MarketplaceScanSetting, 0, len(req.MarketplaceIntervals))
	for _, mi := range req.MarketplaceIntervals {
		setting, err := q.UpsertMarketplaceScanSetting(ctx, sqlcgen.UpsertMarketplaceScanSettingParams{
			MarketplaceSlug:    mi.MarketplaceSlug,
			MinIntervalMinutes: mi.MinIntervalMinutes,
			MaxIntervalMinutes: mi.MaxIntervalMinutes,
		})
		if err != nil {
			writeError(w, http.StatusBadRequest, "failed to update marketplace interval: "+err.Error())
			return
		}
		marketplaceIntervals = append(marketplaceIntervals, setting)
	}

	if err := tx.Commit(ctx); err != nil {
		writeError(w, http.StatusInternalServerError, "internal error")
		return
	}

	writeJSON(w, http.StatusOK, toScanSettingsResponse(settings, blockedWords, marketplaceIntervals))
}

func toScanSettingsResponse(s sqlcgen.ScanSetting, blockedWords []sqlcgen.DefaultBlockedWord, marketplaceIntervals []sqlcgen.MarketplaceScanSetting) scanSettingsResponse {
	terms := make([]string, len(blockedWords))
	for i, b := range blockedWords {
		terms[i] = b.Term
	}
	intervals := make([]marketplaceScanIntervalResponse, len(marketplaceIntervals))
	for i, mi := range marketplaceIntervals {
		intervals[i] = marketplaceScanIntervalResponse{
			MarketplaceSlug:    mi.MarketplaceSlug,
			MinIntervalMinutes: mi.MinIntervalMinutes,
			MaxIntervalMinutes: mi.MaxIntervalMinutes,
		}
	}
	return scanSettingsResponse{
		MinIntervalMinutes:   s.MinIntervalMinutes,
		MaxIntervalMinutes:   s.MaxIntervalMinutes,
		DefaultCity:          s.DefaultCity,
		DefaultState:         s.DefaultState,
		DefaultBlockedWords:  terms,
		MarketplaceIntervals: intervals,
	}
}
