package marketplace

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"time"
)

const facebookMarketplaceSlug = "facebook_marketplace"

const apifyRunSyncURL = "https://api.apify.com/v2/acts/apify~facebook-marketplace-scraper/run-sync-get-dataset-items"

// facebookCitySlugs mapeia UF para o slug de cidade usado no path do
// Facebook Marketplace (ex: "MG" -> "belohorizonte"). Diferente do OLX, o
// Facebook exige uma cidade no path da URL de busca (não tem busca
// nacional) — sem slug mapeado, cai para o padrão global via
// facebookDefaultCitySlug.
var facebookCitySlugs = map[string]string{
	"MG": "belohorizonte",
}

const facebookDefaultCitySlug = "belohorizonte"

// FacebookMarketplaceFetcher busca anúncios via o actor apify/facebook-marketplace-scraper
// (ver https://apify.com/apify/facebook-marketplace-scraper). Diferente do
// OLX, a busca no Facebook Marketplace exige uma sessão autenticada — em vez
// de manter uma conta dedicada e assumir o risco de banimento por automação
// (ver ADR 0002/0003), delegamos a coleta a esse serviço de terceiro, que
// resolve login/sessão por conta própria (ver ADR 0006).
type FacebookMarketplaceFetcher struct {
	apiToken   string
	httpClient *http.Client
	// runSyncURL é apifyRunSyncURL em produção, sobrescrito nos testes para
	// apontar a um httptest.Server em vez da API real do Apify.
	runSyncURL string
}

func NewFacebookMarketplaceFetcher(apiToken string) *FacebookMarketplaceFetcher {
	return &FacebookMarketplaceFetcher{
		apiToken:   apiToken,
		httpClient: &http.Client{},
		runSyncURL: apifyRunSyncURL,
	}
}

func (f *FacebookMarketplaceFetcher) Slug() string {
	return facebookMarketplaceSlug
}

type apifyRunInput struct {
	StartURLs             []apifyStartURL `json:"startUrls"`
	ResultsLimit          int             `json:"resultsLimit"`
	IncludeListingDetails bool            `json:"includeListingDetails"`
}

type apifyStartURL struct {
	URL string `json:"url"`
}

// facebookDatasetItem espelha os campos usados de um item do dataset
// retornado pelo actor — o schema real traz muitos outros campos (ver
// exploração manual registrada na sessão que motivou o ADR 0006), ignorados
// aqui via json.Unmarshal parcial.
type facebookDatasetItem struct {
	ID                      string `json:"id"`
	ListingURL              string `json:"listingUrl"`
	MarketplaceListingTitle string `json:"marketplace_listing_title"`
	ListingPrice            struct {
		Amount string `json:"amount"`
	} `json:"listing_price"`
	PrimaryListingPhoto struct {
		PhotoImageURL string `json:"photo_image_url"`
	} `json:"primary_listing_photo"`
}

const facebookResultsLimit = 50

func (f *FacebookMarketplaceFetcher) Fetch(ctx context.Context, query Query) ([]Listing, error) {
	if f.apiToken == "" {
		return nil, fmt.Errorf("facebook marketplace fetch failed: APIFY_API_TOKEN not configured")
	}

	searchURL := buildFacebookSearchURL(query)

	timeoutCtx, cancel := context.WithTimeout(ctx, 90*time.Second)
	defer cancel()

	reqBody, err := json.Marshal(apifyRunInput{
		StartURLs:             []apifyStartURL{{URL: searchURL}},
		ResultsLimit:          facebookResultsLimit,
		IncludeListingDetails: false,
	})
	if err != nil {
		return nil, fmt.Errorf("facebook marketplace fetch failed: %w", err)
	}

	endpoint := f.runSyncURL + "?" + url.Values{"token": {f.apiToken}}.Encode()
	req, err := http.NewRequestWithContext(timeoutCtx, http.MethodPost, endpoint, bytes.NewReader(reqBody))
	if err != nil {
		return nil, fmt.Errorf("facebook marketplace fetch failed: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := f.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("facebook marketplace fetch failed: %w", err)
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("facebook marketplace fetch failed: %w", err)
	}
	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusCreated {
		return nil, fmt.Errorf("facebook marketplace fetch failed: apify returned status %d: %s", resp.StatusCode, respBody)
	}

	var items []facebookDatasetItem
	if err := json.Unmarshal(respBody, &items); err != nil {
		return nil, fmt.Errorf("facebook marketplace fetch failed: invalid response from apify: %w", err)
	}

	listings := make([]Listing, 0, len(items))
	for _, item := range items {
		priceCents, ok := parseDecimalToCents(item.ListingPrice.Amount)
		if !ok {
			continue
		}
		listings = append(listings, Listing{
			ExternalID: item.ID,
			URL:        item.ListingURL,
			Title:      item.MarketplaceListingTitle,
			ImageURL:   item.PrimaryListingPhoto.PhotoImageURL,
			PriceCents: priceCents,
		})
	}
	return listings, nil
}

// buildFacebookSearchURL monta a URL de busca do Facebook Marketplace
// escopada por cidade (path obrigatório, sem fallback nacional como no
// OLX) — usa o slug de cidade mapeado pela UF da Query, ou
// facebookDefaultCitySlug se a região não tiver slug conhecido.
func buildFacebookSearchURL(query Query) string {
	q := strings.Join(query.Keywords, " ")
	citySlug := facebookDefaultCitySlug
	if slug, ok := facebookCitySlugs[strings.ToUpper(query.State)]; ok {
		citySlug = slug
	}
	return "https://www.facebook.com/marketplace/" + citySlug + "/search/?" + url.Values{"query": {q}}.Encode()
}

// parseDecimalToCents converte "450.00" em 45000. Retorna ok=false para
// texto vazio ou não numérico.
func parseDecimalToCents(amount string) (int64, bool) {
	amount = strings.TrimSpace(amount)
	if amount == "" {
		return 0, false
	}
	value, err := strconv.ParseFloat(amount, 64)
	if err != nil {
		return 0, false
	}
	return int64(value*100 + 0.5), true
}
