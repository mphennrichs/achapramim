# Facebook Marketplace via serviço de terceiro (Apify), não conta dedicada

Ver [ADR 0003](0003-olx-only-marketplace.md): Facebook Marketplace foi removido do sistema porque o único caminho viável identificado exigia manter uma conta dedicada com sessão (cookies) capturada manualmente, aceitando o risco de banimento por automação — diferente do OLX, cuja busca pública não exige login.

Esse cálculo de risco muda ao delegar a coleta para um serviço de terceiro que já assume esse risco por conta própria: o actor `apify/facebook-marketplace-scraper` (Apify) resolve login/sessão internamente — o backend só envia uma URL de busca (`https://www.facebook.com/marketplace/<cidade>/search/?query=...`) via `POST /v2/acts/apify~facebook-marketplace-scraper/run-sync-get-dataset-items` e recebe os dados já extraídos. Testado manualmente contra uma busca real (`belohorizonte`, termo "frigobar") e confirmado retornando anúncios reais com preço, título, URL e foto.

## Decisão

Reintroduzir o slug `facebook_marketplace` (migration 000005) com um novo `FacebookMarketplaceFetcher` (`backend/internal/scan/marketplace/facebook_marketplace.go`) que chama a API do Apify via HTTP, em vez de scraping/sessão própria. Diferente do `OLXFetcher` (sidecar Python/Playwright local), este Fetcher não depende do sidecar — é só uma chamada HTTP autenticada por token (`APIFY_API_TOKEN`, gerenciado via Infisical conforme [ADR 0005](0005-infisical-agent-for-secrets.md)).

Consequência: o Facebook Marketplace exige cidade no path da URL de busca (sem fallback nacional como o OLX) — regiões sem slug de cidade mapeado usam um padrão fixo (`belohorizonte`), mesmo padrão de fallback usado pelo `OLXFetcher` para estado.

Custo é por resultado (`$0.0015–0.005`/item, decrescendo por tier de uso da conta Apify) — sujeito a rever se o volume de uso crescer o suficiente para tornar outro modelo de precificação mais vantajoso.

## Consequência para o status `partial` de Scan

Com dois marketplaces reais novamente (OLX + Facebook Marketplace), o status `partial` (sucesso parcial, ver ADR 0003) volta a ser alcançável na prática quando um Watch seleciona ambos e só um Fetcher falha.
