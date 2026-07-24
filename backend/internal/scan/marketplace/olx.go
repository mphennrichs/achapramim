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

// olxStateSlugs mapeia UF para o slug de estado usado no path do OLX
// (ex: "MG" -> "minas-gerais"). Apenas os estados necessários hoje; um
// estado sem slug conhecido cai para busca nacional (path "brasil").
var olxStateSlugs = map[string]string{
	"MG": "minas-gerais",
}

// buildOLXSearchURL monta a URL de busca do OLX escopada por região quando
// City/State estão presentes (path "/<estado>/<cidade>?q=..."), com
// fallback para busca nacional ("/brasil?q=...") se a UF não tiver slug
// mapeado ou a região não for informada.
func buildOLXSearchURL(query Query) string {
	q := strings.Join(query.Keywords, " ")
	regionPath := "brasil"
	if stateSlug, ok := olxStateSlugs[strings.ToUpper(query.State)]; ok && query.City != "" {
		regionPath = stateSlug + "/" + slugify(query.City)
	}
	return "https://www.olx.com.br/" + regionPath + "?" + url.Values{"q": {q}}.Encode()
}

// slugify normaliza um nome de cidade para o formato de path do OLX
// (minúsculas, espaços viram hífen). Não remove acentos — cidades com
// acento no nome (ex: "Belo Horizonte" não tem, mas outras têm) exigiriam
// uma tabela de transliteração; fora do escopo enquanto só MG/BH é usado.
func slugify(name string) string {
	return strings.ToLower(strings.ReplaceAll(strings.TrimSpace(name), " ", "-"))
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
