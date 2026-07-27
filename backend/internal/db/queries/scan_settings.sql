-- name: GetScanSettings :one
SELECT * FROM scan_settings WHERE id = TRUE;

-- name: UpdateScanSettings :one
UPDATE scan_settings
SET default_city = $1,
    default_state = $2,
    updated_at = now()
WHERE id = TRUE
RETURNING *;
