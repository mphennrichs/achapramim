// Package browser centraliza a configuração do allocator chromedp
// compartilhada por todo scraping via browser real (OLXFetcher,
// linkpreview.FetchPage) — mesmo motivo em ambos os casos: os sites de
// anúncio bloqueiam requisições HTTP simples por fingerprint, exigindo um
// Chrome de verdade.
package browser

import (
	"context"
	"os"

	"github.com/chromedp/chromedp"
)

// NewContext cria um contexto chromedp pronto para rodar tanto localmente
// quanto no container de produção (rodando como root, sem sandbox de
// kernel disponível) — ver Dockerfile do backend. CHROME_EXEC_PATH,
// quando definido, aponta para o binário do Chromium instalado na imagem;
// em ambiente de desenvolvimento (sem essa env var) o chromedp localiza o
// browser automaticamente.
func NewContext(ctx context.Context) (context.Context, context.CancelFunc) {
	opts := append(chromedp.DefaultExecAllocatorOptions[:],
		chromedp.NoSandbox,
		chromedp.DisableGPU,
		chromedp.Flag("disable-dev-shm-usage", true),
	)
	if execPath := os.Getenv("CHROME_EXEC_PATH"); execPath != "" {
		opts = append(opts, chromedp.ExecPath(execPath))
	}

	allocCtx, cancelAlloc := chromedp.NewExecAllocator(ctx, opts...)
	browserCtx, cancelBrowser := chromedp.NewContext(allocCtx)

	return browserCtx, func() {
		cancelBrowser()
		cancelAlloc()
	}
}
