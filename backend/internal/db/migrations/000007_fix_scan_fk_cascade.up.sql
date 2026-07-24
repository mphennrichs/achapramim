-- Corrige exclusão de Watch retornando 500: offers.first_seen_scan_id,
-- offers.last_checked_scan_id e offer_price_points.scan_id referenciavam
-- scans sem ON DELETE CASCADE. Como watches -> scans já é cascade, apagar um
-- Watch tenta apagar seus Scans enquanto Offers/Histórico de Preço ainda os
-- referenciam sem cascade, violando a FK.
ALTER TABLE offers DROP CONSTRAINT offers_first_seen_scan_id_fkey;
ALTER TABLE offers ADD CONSTRAINT offers_first_seen_scan_id_fkey
    FOREIGN KEY (first_seen_scan_id) REFERENCES scans (id) ON DELETE CASCADE;

ALTER TABLE offers DROP CONSTRAINT offers_last_checked_scan_id_fkey;
ALTER TABLE offers ADD CONSTRAINT offers_last_checked_scan_id_fkey
    FOREIGN KEY (last_checked_scan_id) REFERENCES scans (id) ON DELETE CASCADE;

ALTER TABLE offer_price_points DROP CONSTRAINT offer_price_points_scan_id_fkey;
ALTER TABLE offer_price_points ADD CONSTRAINT offer_price_points_scan_id_fkey
    FOREIGN KEY (scan_id) REFERENCES scans (id) ON DELETE CASCADE;
