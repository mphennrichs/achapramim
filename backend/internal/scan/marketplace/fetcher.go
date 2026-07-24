package marketplace

import "context"

// Listing é um anúncio cru retornado por um Fetcher, antes de virar uma
// Offer (que também carrega Classificação e vínculo com Watch/Scan).
type Listing struct {
	ExternalID string
	URL        string
	Title      string
	ImageURL   string
	PriceCents int64
}

// Query descreve o que buscar: as palavras-chave e bloqueadas já
// determinam o texto de busca e o filtro client-side, sem nenhuma
// dependência do domínio Watch dentro deste pacote. City/State escopam a
// busca por região — já resolvidos para o padrão global pelo chamador
// (Runner) quando o Watch não define os seus próprios.
type Query struct {
	Keywords     []string
	BlockedWords []string
	City         string
	State        string
}

// Fetcher busca anúncios em um Marketplace específico. Cada implementação
// vive em seu próprio arquivo neste pacote e encapsula sua própria
// estratégia de coleta (scraping, sessão autenticada, etc. — ver ADR 0003;
// Mercado Livre e Facebook Marketplace foram removidos do sistema por não
// terem um Fetcher viável, ver ADR 0002, superseded por ADR 0003).
type Fetcher interface {
	// Slug é o identificador do Marketplace, igual ao valor persistido em
	// watch_marketplaces.marketplace_slug (ex: "olx").
	Slug() string
	Fetch(ctx context.Context, query Query) ([]Listing, error)
}
