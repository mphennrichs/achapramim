-- name: AddWatchKeyword :one
INSERT INTO watch_keywords (watch_id, term) VALUES ($1, $2) RETURNING *;

-- name: ListWatchKeywords :many
SELECT * FROM watch_keywords WHERE watch_id = $1 ORDER BY term;

-- name: DeleteWatchKeyword :exec
DELETE FROM watch_keywords WHERE id = $1 AND watch_id = $2;

-- name: DeleteAllWatchKeywords :exec
DELETE FROM watch_keywords WHERE watch_id = $1;
