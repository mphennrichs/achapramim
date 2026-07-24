package sidecar

import (
	"context"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/require"
)

// useTestdataScripts redireciona Run para as fixtures shell script em
// testdata/, rodadas via /bin/sh — evita depender de Python instalado no
// runner de CI para exercitar o mecanismo de invocação de subprocesso.
func useTestdataScripts(t *testing.T) {
	t.Helper()
	t.Setenv("SIDECAR_PYTHON_BIN", "/bin/sh")
	t.Setenv("SIDECAR_SCRIPT_DIR", "testdata")
}

func TestRun_ValidJSONRoundTrip(t *testing.T) {
	useTestdataScripts(t)

	var out struct {
		OK   bool           `json:"ok"`
		Echo map[string]any `json:"echo"`
	}
	err := Run(context.Background(), "echo_input.sh", map[string]string{"url": "https://example.com"}, &out)
	require.NoError(t, err)
	require.True(t, out.OK)
	require.Equal(t, "https://example.com", out.Echo["url"])
}

func TestRun_NonZeroExitIncludesStderr(t *testing.T) {
	useTestdataScripts(t)

	var out map[string]any
	err := Run(context.Background(), "fail.sh", map[string]string{}, &out)
	require.Error(t, err)
	require.Contains(t, err.Error(), "something went wrong")
}

func TestRun_InvalidJSONOutputErrors(t *testing.T) {
	useTestdataScripts(t)

	var out map[string]any
	err := Run(context.Background(), "bad_json.sh", map[string]string{}, &out)
	require.Error(t, err)
	require.Contains(t, err.Error(), "invalid JSON output")
}

func TestRun_ContextCancellationKillsProcess(t *testing.T) {
	useTestdataScripts(t)

	ctx, cancel := context.WithTimeout(context.Background(), 200*time.Millisecond)
	defer cancel()

	start := time.Now()
	var out map[string]any
	err := Run(ctx, "sleep.sh", map[string]string{}, &out)
	elapsed := time.Since(start)

	require.Error(t, err)
	require.Less(t, elapsed, 5*time.Second, "context cancellation should kill the process promptly, not wait for the full sleep")
	require.True(t, strings.Contains(err.Error(), "signal") || strings.Contains(err.Error(), "killed") || strings.Contains(err.Error(), "context deadline exceeded") || strings.Contains(err.Error(), "invalid JSON"))
}
