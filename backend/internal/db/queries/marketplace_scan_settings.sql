-- name: ListMarketplaceScanSettings :many
SELECT * FROM marketplace_scan_settings ORDER BY marketplace_slug;

-- name: UpsertMarketplaceScanSetting :one
INSERT INTO marketplace_scan_settings (marketplace_slug, min_interval_minutes, max_interval_minutes)
VALUES ($1, $2, $3)
ON CONFLICT (marketplace_slug) DO UPDATE SET
    min_interval_minutes = EXCLUDED.min_interval_minutes,
    max_interval_minutes = EXCLUDED.max_interval_minutes
RETURNING *;

-- name: DeleteMarketplaceScanSettingsNotIn :exec
-- Remove configurações de marketplaces que não vieram na última
-- atualização (voltam a usar o fallback global) — mesmo padrão de replace
-- completo usado em ReplaceDefaultBlockedWords.
DELETE FROM marketplace_scan_settings
WHERE marketplace_slug != ALL(sqlc.arg(marketplace_slugs)::text[]);
