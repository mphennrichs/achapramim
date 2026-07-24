-- Marca uma Offer para monitoramento manual do usuário (ex: base pro futuro
-- drop trigger, que ainda precisa saber quais Offers observar). Também dá
-- prioridade fixa na listagem, independente do critério de ordenação
-- escolhido na UI.
ALTER TABLE offers ADD COLUMN monitored BOOLEAN NOT NULL DEFAULT FALSE;
