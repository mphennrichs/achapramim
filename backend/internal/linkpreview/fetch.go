package linkpreview

import (
	"context"
	"fmt"
	"time"

	"github.com/mphennrichs/achapramim/backend/internal/sidecar"
)

// PageContent é o conteúdo bruto extraído de uma página de anúncio, antes
// de qualquer interpretação pelo LLM.
type PageContent struct {
	Title string
	Text  string
}

type fetchPageInput struct {
	URL string `json:"url"`
}

type fetchPageOutput struct {
	OK    bool   `json:"ok"`
	Title string `json:"title"`
	Text  string `json:"text"`
	Error string `json:"error"`
}

// FetchPage carrega a URL via um sidecar Python/Playwright (ver
// backend/sidecar/fetch_page.py — mesmo motivo do OLXFetcher: sites de
// anúncio tendem a ter proteção anti-bot que bloqueia requisições HTTP
// simples e, mais recentemente, também o chromedp) e extrai título + texto
// visível da página.
func FetchPage(ctx context.Context, url string) (PageContent, error) {
	timeoutCtx, cancel := context.WithTimeout(ctx, 30*time.Second)
	defer cancel()

	var out fetchPageOutput
	if err := sidecar.Run(timeoutCtx, "fetch_page.py", fetchPageInput{URL: url}, &out); err != nil {
		return PageContent{}, fmt.Errorf("failed to fetch page content: %w", err)
	}
	if !out.OK {
		return PageContent{}, fmt.Errorf("failed to fetch page content: %s", out.Error)
	}
	return PageContent{Title: out.Title, Text: out.Text}, nil
}
