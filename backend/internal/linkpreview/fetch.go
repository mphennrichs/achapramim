package linkpreview

import (
	"context"
	"errors"
	"fmt"
	"net"
	"net/netip"
	"net/url"
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
func FetchPage(ctx context.Context, rawURL string) (PageContent, error) {
	timeoutCtx, cancel := context.WithTimeout(ctx, 30*time.Second)
	defer cancel()

	if err := ValidatePublicURL(timeoutCtx, rawURL); err != nil {
		return PageContent{}, err
	}

	var out fetchPageOutput
	if err := sidecar.Run(timeoutCtx, "fetch_page.py", fetchPageInput{URL: rawURL}, &out); err != nil {
		return PageContent{}, fmt.Errorf("failed to fetch page content: %w", err)
	}
	if !out.OK {
		return PageContent{}, fmt.Errorf("failed to fetch page content: %s", out.Error)
	}
	return PageContent{Title: out.Title, Text: out.Text}, nil
}

// ErrURLNotAllowed: a URL do link-preview não é http(s) ou aponta para um
// endereço que não é público (loopback, rede privada, link-local, CGNAT/
// Tailscale…). Sem isso o Chromium do sidecar vira um SSRF: qualquer usuário
// logado faria o servidor abrir file:// ou serviços internos (dockerproxy,
// komodo, infisical) da rede do host.
var ErrURLNotAllowed = errors.New("url not allowed for link preview")

// lookupHost é trocável nos testes (evita DNS real).
var lookupHost = net.DefaultResolver.LookupNetIP

// ValidatePublicURL aceita só http/https cujo host resolve exclusivamente para
// IPs públicos. É a primeira barreira; o sidecar repete a checagem em cada
// requisição do browser (redirects e sub-recursos), ver fetch_page.py.
func ValidatePublicURL(ctx context.Context, rawURL string) error {
	u, err := url.Parse(rawURL)
	if err != nil || (u.Scheme != "http" && u.Scheme != "https") || u.Hostname() == "" {
		return ErrURLNotAllowed
	}
	host := u.Hostname()
	if ip, err := netip.ParseAddr(host); err == nil {
		if !isPublicIP(ip) {
			return ErrURLNotAllowed
		}
		return nil
	}
	ips, err := lookupHost(ctx, "ip", host)
	if err != nil || len(ips) == 0 {
		return ErrURLNotAllowed
	}
	for _, ip := range ips {
		if !isPublicIP(ip) {
			return ErrURLNotAllowed
		}
	}
	return nil
}

var cgnat = netip.MustParsePrefix("100.64.0.0/10") // inclui a faixa do Tailscale

func isPublicIP(ip netip.Addr) bool {
	ip = ip.Unmap()
	return ip.IsValid() && ip.IsGlobalUnicast() && !ip.IsPrivate() &&
		!ip.IsLoopback() && !ip.IsLinkLocalUnicast() && !cgnat.Contains(ip)
}
