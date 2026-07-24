package marketplace

import (
	"context"
	"testing"

	"github.com/stretchr/testify/require"
)

// TestOLXFetcher_Fetch exercita o pós-processamento de Fetch (parsing de
// preço, filtragem de preço inválido) ponta a ponta, contra uma fixture
// shell script que substitui o sidecar Python real — sem depender de
// Playwright/browser/rede real. Ver testdata/success/olx_search.py e
// testdata/failure/olx_search.py.
func TestOLXFetcher_Fetch_ParsesAndFiltersListings(t *testing.T) {
	t.Setenv("SIDECAR_PYTHON_BIN", "/bin/sh")
	t.Setenv("SIDECAR_SCRIPT_DIR", "testdata/success")

	f := NewOLXFetcher()
	listings, err := f.Fetch(context.Background(), Query{Keywords: []string{"frigobar"}})
	require.NoError(t, err)

	// A segunda listing da fixture tem "Preço a combinar" (não numérico) —
	// deve ser filtrada, sobrando só a primeira.
	require.Len(t, listings, 1)
	require.Equal(t, "111", listings[0].ExternalID)
	require.Equal(t, "Frigobar novo", listings[0].Title)
	require.Equal(t, int64(60000), listings[0].PriceCents)
}

func TestOLXFetcher_Fetch_ReturnsErrorOnSidecarFailure(t *testing.T) {
	t.Setenv("SIDECAR_PYTHON_BIN", "/bin/sh")
	t.Setenv("SIDECAR_SCRIPT_DIR", "testdata/failure")

	f := NewOLXFetcher()
	_, err := f.Fetch(context.Background(), Query{Keywords: []string{"frigobar"}})
	require.Error(t, err)
	require.Contains(t, err.Error(), "cloudflare challenge")
}
