-- name: CreatePriceDropNotification :one
-- Notificação in-app de queda de preço de uma Offer monitorada. channel_type
-- fica fixo em 'in_app' e status em 'sent' — ainda não existe disparo real
-- por canal externo (ver ADR 0001), só o registro in-app; os demais campos
-- existem no schema para quando isso for implementado.
INSERT INTO notifications (user_id, offer_id, channel_type, trigger, status, sent_at)
VALUES ($1, $2, 'in_app', 'price_drop', 'sent', now())
RETURNING *;

-- name: ListNotificationsByUser :many
-- Junta com offers/watches pra dar contexto exibível (título, preço, nome
-- do Watch) sem a UI precisar de uma segunda chamada por notificação.
SELECT n.*, o.title AS offer_title, o.price_cents AS offer_price_cents,
    o.url AS offer_url, w.id AS watch_id, w.name AS watch_name
FROM notifications n
JOIN offers o ON o.id = n.offer_id
JOIN watches w ON w.id = o.watch_id
WHERE n.user_id = $1
ORDER BY n.created_at DESC
LIMIT $2;

-- name: CountUnreadNotifications :one
SELECT count(*) FROM notifications WHERE user_id = $1 AND read_at IS NULL;

-- name: MarkNotificationRead :one
UPDATE notifications SET read_at = now() WHERE id = $1 AND user_id = $2 RETURNING *;

-- name: MarkAllNotificationsRead :exec
UPDATE notifications SET read_at = now() WHERE user_id = $1 AND read_at IS NULL;
