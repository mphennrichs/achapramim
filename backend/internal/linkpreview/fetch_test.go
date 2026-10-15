package linkpreview

import (
	"context"
	"net/netip"
	"testing"

	"github.com/stretchr/testify/require"
)

// Ver testdata/success/fetch_page.py e testdata/failure/fetch_page.py —
// fixtures shell script substituindo o sidecar Python real, sem depender de
// Playwright/browser/rede.
// stubDNS faz o host resolver para os IPs dados, sem DNS real.
func stubDNS(t *testing.T, ips ...string) {
	t.Helper()
	orig := lookupHost
	t.Cleanup(func() { lookupHost = orig })
	lookupHost = func(context.Context, string, string) ([]netip.Addr, error) {
		out := make([]netip.Addr, 0, len(ips))
		for _, s := range ips {
			out = append(out, netip.MustParseAddr(s))
		}
		return out, nil
	}
}

func TestFetchPage_Success(t *testing.T) {
	stubDNS(t, "151.101.1.1")
	t.Setenv("SIDECAR_PYTHON_BIN", "/bin/sh")
	t.Setenv("SIDECAR_SCRIPT_DIR", "testdata/success")

	content, err := FetchPage(context.Background(), "https://olx.com.br/anuncio/123")
	require.NoError(t, err)
	require.Equal(t, "Frigobar Branco Midea 40L NOVO", content.Title)
	require.Contains(t, content.Text, "R$ 600")
}

func TestFetchPage_SidecarFailure(t *testing.T) {
	stubDNS(t, "151.101.1.1")
	t.Setenv("SIDECAR_PYTHON_BIN", "/bin/sh")
	t.Setenv("SIDECAR_SCRIPT_DIR", "testdata/failure")

	_, err := FetchPage(context.Background(), "https://olx.com.br/anuncio/123")
	require.Error(t, err)
	require.Contains(t, err.Error(), "navigation timeout")
}

func TestValidatePublicURL(t *testing.T) {
	ctx := context.Background()

	stubDNS(t, "151.101.1.1")
	require.NoError(t, ValidatePublicURL(ctx, "https://www.olx.com.br/anuncio/123"))
	require.NoError(t, ValidatePublicURL(ctx, "http://8.8.8.8/x"))

	for _, raw := range []string{
		"file:///etc/passwd",
		"ftp://example.com/x",
		"javascript:alert(1)",
		"https://",
		"http://127.0.0.1:8080/",
		"http://[::1]/",
		"http://10.0.0.5/",
		"http://172.21.0.12:2375/containers/json",
		"http://192.168.0.17/",
		"http://169.254.169.254/latest/meta-data/",
		"http://100.115.190.19/",
	} {
		require.ErrorIs(t, ValidatePublicURL(ctx, raw), ErrURLNotAllowed, raw)
	}
}

func TestValidatePublicURL_HostResolvingToPrivateIP(t *testing.T) {
	stubDNS(t, "151.101.1.1", "172.21.0.12") // um registro interno basta para recusar
	require.ErrorIs(t, ValidatePublicURL(context.Background(), "http://dockerproxy/"), ErrURLNotAllowed)
}

func TestFetchPage_RejectsInternalURLBeforeSidecar(t *testing.T) {
	t.Setenv("SIDECAR_PYTHON_BIN", "/bin/sh")
	t.Setenv("SIDECAR_SCRIPT_DIR", "testdata/success")

	_, err := FetchPage(context.Background(), "http://komodo-core:9120/")
	require.ErrorIs(t, err, ErrURLNotAllowed)
}
