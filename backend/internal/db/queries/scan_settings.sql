-- name: GetScanSettings :one
SELECT * FROM scan_settings WHERE id = TRUE;

-- name: UpdateScanSettings :one
UPDATE scan_settings
SET min_interval_minutes = $1,
    max_interval_minutes = $2,
    default_city = $3,
    default_state = $4,
    updated_at = now()
WHERE id = TRUE
RETURNING *;
