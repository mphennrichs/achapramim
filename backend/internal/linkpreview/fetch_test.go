package linkpreview

import (
	"context"
	"testing"

	"github.com/stretchr/testify/require"
)

// Ver testdata/success/fetch_page.py e testdata/failure/fetch_page.py —
// fixtures shell script substituindo o sidecar Python real, sem depender de
// Playwright/browser/rede.
func TestFetchPage_Success(t *testing.T) {
	t.Setenv("SIDECAR_PYTHON_BIN", "/bin/sh")
	t.Setenv("SIDECAR_SCRIPT_DIR", "testdata/success")

	content, err := FetchPage(context.Background(), "https://olx.com.br/anuncio/123")
	require.NoError(t, err)
	require.Equal(t, "Frigobar Branco Midea 40L NOVO", content.Title)
	require.Contains(t, content.Text, "R$ 600")
}

func TestFetchPage_SidecarFailure(t *testing.T) {
	t.Setenv("SIDECAR_PYTHON_BIN", "/bin/sh")
	t.Setenv("SIDECAR_SCRIPT_DIR", "testdata/failure")

	_, err := FetchPage(context.Background(), "https://olx.com.br/anuncio/123")
	require.Error(t, err)
	require.Contains(t, err.Error(), "navigation timeout")
}
