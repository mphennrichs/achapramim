ALTER TABLE offers DROP CONSTRAINT offers_first_seen_scan_id_fkey;
ALTER TABLE offers ADD CONSTRAINT offers_first_seen_scan_id_fkey
    FOREIGN KEY (first_seen_scan_id) REFERENCES scans (id);

ALTER TABLE offers DROP CONSTRAINT offers_last_checked_scan_id_fkey;
ALTER TABLE offers ADD CONSTRAINT offers_last_checked_scan_id_fkey
    FOREIGN KEY (last_checked_scan_id) REFERENCES scans (id);

ALTER TABLE offer_price_points DROP CONSTRAINT offer_price_points_scan_id_fkey;
ALTER TABLE offer_price_points ADD CONSTRAINT offer_price_points_scan_id_fkey
    FOREIGN KEY (scan_id) REFERENCES scans (id);
