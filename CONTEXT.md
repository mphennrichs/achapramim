# Achapramim

Monitora marketplaces em busca de ofertas que atendam critérios cadastrados pelo usuário, notificando-o quando novas ofertas relevantes aparecem.

## Language

**Alerta**:
Configuração salva de monitoramento: contém valor-alvo (com % de variação aceitável), palavras-chave, lista de palavras bloqueadas, quantidade de ofertas listadas (limite total, somado entre marketplaces), limiar mínimo de queda de preço para notificação, e os marketplaces a monitorar. Um Alerta pode abranger múltiplos marketplaces simultaneamente. Pode ser criado manualmente ou a partir de uma Proposta de Preenchimento gerada a partir de um link.
_Avoid_: Consulta, busca, monitoramento, Watch (termo anterior, substituído para consistência com a UI em português)

**Proposta de Preenchimento**:
Sugestão transitória (nunca persistida como Alerta por si só) de palavras-chave, palavras bloqueadas e valor-alvo, gerada ao analisar um link de anúncio fornecido pelo usuário. É sempre exibida como formulário de Alerta pré-preenchido e editável — nenhum Alerta é criado sem confirmação explícita do usuário. Em caso de falha ou análise parcial do link, o formulário abre preenchido com o que foi possível extrair e em branco no restante. A tolerância % não faz parte da proposta — vem sempre do padrão do sistema, ajustável manualmente.
_Avoid_: Auto-preenchimento, sugestão de IA (como nome do campo)

**Scan**:
Uma execução pontual de um Alerta: consulta todos os marketplaces configurados naquele Alerta, agregando o resultado em uma única execução com seu próprio timestamp e status. Não existe um Scan por marketplace — é sempre um Scan agregado por Alerta. O agendamento do próximo Scan é sorteado independentemente para cada Alerta, dentro do intervalo mínimo/máximo global definido pelo admin. Um Scan pode ter sucesso parcial: marketplaces que falharem não impedem o processamento e notificação das Offers encontradas nos demais.
_Avoid_: Execução, consulta, run

**Marketplace**:
Uma fonte externa de ofertas (Mercado Livre, OLX, Facebook Marketplace). Um Alerta pode monitorar vários Marketplaces ao mesmo tempo.

**Offer**:
Um anúncio encontrado em um Marketplace durante um Scan, que atende aos critérios do Alerta. Contém valor, link, ao menos 1 imagem e uma classificação. Ofertas de diferentes Marketplaces competem pelo mesmo limite de "quantidade de ofertas listadas" do Alerta — o corte é total, não por Marketplace. Uma Offer permanece disponível na listagem enquanto o anúncio original seguir ativo no Marketplace; a cada novo Scan, as Offers atualmente exibidas (dentro do top-N) são reverificadas, e as que não estão mais disponíveis (vendidas/removidas) saem da lista. Offers fora do top-N não são reverificadas. A mesma reverificação também observa o valor atual do anúncio, alimentando o Histórico de Preço da Offer.
_Avoid_: Anúncio, item, produto

**Histórico de Preço**:
Sequência de valores observados de uma Offer ao longo do tempo, usada para saber se o preço está subindo ou descendo. Um novo ponto só é registrado quando o valor observado difere do último registrado — reverificações sem mudança de valor não geram novo ponto. Quando uma queda ultrapassa o limiar mínimo definido no Alerta, dispara uma Notificação (além do gatilho de Offer nova); aumentos de valor entram no histórico normalmente, mas nunca notificam. O histórico pertence à Offer, não ao período em que ela esteve no top-N: se a Offer sair do top-N (parando de ser reverificada) e depois voltar a entrar, o histórico anterior é preservado — não reinicia do zero.
_Avoid_: Variação de preço (como nome do campo), price history

**Classificação**:
Pontuação calculada pelo backend para cada Offer, com base na correspondência de palavras-chave e no valor, usada para ordenar as ofertas exibidas. É sempre um cálculo determinístico (string matching sobre a lista de palavras-chave/bloqueadas do Alerta, já expandida com eventuais Sugestões de Sinônimos aceitas) — nenhuma chamada a LLM acontece em tempo de Scan. A fórmula exata é um detalhe de implementação, não fixada no domínio.
_Avoid_: Score, ranking (como nome do campo)

**Palavra bloqueada**:
Termo cadastrado no Alerta que, se presente na Offer, a exclui totalmente dos resultados — ela não é exibida nem gera Notificação. Diferente de palavra-chave, que influencia a Classificação mas não exclui.
_Avoid_: Blocklist (como nome do campo), palavra banida

