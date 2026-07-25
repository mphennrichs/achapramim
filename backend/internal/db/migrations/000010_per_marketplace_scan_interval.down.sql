ALTER TABLE scans DROP COLUMN marketplace_slug;
DROP INDEX idx_watch_marketplaces_next_scan_at;
ALTER TABLE watch_marketplaces DROP COLUMN next_scan_at;
DROP TABLE marketplace_scan_settings;
