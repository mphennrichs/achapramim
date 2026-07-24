-- name: CreateUser :one
-- username é opcional (NULL): se ausente, o User completa via Primeiro
-- Acesso no primeiro login (ver SetUsername).
INSERT INTO users (name, email, password_hash, role, username)
VALUES ($1, $2, $3, $4, $5)
RETURNING *;

-- name: IsUsernameTaken :one
SELECT EXISTS (SELECT 1 FROM users WHERE username = $1) AS taken;

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
-- Só aplica se o User ainda não tiver username — usada pelo Primeiro Acesso.
UPDATE users SET username = $2, updated_at = now()
WHERE id = $1 AND username IS NULL
RETURNING *;

-- name: UpdateUsername :one
-- Troca o username já definido — usada pela tela de Perfil. Sem a restrição
-- username IS NULL do Primeiro Acesso; a unicidade continua garantida pela
-- constraint users_username_key.
UPDATE users SET username = $2, updated_at = now()
WHERE id = $1
RETURNING *;

-- name: SetPasswordHash :one
UPDATE users SET password_hash = $2, updated_at = now() WHERE id = $1 RETURNING *;

-- name: SetName :one
UPDATE users SET name = $2, updated_at = now() WHERE id = $1 RETURNING *;