**Sugestão de Sinônimos**:
Ação explícita, acionada pelo usuário ao cadastrar/editar uma palavra-chave ou palavra bloqueada, que consulta um LLM para propor variações (sinônimos, termos relacionados). As sugestões são sempre revisadas manualmente — o usuário marca quais aceitar antes delas entrarem na lista. Uma vez aceita, uma sugestão vira uma entrada solta na mesma lista, indistinguível de uma palavra digitada manualmente (sem vínculo rastreável com a palavra que a originou).
_Avoid_: Auto-expansão, sinônimo automático

**Role**:
Nível de permissão de um User dentro do sistema. Modelado de forma extensível (não fixo em apenas dois valores), ainda que hoje existam somente `admin` e `user`. Admin é superset de user — possui todas as permissões e acessos do user comum, mais a administração de Users e Alertas.

Cada Alerta pertence a um User, que o cria, edita, exclui e ativa/inativa livremente sem depender do admin. Um User comum vê os Scans e Offers apenas dos próprios Alertas. O admin, além disso, tem visibilidade e controle cross-user: pode ver os Alertas e Scans de todos os Users, agrupados por User, cadastrar novos Users, alterar Roles, desativar Users, e também editar, ativar/inativar e excluir o Alerta de qualquer User — o mesmo controle que o próprio dono tem sobre seu Alerta.

**Username**:
Identificador único e permanente do User, escolhido por ele mesmo (não pelo admin) no Primeiro Acesso. Login aceita indistintamente email ou Username no mesmo campo. Diferente do email, não pode ser alterado depois de definido — trocar de username fica fora de escopo do User, resolvido apenas por intervenção manual (suporte/admin direto no banco), não por uma tela de edição.
_Avoid_: Apelido, handle

**Primeiro Acesso**:
Etapa obrigatória entre o admin cadastrar um User (com nome, email e senha) e o User poder usar o restante do sistema: o User loga normalmente com email+senha, e o Primeiro Acesso consiste unicamente em escolher seu Username antes de prosseguir — não é um fluxo de troca de senha (a senha definida pelo admin já vale desde o cadastro, sem exigir troca). Um User sem Username definido consegue autenticar (login retorna token normalmente), mas o front bloqueia todo o resto do app até o Username ser definido.
_Avoid_: Onboarding, cadastro (o User já foi cadastrado pelo admin; isso é só a etapa do username)

**User desativado**:
Um User pode ser desativado pelo admin (soft-disable, sem apagar histórico). Ao ser desativado, todos os Alertas daquele User pausam automaticamente — deixam de gerar novos Scans e Notificações. Reativar o User volta os Alertas ao funcionamento normal (respeitando o estado ativo/inativo de cada Alerta, se houver algum inativo). O histórico de Alertas/Scans/Offers permanece visível independente do estado do User.
_Avoid_: Deletar, remover, banir

**Notificação**:
Mensagem enviada a um User em um Canal (WhatsApp, Telegram ou email) informando sobre uma Offer nova (nunca vista antes) ou sobre uma queda de preço relevante (acima do limiar do Alerta) em uma Offer já vista. Re-ranking de Offers já vistas, sem mudança de valor, não gera Notificação. O envio segue retry com backoff; após esgotar as tentativas, a falha é registrada e a Notificação é descartada — a Offer permanece salva e visível independente do sucesso do envio.
_Avoid_: Aviso, Notification. Não confundir com **Alerta** (o conceito antes chamado de Watch) — são termos diferentes que coincidem em português com "alerta"/"aviso" em uso comum; aqui cada um tem seu significado técnico fixo.

**Canal**:
Um meio de entrega de Notificação: WhatsApp, Telegram ou email. Um User pode ter múltiplos Canais cadastrados e vinculados simultaneamente.
_Avoid_: Channel, meio

**Alerta ativo/inativo**:
Interruptor manual por Alerta (acionável pelo dono ou pelo admin) que, quando inativo, desativa a geração de novos Scans e Notificações daquele Alerta, sem afetar outros Alertas. É um estado independente da pausa por User desativado — os dois podem coexistir por motivos diferentes, e não devem ser confundidos: "Alerta inativo" é o interruptor manual por Alerta; "User desativado" é o estado do dono, que também pausa os Alertas dele mas por um caminho derivado (join), nunca persistido no Alerta. Um Alerta só roda quando nenhuma das duas condições estiver desativando-o: está ativo E o dono não está desativado. Reativar um Alerta de um User desativado não faz ele voltar a rodar.
_Avoid_: Mute/mutado (termo anterior, substituído), Silenciar (usar apenas como verbo, não como nome do campo), pausar
