-- name: AddWatchBlockedWord :one
INSERT INTO watch_blocked_words (watch_id, term) VALUES ($1, $2) RETURNING *;

-- name: ListWatchBlockedWords :many
SELECT * FROM watch_blocked_words WHERE watch_id = $1 ORDER BY term;

-- name: DeleteWatchBlockedWord :exec
DELETE FROM watch_blocked_words WHERE id = $1 AND watch_id = $2;

-- name: DeleteAllWatchBlockedWords :exec
DELETE FROM watch_blocked_words WHERE watch_id = $1;
