package scan

import "strings"

// classify calcula a Classificação de um anúncio: metade do peso vem da
// fração de palavras-chave presentes no título (string matching, case
// insensitive), metade vem de quão perto o preço está do valor-alvo
// dentro da tolerância aceitável. Determinístico, sem chamada a LLM (ver
// CONTEXT.md e ADR 0004) — a fórmula exata é detalhe de implementação, não
// fixada no domínio.
func classify(title string, keywords []string, targetPriceCents int64, tolerancePercent float64, priceCents int64) float64 {
	keywordScore := keywordMatchRatio(title, keywords)
	priceScore := priceProximityScore(targetPriceCents, tolerancePercent, priceCents)
	return 0.5*keywordScore + 0.5*priceScore
}

func keywordMatchRatio(title string, keywords []string) float64 {
	if len(keywords) == 0 {
		return 1
	}
	lowerTitle := strings.ToLower(title)
	matches := 0
	for _, kw := range keywords {
		if kw == "" {
			continue
		}
		if strings.Contains(lowerTitle, strings.ToLower(kw)) {
			matches++
		}
	}
	return float64(matches) / float64(len(keywords))
}

// containsBlockedWord reporta se o título contém alguma palavra bloqueada
// (case insensitive). Offers com blocked word são excluídas antes mesmo de
// ter Classificação calculada — ver CONTEXT.md.
func containsBlockedWord(title string, blockedWords []string) bool {
	lowerTitle := strings.ToLower(title)
	for _, bw := range blockedWords {
		if bw == "" {
			continue
		}
		if strings.Contains(lowerTitle, strings.ToLower(bw)) {
			return true
		}
	}
	return false
}

// matchesAllKeywords reporta se o título contém TODAS as keywords
// informadas (case insensitive) — usado para filtrar de verdade quando
// keyword_match_mode do Watch é 'all', diferente do modo 'any' (padrão),
// em que nenhuma keyword é obrigatória e a fração batida só influencia a
// Classificação (ver keywordMatchRatio). Lista vazia sempre passa (sem
// keyword configurada, nada a exigir).
func matchesAllKeywords(title string, keywords []string) bool {
	lowerTitle := strings.ToLower(title)
	for _, kw := range keywords {
		if kw == "" {
			continue
		}
		if !strings.Contains(lowerTitle, strings.ToLower(kw)) {
			return false
		}
	}
	return true
}

// priceProximityScore vale 1 quando o preço está exatamente no valor-alvo,
// decaindo linearmente até 0 na borda da tolerância; preços fora da
// tolerância recebem 0 (a filtragem por tolerância acontece em outro
// ponto — aqui é só o componente do score).
func priceProximityScore(targetPriceCents int64, tolerancePercent float64, priceCents int64) float64 {
	if targetPriceCents <= 0 {
		return 0
	}
	toleranceCents := float64(targetPriceCents) * (tolerancePercent / 100)
	if toleranceCents <= 0 {
		if priceCents == targetPriceCents {
			return 1
		}
		return 0
	}
	diff := float64(priceCents - targetPriceCents)
	if diff < 0 {
		diff = -diff
	}
	score := 1 - diff/toleranceCents
	if score < 0 {
		return 0
	}
	return score
}
