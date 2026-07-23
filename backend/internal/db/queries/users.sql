-- name: CreateUser :one
INSERT INTO users (name, email, password_hash, role)
VALUES ($1, $2, $3, $4)
RETURNING *;

-- name: GetUserByEmail :one
SELECT * FROM users WHERE email = $1;

-- name: GetUserByEmailOrUsername :one
SELECT * FROM users WHERE email = $1 OR username = $1;

-- name: GetUserByID :one
SELECT * FROM users WHERE id = $1;

-- name: ListUsers :many
SELECT * FROM users ORDER BY created_at DESC;

-- name: SetUserRole :one
UPDATE users SET role = $2, updated_at = now() WHERE id = $1 RETURNING *;

-- name: SetUserActive :one
UPDATE users SET active = $2, updated_at = now() WHERE id = $1 RETURNING *;

-- name: SetUsername :one
-- Só aplica se o User ainda não tiver username (Primeiro Acesso é
-- one-shot — trocar depois de definido não é suportado por esta query).
UPDATE users SET username = $2, updated_at = now()
WHERE id = $1 AND username IS NULL
RETURNING *;
