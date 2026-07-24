# Achapramim

Aplicação que monitora marketplaces em busca de ofertas que atendam critérios cadastrados pelo usuário, notificando-o via WhatsApp, Telegram e/ou email quando novas ofertas relevantes aparecem.

Terminologia completa em [CONTEXT.md](./CONTEXT.md). Decisões de arquitetura em [docs/adr/](./docs/adr/).

## Stack

- **Backend**: Golang (binário único: API HTTP + agendador/executor de Scans em goroutines)
- **Banco de dados**: PostgreSQL
- **Frontend**: Flutter web
- **Autenticação**: JWT Bearer token
- **Notificações**: WhatsApp (via serviço externo [ibex-bot](./docs/adr/0001-whatsapp-via-ibex-bot-http-service.md)), Telegram, email
- **LLM**: Claude (API Anthropic) — usado apenas offline/sob demanda (preenchimento por link, sugestão de sinônimos), nunca em tempo real de Scan. Detalhes em [ADR 0003](./docs/adr/0003-llm-based-link-autofill.md) e [ADR 0004](./docs/adr/0004-llm-offline-human-in-the-loop-only.md).
- **Segredos**: Infisical Agent como sidecar, injetando variáveis de ambiente (sem SDK embutido no código). Detalhes em [ADR 0005](./docs/adr/0005-infisical-agent-for-secrets.md).

## Deploy

- Ambiente: fogolab, via Docker Compose + Traefik + Komodo, mesma topologia usada pelo projeto trupesound (rede `traefik` externa compartilhada, roteamento por `Host` + `PathPrefix(/api)`, healthchecks, TLS via Cloudflare, logging `json-file` limitado). `compose.yml` na raiz deste repo é a referência dessa topologia — o arquivo que roda de fato é `fogolab/achapramim/docker-compose.yaml`, criado a partir dela seguindo o checklist "Adding a new stack" do `CLAUDE.md` do fogolab.
- Segredos via Infisical (projeto `fogolab`, folder `/achapramim`, env `prod`), sincronizados para o Stack do Komodo pela Action `sync-secrets-deploy.yml` do fogolab — nunca hardcoded em compose.
- CI/CD: [.github/workflows/docker-publish.yml](./.github/workflows/docker-publish.yml) builda e publica `achapramim-backend`/`achapramim-frontend` no GHCR a cada push na `main`, e dispara um `repository_dispatch` para o fogolab com a tag `sha-<commit>` — o `on-image-updated.yml` de lá faz o pin da imagem no compose do stack e o push aciona o redeploy via Komodo. Pré-requisito no lado do fogolab: `achapramim` precisa estar na allowlist desse workflow e o Stack precisar já existir (com os secrets citados acima) antes do primeiro dispatch surtir efeito.
- O backend controla um Chrome real via `chromedp` (contorna bloqueio anti-bot de fingerprint ao raspar os marketplaces — ver [ADR 0002](./docs/adr/0002-hybrid-marketplace-data-collection.md)), então a imagem de runtime do backend inclui Chromium (`backend/Dockerfile`) — não é só uma dependência de build.

## Usuários e permissões

- Apenas o admin cadastra novos Users (sem self-signup). O admin define a senha inicial diretamente; o User não é obrigado a trocá-la no primeiro login.
- Roles são modeladas de forma extensível, mas hoje existem apenas `admin` e `user`. Admin é superset de user.
- Admin pode: cadastrar Users, mudar Roles, e ver os Watches/Scans de todos os Users (auditoria).
- Cada User gerencia livremente seus próprios Watches (criar, editar, excluir, ativar/inativar) e vê apenas os resultados dos seus próprios Watches — não depende do admin para isso.

## Watch (monitoramento cadastrado)

Um Watch é a configuração salva de um monitoramento. Contém:

- Valor-alvo, com % de variação aceitável
- Palavras-chave (influenciam a Classificação das Offers)
- Palavras bloqueadas (excluem totalmente a Offer dos resultados, se presentes)

