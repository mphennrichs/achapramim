# WhatsApp via ibex-bot como serviço HTTP separado

Notificações por WhatsApp dependem do projeto `ibex-bot`, já existente. Em vez de importá-lo como biblioteca Go dentro deste backend, ele roda como serviço próprio e este projeto o chama via API HTTP para disparar mensagens. Isso evita acoplar o deploy e as versões dos dois projetos, e permite que o `ibex-bot` continue servindo outros projetos além deste. O envio segue retry com backoff; após esgotar as tentativas, a falha é registrada e a notificação é descartada sem bloquear o restante do fluxo.
