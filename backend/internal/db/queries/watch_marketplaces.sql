-- name: AddWatchMarketplace :exec
INSERT INTO watch_marketplaces (watch_id, marketplace_slug)
VALUES ($1, $2)
ON CONFLICT DO NOTHING;

-- name: ListWatchMarketplaces :many
SELECT marketplace_slug FROM watch_marketplaces WHERE watch_id = $1 ORDER BY marketplace_slug;

-- name: DeleteWatchMarketplacesNotIn :exec
DELETE FROM watch_marketplaces
WHERE watch_id = $1 AND marketplace_slug != ALL(sqlc.arg(marketplace_slugs)::text[]);

-- name: DeleteAllWatchMarketplaces :exec
DELETE FROM watch_marketplaces WHERE watch_id = $1;
