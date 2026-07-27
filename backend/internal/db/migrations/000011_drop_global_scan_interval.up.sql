-- Backfill: qualquer marketplace já em uso (referenciado por algum
-- watch_marketplaces) mas sem override próprio em marketplace_scan_settings
-- herda os valores globais antes de o fallback deixar de existir — sem
-- isso, watches nesses marketplaces parariam de reagendar silenciosamente
-- após esta migration (ver resolveMarketplaceInterval em scan/runner.go,
-- que passa a exigir override, sem fallback).
INSERT INTO marketplace_scan_settings (marketplace_slug, min_interval_minutes, max_interval_minutes)
SELECT DISTINCT wm.marketplace_slug, s.min_interval_minutes, s.max_interval_minutes
FROM watch_marketplaces wm, scan_settings s
WHERE wm.marketplace_slug NOT IN (SELECT marketplace_slug FROM marketplace_scan_settings)
ON CONFLICT (marketplace_slug) DO NOTHING;

-- O intervalo global de scan_settings só existia como fallback para
-- marketplaces sem override em marketplace_scan_settings — a UI de admin
-- sempre grava um override por marketplace (ver availableMarketplaces no
-- frontend), então o fallback nunca é de fato usado e o campo perdeu
-- utilidade. scan_settings continua existindo (default_city/default_state).
ALTER TABLE scan_settings DROP COLUMN min_interval_minutes;
ALTER TABLE scan_settings DROP COLUMN max_interval_minutes;
