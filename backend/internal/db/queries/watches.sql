-- name: CreateWatch :one
-- city/state são opcionais (NULL): quando ausentes, o Scan usa o padrão
-- global em scan_settings (default_city/default_state) — ver OLXFetcher.
INSERT INTO watches (
    user_id, name, target_price_cents, tolerance_percent,
    max_offers, price_drop_threshold_percent, city, state, keyword_match_mode
)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
RETURNING *;

-- name: GetWatchByID :one
SELECT * FROM watches WHERE id = $1;

-- name: ListWatchesByUser :many
SELECT * FROM watches WHERE user_id = $1 ORDER BY created_at DESC;

-- name: ListAllWatchesWithOwner :many
-- Listagem cross-user (admin, ver ?all=true em WatchHandler.List) já com
-- nome/email do dono — usada pela tela admin "Todos os Alertas" para exibir
-- de quem é cada Alerta sem uma segunda chamada por User.
SELECT w.*, u.name AS owner_name, u.email AS owner_email
FROM watches w
JOIN users u ON u.id = w.user_id
ORDER BY w.user_id, w.created_at DESC;

-- name: UpdateWatch :one
UPDATE watches SET
    name = $2,
    target_price_cents = $3,
    tolerance_percent = $4,
    max_offers = $5,
    price_drop_threshold_percent = $6,
    city = $7,
    state = $8,
    keyword_match_mode = $9,
    updated_at = now()
WHERE id = $1
RETURNING *;

-- name: SetWatchActive :one
UPDATE watches SET active = $2, updated_at = now() WHERE id = $1 RETURNING *;

-- name: DeleteWatch :exec
DELETE FROM watches WHERE id = $1;

-- name: DueWatchMarketplaces :many
-- Pares (Watch, marketplace) prontos para rodar um novo Scan: Watch ativo,
-- dono ativo, e o next_scan_at daquele marketplace específico já passou —
-- cada marketplace de um Watch é agendado e reagendado independentemente
-- (ver watch_marketplaces.next_scan_at), não mais o Watch inteiro de uma
-- vez. A pausa por dono desativado nunca é persistida como estado do
-- Watch — é sempre derivada via join com users.active.
SELECT w.*, wm.marketplace_slug
FROM watch_marketplaces wm
JOIN watches w ON w.id = wm.watch_id
JOIN users u ON u.id = w.user_id
WHERE w.active
  AND u.active
  AND wm.next_scan_at <= now();

-- name: RescheduleWatchMarketplace :exec
UPDATE watch_marketplaces SET next_scan_at = $3
WHERE watch_id = $1 AND marketplace_slug = $2;
