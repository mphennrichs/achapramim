-- Resumo de anúncios por Scan: quantos eram novos (primeira vez vistos)
-- vs. quantos já eram conhecidos (reverificação) — offers_found já existia
-- mas não distinguia os dois casos.
ALTER TABLE scans ADD COLUMN new_offers_count INTEGER NOT NULL DEFAULT 0;
ALTER TABLE scans ADD COLUMN seen_offers_count INTEGER NOT NULL DEFAULT 0;

-- notifications.status já existe pra rastrear tentativa de envio por canal
-- (pending/sent/failed) — read_at é um conceito separado: se o usuário já
-- viu a notificação dentro do próprio app, independente de canal externo.
ALTER TABLE notifications ADD COLUMN read_at TIMESTAMPTZ;

-- 'in_app' cobre notificações mostradas só dentro do próprio app, sem
-- nenhum canal externo (whatsapp/telegram/email) envolvido — esse é o
-- único canal implementado por enquanto (ver ADR sobre o escopo desta
-- primeira etapa: só in-app, disparo por canal externo fica para depois).
ALTER TYPE channel_type ADD VALUE 'in_app';
