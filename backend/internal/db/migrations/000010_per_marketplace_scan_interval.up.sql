-- Intervalo de Scan configurável por marketplace (ex: OLX a cada 1-2h,
-- Facebook 1x/dia) — antes era um único min/max global em scan_settings
-- valendo para todos. Um marketplace sem linha aqui cai no fallback global
-- (scan_settings.min_interval_minutes/max_interval_minutes), que passa a
-- ser só o "padrão quando não configurado por engine".
CREATE TABLE marketplace_scan_settings (
    marketplace_slug TEXT PRIMARY KEY REFERENCES marketplaces (slug),
    min_interval_minutes INTEGER NOT NULL CHECK (min_interval_minutes >= 1),
    max_interval_minutes INTEGER NOT NULL CHECK (max_interval_minutes <= 1440),
    CHECK (min_interval_minutes <= max_interval_minutes)
);

-- Agendamento deixa de ser por Watch inteiro e passa a ser por
-- (Watch, marketplace): cada engine dentro de um Watch roda e reagenda no
-- seu próprio intervalo, em vez de todos os marketplaces do Watch rodarem
-- juntos no mesmo ciclo. watches.next_scan_at fica obsoleto (mantido só
-- para não quebrar a leitura de linhas antigas antes do backfill abaixo
-- rodar; nenhum código novo o lê).
ALTER TABLE watch_marketplaces ADD COLUMN next_scan_at TIMESTAMPTZ NOT NULL DEFAULT now();
CREATE INDEX idx_watch_marketplaces_next_scan_at ON watch_marketplaces (next_scan_at);

-- Um Scan agora cobre exatamente um marketplace (antes cobria todos os do
-- Watch de uma vez) — necessário pra rastrear o Histórico de Scans por
-- engine individualmente.
ALTER TABLE scans ADD COLUMN marketplace_slug TEXT REFERENCES marketplaces (slug);
