package linkpreview

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/anthropics/anthropic-sdk-go"
	"github.com/anthropics/anthropic-sdk-go/option"
)

// Proposal é a Proposta de Preenchimento (ver CONTEXT.md): sugestão
// transitória de palavras-chave, palavras bloqueadas e valor-alvo, nunca
// persistida diretamente. Campos ausentes/vazios indicam que o LLM não
// conseguiu extrair aquela informação da página — o formulário abre em
// branco nesses casos, sem bloquear a criação manual (ver ADR 0003).
type Proposal struct {
	Keywords         []string `json:"keywords"`
	BlockedWords     []string `json:"blocked_words"`
	TargetPriceCents int64    `json:"target_price_cents"`
}

// Proposer chama o Claude para extrair uma Proposal a partir do conteúdo
// bruto de uma página de anúncio. Roda sob demanda, uma única vez, fora do
// ciclo de Scan (ver ADR 0004) — nunca em tempo real de Scan.
type Proposer struct {
	client anthropic.Client
}

func NewProposer(apiKey string) *Proposer {
	return &Proposer{client: anthropic.NewClient(option.WithAPIKey(apiKey))}
}

const proposalSchemaJSON = `{
  "type": "object",
  "properties": {
    "keywords": {
      "type": "array",
      "items": {"type": "string"},
      "description": "Palavras-chave relevantes extraídas do título/descrição do anúncio (marca, modelo, características)."
    },
    "blocked_words": {
      "type": "array",
      "items": {"type": "string"},
      "description": "Termos que, se presentes em outros anúncios, devem excluí-los (ex: 'quebrado', 'para peças', 'sem garantia'), inferidos do contexto do anúncio."
    },
    "target_price_cents": {
      "type": "integer",
      "description": "Valor do anúncio em centavos. 0 se não foi possível identificar um preço."
    }
  },
  "required": ["keywords", "blocked_words", "target_price_cents"],
  "additionalProperties": false
}`

// Propose analisa o conteúdo de uma página de anúncio e retorna uma
// Proposal. Best-effort: se o LLM falhar ou retornar dados parciais, os
// campos não preenchidos ficam vazios/zero — o chamador é responsável por
// abrir o formulário com o que foi possível extrair (nunca bloqueia a
// criação manual do Watch).
func (p *Proposer) Propose(ctx context.Context, page PageContent) (Proposal, error) {
	var schema map[string]any
	if err := json.Unmarshal([]byte(proposalSchemaJSON), &schema); err != nil {
		return Proposal{}, fmt.Errorf("invalid proposal schema: %w", err)
	}

	prompt := fmt.Sprintf(
		"Analise o anúncio de marketplace abaixo e extraia palavras-chave, palavras bloqueadas sugeridas e o valor do anúncio.\n\nTítulo: %s\n\nConteúdo da página:\n%s",
		page.Title, truncate(page.Text, 8000),
	)

	message, err := p.client.Messages.New(ctx, anthropic.MessageNewParams{
		Model:     anthropic.ModelClaudeOpus4_8,
		MaxTokens: 1024,
		OutputConfig: anthropic.OutputConfigParam{
			Format: anthropic.JSONOutputFormatParam{Schema: schema},
		},
		Messages: []anthropic.MessageParam{
			anthropic.NewUserMessage(anthropic.NewTextBlock(prompt)),
		},
	})
	if err != nil {
		return Proposal{}, fmt.Errorf("failed to call anthropic api: %w", err)
	}

	if message.StopReason == "refusal" {
		return Proposal{}, nil
	}

	var text string
	for _, block := range message.Content {
		if variant, ok := block.AsAny().(anthropic.TextBlock); ok {
			text = variant.Text
			break
		}
	}
	if text == "" {
		return Proposal{}, nil
	}

	var proposal Proposal
	if err := json.Unmarshal([]byte(text), &proposal); err != nil {
		return Proposal{}, fmt.Errorf("failed to parse proposal: %w", err)
	}
	return proposal, nil
}

func truncate(s string, maxLen int) string {
	if len(s) <= maxLen {
		return s
	}
	return s[:maxLen]
}
