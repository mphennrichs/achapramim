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

// olxCityRegionSlugs mapeia "cidade|UF" (chave normalizada, ver
// olxCityRegionKey) para o slug de região usado no path do OLX (ex.
// "Belo Horizonte"+"MG" -> "belo-horizonte-e-regiao") — não é derivável do
// nome da cidade por uma regra geral (cada região tem seu próprio nome no
// OLX, ex. "regiao-de-juiz-de-fora", "grande-salvador"), por isso é mantido
// como tabela manual, crescida conforme novas cidades entram em uso. Uma
// cidade sem entrada aqui cai para escopo por estado (mais amplo, mas ainda
// filtra corretamente — ver buildOLXSearchURL).
var olxCityRegionSlugs = map[string]string{
	"belo horizonte|mg": "belo-horizonte-e-regiao",
}

func olxCityRegionKey(city, state string) string {
	return strings.ToLower(strings.TrimSpace(city)) + "|" + strings.ToLower(strings.TrimSpace(state))
}

// buildOLXSearchURL monta a URL de busca do OLX escopada por região: por
// cidade quando há um slug mapeado (path "/estado-<uf>/<slug-da-regiao>",
// ex. "/estado-mg/belo-horizonte-e-regiao"), com fallback para escopo por
// estado (path "/brasil/estado-<uf>") quando só o estado está disponível, e
// busca nacional ("/brasil") quando nenhuma região é informada.
//
// O formato antigo usado aqui ("/<nome-do-estado>/<cidade>?q=...", ex.
// "/minas-gerais/belo-horizonte") nunca resolve para uma página de busca —
// cai na home genérica do OLX, silenciosamente retornando zero listings
// (sem erro, já que olx_search.py trata ausência de resultados como busca
// vazia, não falha). Confirmado testando manualmente contra produção com os
// dois formatos atuais: "/brasil/estado-<uf>?q=..." e
// "/estado-<uf>/<slug-de-regiao>?q=...".
func buildOLXSearchURL(query Query) string {
	q := strings.Join(query.Keywords, " ")
	regionPath := "brasil"
	if query.State != "" {
		stateSlug := strings.ToLower(query.State)
		if regionSlug, ok := olxCityRegionSlugs[olxCityRegionKey(query.City, query.State)]; ok {
			regionPath = "estado-" + stateSlug + "/" + regionSlug
		} else {
			regionPath = "brasil/estado-" + stateSlug
		}
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
