// Package clientip extrai o IP real do cliente atrás do Cloudflare Tunnel +
// Traefik.
//
// RemoteAddr é sempre o Traefik, e o Traefik reescreve X-Forwarded-For e
// X-Real-IP com o IP do container do cloudflared (172.21.0.1): os dois ficam
// iguais para todo mundo. Só o CF-Connecting-IP, escrito pela borda da
// Cloudflare, traz o cliente. Ele só é aceito quando a conexão chega de rede
// privada (o proxy); vindo de qualquer outro lugar, o cliente escolheria o
// próprio "IP" e escaparia dos limites por IP.
package clientip

import (
	"net"
	"net/http"
	"net/netip"
	"strings"
)

// FromRequest devolve o IP do cliente (sem porta).
func FromRequest(r *http.Request) string {
	host, _, err := net.SplitHostPort(r.RemoteAddr)
	if err != nil {
		host = r.RemoteAddr
	}
	remote, err := netip.ParseAddr(host)
	if err != nil {
		return host
	}
	remote = remote.Unmap()
	if cf := r.Header.Get("CF-Connecting-IP"); cf != "" && fromProxy(remote) {
		if ip, err := netip.ParseAddr(strings.TrimSpace(cf)); err == nil {
			return ip.Unmap().String()
		}
	}
	return remote.String()
}

// LimitKey é a chave para limites por IP (httprate.WithKeyFuncs). Agrupa IPv6
// por /64: um cliente costuma ter o /64 inteiro e trocaria de endereço a cada
// tentativa.
func LimitKey(r *http.Request) (string, error) {
	ip, err := netip.ParseAddr(FromRequest(r))
	if err != nil || ip.Is4() {
		return FromRequest(r), nil
	}
	p, err := ip.Prefix(64)
	if err != nil {
		return ip.String(), nil
	}
	return p.String(), nil
}

func fromProxy(a netip.Addr) bool {
	return a.IsPrivate() || a.IsLoopback()
}