Tanto palavras-chave quanto palavras bloqueadas podem ser expandidas com **Sugestão de Sinônimos**: uma ação explícita (não automática) que consulta o LLM e propõe variações, sempre revisadas e aceitas manualmente antes de entrar na lista. Uma vez aceito, um sinônimo vira uma entrada solta na lista, sem vínculo rastreável com a palavra que o originou.
- Quantidade de ofertas listadas (limite total exibido, somado entre todos os marketplaces do Watch — não é um limite por marketplace)
- Limiar mínimo de queda de preço para notificação (%)
- Um ou mais marketplaces a monitorar (hoje só OLX é suportado — ver [ADR 0003](./docs/adr/0003-olx-only-marketplace.md))

Um Watch pertence a um User e pode ser inativado (interrompendo Scans e notificações) individualmente, sem afetar os outros Watches do mesmo User.

### Criação a partir de link

Além da criação manual, um Watch pode ser criado colando um link de anúncio:

- O sistema analisa o conteúdo da página via LLM e propõe palavras-chave, palavras bloqueadas e valor-alvo.
- A proposta nunca é salva diretamente: sempre abre como formulário de Watch pré-preenchido e editável, exigindo confirmação explícita do usuário antes de persistir.
- A tolerância % não é sugerida pelo LLM — vem sempre do padrão do sistema, ajustável manualmente.
- Se o link falhar ou só puder ser analisado parcialmente, o formulário abre com o que foi possível extrair e em branco no restante (nunca bloqueia a criação manual).
- O marketplace do Watch não é escolhido pelo usuário — com só OLX suportado, todo Watch é criado com esse marketplace automaticamente (ver [ADR 0003](./docs/adr/0003-olx-only-marketplace.md)).

## Scan (execução do monitoramento)

- Cada Watch roda em seu próprio ritmo: o próximo Scan é sorteado dentro de um intervalo mínimo/máximo global, definido pelo admin.
- Um Scan é sempre agregado por Watch: consulta todos os marketplaces configurados naquele Watch em uma única execução (não existe um Scan por marketplace).
- Um Scan pode ter sucesso parcial — se um marketplace falhar, os demais seguem sendo processados e notificados normalmente.
- Coleta de dados é por scraping da página pública de busca do OLX — não há API oficial de busca de terceiros para este caso de uso. Detalhes em [ADR 0002](./docs/adr/0002-hybrid-marketplace-data-collection.md) (histórico) e [ADR 0003](./docs/adr/0003-olx-only-marketplace.md) (decisão atual).

## Offer (oferta encontrada)

- Contém valor, link, ao menos 1 imagem e uma Classificação (score calculado pelo backend com base em palavras-chave e valor). O cálculo é sempre determinístico — string matching sobre a lista já expandida por sinônimos aceitos; nenhuma chamada a LLM acontece em tempo de Scan.
- Ofertas de marketplaces diferentes competem pelo mesmo limite de exibição do Watch — o corte é total, não por marketplace.
- Identidade da Offer = URL/ID do anúncio no marketplace de origem, usada para deduplicar entre Scans.
- Uma Offer some da lista quando o anúncio original deixa de estar disponível (vendido/removido). Apenas as Offers atualmente exibidas (dentro do limite) são reverificadas a cada Scan.
- A mesma reverificação observa o valor atual do anúncio e alimenta o Histórico de Preço da Offer: um novo ponto só é registrado quando o valor muda (reverificações sem mudança não geram ponto novo).

## Notificações

- Disparadas para Offers genuinamente novas (nunca vistas antes naquele Watch) e para quedas de preço relevantes (acima do limiar % definido no Watch) em Offers já vistas. Re-ranking sem mudança de valor não gera notificação nova; aumentos de preço entram no histórico mas nunca notificam.
- Canais disponíveis: WhatsApp, Telegram, email — todos opcionais; o User pode usar o sistema só pela tela, sem vincular nenhum canal.
- Telegram exige handshake prévio: o usuário abre um deep-link (`t.me/<bot>?start=<token>`) que identifica sua conta e vincula automaticamente o `chat_id` ao User.
- Envio segue retry com backoff; se todas as tentativas falharem, a notificação é descartada e o erro é registrado — a Offer permanece salva e visível independente do canal externo funcionar.
