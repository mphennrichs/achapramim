package marketplace

import (
	"context"
	"fmt"
	"net/url"
	"strconv"
	"strings"
	"time"

	"github.com/chromedp/chromedp"

	"github.com/mphennrichs/achapramim/backend/internal/browser"
)

const olxSlug = "olx"

// OLXFetcher busca anúncios na página pública de busca do OLX via browser
// real (chromedp/Chrome headless). A página é acessível sem autenticação,
// mas exige um browser de verdade — requisições HTTP simples são
// bloqueadas por fingerprint (ver ADR 0002).
type OLXFetcher struct {
	// AllocatorContext, se não-nil, é usado como contexto pai do Chrome
	// (ex: para reusar um browser já alocado entre chamadas). Se nil, um
	// browser novo é alocado a cada Fetch.
	AllocatorContext context.Context
}

func NewOLXFetcher() *OLXFetcher {
	return &OLXFetcher{}
}

func (f *OLXFetcher) Slug() string {
	return olxSlug
}

// olxListing espelha a estrutura de um card de anúncio na página de busca.
// TODO(scraping): seletores baseados em data-testid observados em uma
// inspeção manual anterior (ver docs/adr/0002), não validados ponta a
// ponta contra a extração real — confirmar e ajustar rodando localmente
// contra https://www.olx.com.br antes de considerar este fetcher pronto.
type olxListing struct {
	ExternalID string `json:"externalId"`
	URL        string `json:"url"`
	Title      string `json:"title"`
	ImageURL   string `json:"imageUrl"`
	PriceText  string `json:"priceText"`
}

func (f *OLXFetcher) Fetch(ctx context.Context, query Query) ([]Listing, error) {
	searchURL := buildOLXSearchURL(query)

	allocCtx := f.AllocatorContext
	if allocCtx == nil {
		allocCtx = ctx
	}
	browserCtx, cancel := browser.NewContext(allocCtx)
	defer cancel()

	timeoutCtx, cancelTimeout := context.WithTimeout(browserCtx, 30*time.Second)
	defer cancelTimeout()

	var rawListings []olxListing
	err := chromedp.Run(timeoutCtx,
		chromedp.Navigate(searchURL),
		chromedp.Sleep(3*time.Second), // deixa o conteúdo client-side renderizar
		chromedp.Evaluate(olxExtractionScript, &rawListings),
	)
	if err != nil {
		return nil, fmt.Errorf("olx fetch failed: %w", err)
	}

	listings := make([]Listing, 0, len(rawListings))
	for _, raw := range rawListings {
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

// olxExtractionScript roda no contexto da página e retorna os cards de
// anúncio como JSON. TODO(scraping): validar os seletores contra o DOM
// real do OLX.
const olxExtractionScript = `
(() => {
  const cards = Array.from(document.querySelectorAll('[data-testid="ad-card"]'));
  return cards.map((card) => {
    const link = card.querySelector('a[href]');
    const img = card.querySelector('img');
    const priceEl = card.querySelector('[data-testid="ad-price"]');
    const titleEl = card.querySelector('h2, [data-testid="ad-title"]');
    const href = link ? link.href : '';
    const idMatch = href.match(/-(\d+)$/);
    return {
      externalId: idMatch ? idMatch[1] : href,
      url: href,
      title: titleEl ? titleEl.textContent.trim() : '',
      imageUrl: img ? img.src : '',
      priceText: priceEl ? priceEl.textContent.trim() : '',
    };
  }).filter((item) => item.externalId && item.url);
})()
`

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
