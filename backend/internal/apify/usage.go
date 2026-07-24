// Package apify expõe consultas de uso/custo da conta Apify usada pelo
// FacebookMarketplaceFetcher (ver ADR 0006) — não faz scraping, só reporta
// gasto para a tela de admin acompanhar o custo do serviço de terceiro.
package apify

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"time"
)

const runsURL = "https://api.apify.com/v2/actor-runs"

// Run é uma execução de actor com seu custo individual (usageTotalUsd),
// espelhando os campos usados de GET /v2/actor-runs.
type Run struct {
	ID         string    `json:"id"`
	ActorID    string    `json:"actId"`
	Status     string    `json:"status"`
	StartedAt  time.Time `json:"startedAt"`
	FinishedAt time.Time `json:"finishedAt"`
	UsageUSD   float64   `json:"usageTotalUsd"`
}

type UsageClient struct {
	apiToken   string
	httpClient *http.Client
	// baseURL é runsURL em produção, sobrescrito nos testes para apontar a
	// um httptest.Server em vez da API real do Apify.
	baseURL string
}

func NewUsageClient(apiToken string) *UsageClient {
	return &UsageClient{
		apiToken:   apiToken,
		httpClient: &http.Client{},
		baseURL:    runsURL,
	}
}

type runsResponse struct {
	Data struct {
		Total int   `json:"total"`
		Items []Run `json:"items"`
	} `json:"data"`
}

// RecentRuns retorna as últimas execuções de actor da conta (todas as
// integrações Apify usadas, não só o Facebook Marketplace), mais recentes
// primeiro, com o custo individual de cada uma.
func (c *UsageClient) RecentRuns(ctx context.Context, limit int) ([]Run, error) {
	if c.apiToken == "" {
		return nil, fmt.Errorf("apify usage fetch failed: APIFY_API_TOKEN not configured")
	}

	endpoint := c.baseURL + "?" + url.Values{
		"token": {c.apiToken},
		"limit": {fmt.Sprintf("%d", limit)},
		"desc":  {"true"},
	}.Encode()

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint, nil)
	if err != nil {
		return nil, fmt.Errorf("apify usage fetch failed: %w", err)
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("apify usage fetch failed: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("apify usage fetch failed: %w", err)
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("apify usage fetch failed: apify returned status %d: %s", resp.StatusCode, body)
	}

	var parsed runsResponse
	if err := json.Unmarshal(body, &parsed); err != nil {
		return nil, fmt.Errorf("apify usage fetch failed: invalid response from apify: %w", err)
	}
	return parsed.Data.Items, nil
}
