package httpapi

import (
	"encoding/json"
	"net/http"

	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/mphennrichs/achapramim/backend/internal/db/sqlcgen"
)

type ScanSettingsHandler struct {
	queries *sqlcgen.Queries
}

func NewScanSettingsHandler(pool *pgxpool.Pool) *ScanSettingsHandler {
	return &ScanSettingsHandler{queries: sqlcgen.New(pool)}
}

type scanSettingsRequest struct {
	MinIntervalMinutes int32 `json:"min_interval_minutes"`
	MaxIntervalMinutes int32 `json:"max_interval_minutes"`
}

type scanSettingsResponse struct {
	MinIntervalMinutes int32 `json:"min_interval_minutes"`
	MaxIntervalMinutes int32 `json:"max_interval_minutes"`
}

// Get retorna a configuração global de Scan (intervalo mín/máx entre
// execuções de cada Watch).
func (h *ScanSettingsHandler) Get(w http.ResponseWriter, r *http.Request) {
	settings, err := h.queries.GetScanSettings(r.Context())
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal error")
		return
	}
	writeJSON(w, http.StatusOK, toScanSettingsResponse(settings))
}

// Update altera a configuração global de Scan. Só admin acessa esta rota
// (ver router.go); afeta o agendamento de todos os Watches do sistema.
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

	settings, err := h.queries.UpdateScanSettings(r.Context(), sqlcgen.UpdateScanSettingsParams{
		MinIntervalMinutes: req.MinIntervalMinutes,
		MaxIntervalMinutes: req.MaxIntervalMinutes,
	})
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal error")
		return
	}
	writeJSON(w, http.StatusOK, toScanSettingsResponse(settings))
}

func toScanSettingsResponse(s sqlcgen.ScanSetting) scanSettingsResponse {
	return scanSettingsResponse{
		MinIntervalMinutes: s.MinIntervalMinutes,
		MaxIntervalMinutes: s.MaxIntervalMinutes,
	}
}
