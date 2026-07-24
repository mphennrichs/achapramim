-- name: CreateWatch :one
-- city/state são opcionais (NULL): quando ausentes, o Scan usa o padrão
-- global em scan_settings (default_city/default_state) — ver OLXFetcher.
INSERT INTO watches (
    user_id, name, target_price_cents, tolerance_percent,
    max_offers, price_drop_threshold_percent, city, state
)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
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
    updated_at = now()
WHERE id = $1
RETURNING *;

-- name: SetWatchActive :one
UPDATE watches SET active = $2, updated_at = now() WHERE id = $1 RETURNING *;

-- name: DeleteWatch :exec
DELETE FROM watches WHERE id = $1;

-- name: DueWatches :many
-- Watches prontos para rodar um novo Scan: ativos, dono ativo, e
-- next_scan_at já passou. A pausa por dono desativado nunca é persistida
-- como estado do Watch — é sempre derivada via join com users.active.
SELECT w.*
FROM watches w
JOIN users u ON u.id = w.user_id
WHERE w.active
  AND u.active
  AND w.next_scan_at <= now();

-- name: RescheduleWatch :exec
UPDATE watches SET next_scan_at = $2 WHERE id = $1;
