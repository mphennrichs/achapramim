-- name: CreateScan :one
INSERT INTO scans (watch_id, status) VALUES ($1, 'success') RETURNING *;

-- name: FinishScan :one
UPDATE scans SET status = $2, finished_at = now(), offers_found = $3
WHERE id = $1
RETURNING *;

-- name: RecordScanMarketplaceFailure :exec
INSERT INTO scan_marketplace_failures (scan_id, marketplace_slug, error_message)
VALUES ($1, $2, $3);
