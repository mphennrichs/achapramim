package httpapi

import (
	"encoding/json"
	"net/http"

	"github.com/mphennrichs/achapramim/backend/internal/linkpreview"
)

type LinkPreviewHandler struct {
	proposer *linkpreview.Proposer
}

func NewLinkPreviewHandler(proposer *linkpreview.Proposer) *LinkPreviewHandler {
	return &LinkPreviewHandler{proposer: proposer}
}

type linkPreviewRequest struct {
	URL string `json:"url"`
}

type linkPreviewResponse struct {
	Name             string   `json:"name"`
	TargetPriceCents int64    `json:"target_price_cents"`
	Keywords         []string `json:"keywords"`
	BlockedWords     []string `json:"blocked_words"`
	PartialFailure   bool     `json:"partial_failure"`
}

// Preview analisa um link de anúncio e retorna uma Proposta de Preenchimento
// (ver CONTEXT.md e ADR 0003): sugestão transitória de nome, palavras-chave,
// palavras bloqueadas e valor-alvo — nunca persistida diretamente. O
// chamador (front-end) usa isso para pré-preencher o formulário de criação
// manual de Watch, sempre editável e nunca criado sem confirmação explícita.
// Tolerância não faz parte da proposta (vem sempre do padrão do sistema).
// Em caso de falha total ou parcial na análise, retorna o que foi possível
// extrair com partial_failure=true — nunca bloqueia a criação manual.
func (h *LinkPreviewHandler) Preview(w http.ResponseWriter, r *http.Request) {
	var req linkPreviewRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	if req.URL == "" {
		writeError(w, http.StatusBadRequest, "url is required")
		return
	}

	ctx := r.Context()
	page, err := linkpreview.FetchPage(ctx, req.URL)
	if err != nil {
		writeJSON(w, http.StatusOK, linkPreviewResponse{PartialFailure: true})
		return
	}

	proposal, err := h.proposer.Propose(ctx, page)
	if err != nil {
		writeJSON(w, http.StatusOK, linkPreviewResponse{
			Name:           page.Title,
			PartialFailure: true,
		})
		return
	}

	writeJSON(w, http.StatusOK, linkPreviewResponse{
		Name:             page.Title,
		TargetPriceCents: proposal.TargetPriceCents,
		Keywords:         proposal.Keywords,
		BlockedWords:     proposal.BlockedWords,
		PartialFailure:   len(proposal.Keywords) == 0 && len(proposal.BlockedWords) == 0 && proposal.TargetPriceCents == 0,
	})
}
