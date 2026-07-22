package linkpreview

import (
	"context"
	"encoding/json"
	"os"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestProposalSchema_IsValidJSON(t *testing.T) {
	var schema map[string]any
	require.NoError(t, json.Unmarshal([]byte(proposalSchemaJSON), &schema))
	required, ok := schema["required"].([]any)
	require.True(t, ok)
	require.ElementsMatch(t, []any{"keywords", "blocked_words", "target_price_cents"}, required)
}

// TestProposer_Propose_Integration só roda quando ANTHROPIC_API_KEY está
// setado — chama a API real do Claude para confirmar que o schema
// estruturado é aceito e a resposta parseia corretamente.
func TestProposer_Propose_Integration(t *testing.T) {
	apiKey := os.Getenv("ANTHROPIC_API_KEY")
	if apiKey == "" {
		t.Skip("ANTHROPIC_API_KEY not set, skipping integration test")
	}

	proposer := NewProposer(apiKey)
	proposal, err := proposer.Propose(context.Background(), PageContent{
		Title: "PlayStation 5 Slim novo lacrado - 1TB",
		Text:  "Vendo PlayStation 5 Slim, 1TB, novo lacrado na caixa. Valor R$ 3.200,00. Aceito cartão.",
	})
	require.NoError(t, err)
	require.NotEmpty(t, proposal.Keywords)
	require.Equal(t, int64(320000), proposal.TargetPriceCents)
}
