package linkpreview

import (
	"context"
	"fmt"
	"time"

	"github.com/chromedp/chromedp"
)

// PageContent é o conteúdo bruto extraído de uma página de anúncio, antes
// de qualquer interpretação pelo LLM.
type PageContent struct {
	Title string
	Text  string
}

// FetchPage carrega a URL via browser real (mesmo motivo do OLXFetcher: sites
// de anúncio tendem a ter proteção anti-bot que bloqueia requisições HTTP
// simples) e extrai título + texto visível da página.
func FetchPage(ctx context.Context, url string) (PageContent, error) {
	browserCtx, cancel := chromedp.NewContext(ctx)
	defer cancel()

	timeoutCtx, cancelTimeout := context.WithTimeout(browserCtx, 30*time.Second)
	defer cancelTimeout()

	var content PageContent
	err := chromedp.Run(timeoutCtx,
		chromedp.Navigate(url),
		chromedp.Sleep(2*time.Second),
		chromedp.Title(&content.Title),
		chromedp.Text("body", &content.Text, chromedp.NodeVisible),
	)
	if err != nil {
		return PageContent{}, fmt.Errorf("failed to fetch page content: %w", err)
	}
	return content, nil
}
