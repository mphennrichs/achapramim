# Remoção de Mercado Livre e Facebook Marketplace, mantendo só OLX

Ver [ADR 0002](0002-hybrid-marketplace-data-collection.md) para o contexto original: dos três marketplaces planejados, só OLX teve um Fetcher implementado. Mercado Livre ficou pendente por bloqueio de acesso à busca pública (hoje confirmado como restrição de política da própria API, não bloqueio de rede — ver pesquisa registrada na sessão que motivou esta ADR). Facebook Marketplace ficou pendente pela busca exigir sessão autenticada, o que implicaria manter uma conta dedicada com cookies de sessão capturados manualmente, aceitando risco de banimento por automação.

Nenhum dos dois teve, em nenhum momento, um Fetcher funcional em produção — eram apenas slugs reservados na tabela `marketplaces`, sem nenhum Watch, Offer ou Scan real referenciando-os (confirmado antes da remoção). Manter os dois como "marketplaces disponíveis" na UI e no schema, sem um Fetcher por trás, criava a expectativa de uma funcionalidade que nunca existiu de fato.

## Decisão

Remover Mercado Livre e Facebook Marketplace do sistema: linhas de seed em `marketplaces` (migration), qualquer validação/UI que os expusesse como opção. OLX passa a ser o único Marketplace suportado — a seção de seleção de marketplace no formulário de criação de Alerta foi removida (não há escolha real com uma única opção), e todo Alerta é criado com `marketplaces = ['olx']` automaticamente.

Consequência observada: com no máximo um marketplace por Alerta, o status `partial` de Scan (sucesso parcial — alguns marketplaces falham, outros funcionam) fica inatingível na prática. O enum e a lógica que o calcula permanecem no código (não há custo em mantê-los), mas sem cobertura de teste ativa para esse caso — só `success` e `failed` são hoje alcançáveis.

## Caminho de volta

Se Mercado Livre ou Facebook Marketplace ganharem um caminho viável de acesso no futuro (API oficial reaberta, ou disposição de assumir o risco de conta dedicada para Facebook), a reintrodução é: nova migration inserindo o slug em `marketplaces`, um novo Fetcher em `backend/internal/scan/marketplace/`, e a UI de seleção de marketplace volta a fazer sentido com 2+ opções reais.
