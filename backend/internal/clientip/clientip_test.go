package clientip

import (
	"net/http/httptest"
	"testing"
)

func TestFromRequest(t *testing.T) {
	cases := []struct {
		name, remote, cf, want string
	}{
		{"via proxy usa CF-Connecting-IP", "172.21.0.24:5000", "200.150.10.1", "200.150.10.1"},
		{"via proxy IPv6", "172.21.0.24:5000", "2804:14c:5b78:808b::1", "2804:14c:5b78:808b::1"},
		{"sem header usa RemoteAddr", "172.21.0.24:5000", "", "172.21.0.24"},
		{"conexão direta ignora header forjado", "203.0.113.9:4000", "1.2.3.4", "203.0.113.9"},
		{"header inválido usa RemoteAddr", "172.21.0.24:5000", "lixo", "172.21.0.24"},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			r := httptest.NewRequest("POST", "/api/v1/auth/login", nil)
			r.RemoteAddr = c.remote
			if c.cf != "" {
				r.Header.Set("CF-Connecting-IP", c.cf)
			}
			if got := FromRequest(r); got != c.want {
				t.Fatalf("FromRequest = %q, want %q", got, c.want)
			}
		})
	}
}

func TestLimitKeyGroupsIPv6By64(t *testing.T) {
	key := func(cf string) string {
		r := httptest.NewRequest("POST", "/", nil)
		r.RemoteAddr = "172.21.0.24:5000"
		r.Header.Set("CF-Connecting-IP", cf)
		k, _ := LimitKey(r)
		return k
	}
	if a, b := key("2804:14c:5b78:808b::1"), key("2804:14c:5b78:808b:ffff::2"); a != b {
		t.Fatalf("mesmo /64 deveria dar a mesma chave: %q != %q", a, b)
	}
	if a, b := key("200.150.10.1"), key("200.150.10.2"); a == b {
		t.Fatalf("IPv4 diferentes deveriam ter chaves diferentes")
	}
}
