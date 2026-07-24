package marketplace

import (
	"context"
	"fmt"
	"net/url"
	"strconv"
	"strings"
	"time"

	"github.com/mphennrichs/achapramim/backend/internal/sidecar"
)

const olxSlug = "olx"

// OLXFetcher busca anúncios na página pública de busca do OLX via um
// sidecar Python/Playwright (ver backend/sidecar/olx_search.py). O antigo
// mecanismo via chromedp foi substituído após confirmar que a Cloudflare
// bloqueia requisições automatizadas via CDP (ver ADR sobre a migração);
// Playwright passa pela detecção sem ajustes extras.
type OLXFetcher struct{}

func NewOLXFetcher() *OLXFetcher {
	return &OLXFetcher{}
}

func (f *OLXFetcher) Slug() string {
	return olxSlug
}

// olxListing espelha um item da lista "listings" retornada por
// olx_search.py — ver esse arquivo para os seletores usados na extração.
type olxListing struct {
	ExternalID string `json:"externalId"`
	URL        string `json:"url"`
	Title      string `json:"title"`
	ImageURL   string `json:"imageUrl"`
	PriceText  string `json:"priceText"`
}

type olxSidecarInput struct {
	URL string `json:"url"`
}

type olxSidecarOutput struct {
	OK       bool         `json:"ok"`
	Listings []olxListing `json:"listings"`
	Error    string       `json:"error"`
}

func (f *OLXFetcher) Fetch(ctx context.Context, query Query) ([]Listing, error) {
	searchURL := buildOLXSearchURL(query)

	timeoutCtx, cancel := context.WithTimeout(ctx, 30*time.Second)
	defer cancel()

	var out olxSidecarOutput
	if err := sidecar.Run(timeoutCtx, "olx_search.py", olxSidecarInput{URL: searchURL}, &out); err != nil {
		return nil, fmt.Errorf("olx fetch failed: %w", err)
	}
	if !out.OK {
		return nil, fmt.Errorf("olx fetch failed: %s", out.Error)
	}

	listings := make([]Listing, 0, len(out.Listings))
	for _, raw := range out.Listings {
		priceCents, ok := parseBRLToCents(raw.PriceText)
		if !ok {
			continue
		}
		listings = append(listings, Listing{
			ExternalID: raw.ExternalID,
			URL:        raw.URL,
			Title:      raw.Title,
			ImageURL:   raw.ImageURL,
			PriceCents: priceCents,
		})
	}
	return listings, nil
}

// buildOLXSearchURL monta a URL de busca do OLX escopada por estado quando
// State está presente (path "/brasil/estado-<uf>?q=..."), com fallback para
// busca nacional ("/brasil?q=...") se a região não for informada.
//
// O formato antigo usado aqui ("/<nome-do-estado>/<cidade>?q=...", ex.
// "/minas-gerais/belo-horizonte") nunca resolve para uma página de busca —
// cai na home genérica do OLX, silenciosamente retornando zero listings
// (sem erro, já que olx_search.py trata ausência de resultados como busca
// vazia, não falha). Confirmado testando manualmente contra produção: o OLX
// hoje só reconhece escopo regional via "/brasil/estado-<uf>" (ex.
// "estado-mg"); escopo por cidade existe mas usa um slug de "região" que
// não é derivável do nome da cidade (ex. Belo Horizonte é
// "belo-horizonte-e-regiao", não "belo-horizonte") — por isso o escopo por
// cidade foi abandonado em favor de só estado, que já filtra bem e não
// depende de um mapa cidade→slug frágil.
func buildOLXSearchURL(query Query) string {
	q := strings.Join(query.Keywords, " ")
	regionPath := "brasil"
	if query.State != "" {
		regionPath = "brasil/estado-" + strings.ToLower(query.State)
	}
	return "https://www.olx.com.br/" + regionPath + "?" + url.Values{"q": {q}}.Encode()
}

// parseBRLToCents converte "R$ 1.234,56" em 123456. Retorna ok=false para
// texto vazio ou não numérico (ex: "Preço a combinar").
func parseBRLToCents(text string) (int64, bool) {
	cleaned := strings.NewReplacer("R$", "", ".", "", " ", "").Replace(text)
	cleaned = strings.ReplaceAll(cleaned, ",", ".")
	cleaned = strings.TrimSpace(cleaned)
	if cleaned == "" {
		return 0, false
	}
	value, err := strconv.ParseFloat(cleaned, 64)
	if err != nil {
		return 0, false
	}
	return int64(value*100 + 0.5), true
}
