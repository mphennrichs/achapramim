package httpapi

import (
	"net/http"

	"github.com/mphennrichs/achapramim/backend/internal/apify"
)

const apifyUsageRunsLimit = 50

// ApifyUsageHandler expõe o histórico de custo da conta Apify (usada pelo
// FacebookMarketplaceFetcher, ver ADR 0006) para a tela de admin acompanhar
// o gasto — consulta a API do Apify ao vivo, sem persistência própria.
type ApifyUsageHandler struct {
	client *apify.UsageClient
}

func NewApifyUsageHandler(apiToken string) *ApifyUsageHandler {
	return &ApifyUsageHandler{client: apify.NewUsageClient(apiToken)}
}

type apifyUsageRunResponse struct {
	ID         string  `json:"id"`
	ActorID    string  `json:"actor_id"`
	Status     string  `json:"status"`
	StartedAt  string  `json:"started_at"`
	FinishedAt string  `json:"finished_at"`
	UsageUSD   float64 `json:"usage_usd"`
}

func (h *ApifyUsageHandler) List(w http.ResponseWriter, r *http.Request) {
	runs, err := h.client.RecentRuns(r.Context(), apifyUsageRunsLimit)
	if err != nil {
		writeError(w, http.StatusBadGateway, "failed to fetch apify usage: "+err.Error())
		return
	}

	var totalUSD float64
	items := make([]apifyUsageRunResponse, len(runs))
	for i, run := range runs {
		totalUSD += run.UsageUSD
		items[i] = apifyUsageRunResponse{
			ID:         run.ID,
			ActorID:    run.ActorID,
			Status:     run.Status,
			StartedAt:  run.StartedAt.Format("2006-01-02T15:04:05Z07:00"),
			FinishedAt: run.FinishedAt.Format("2006-01-02T15:04:05Z07:00"),
			UsageUSD:   run.UsageUSD,
		}
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"total_usd": totalUSD,
		"runs":      items,
	})
}
