-- name: ListDefaultBlockedWords :many
SELECT * FROM default_blocked_words ORDER BY term;

-- name: ReplaceDefaultBlockedWords :exec
-- Substitui a lista global inteira (usada pela tela admin de Configurações
-- Globais, que edita a lista como um todo, não item a item).
DELETE FROM default_blocked_words;

-- name: AddDefaultBlockedWord :one
INSERT INTO default_blocked_words (term) VALUES ($1) RETURNING *;
