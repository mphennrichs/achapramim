DROP TABLE IF EXISTS default_blocked_words;

ALTER TABLE scan_settings
    DROP COLUMN IF EXISTS default_city,
    DROP COLUMN IF EXISTS default_state;

ALTER TABLE watches
    DROP COLUMN IF EXISTS city,
    DROP COLUMN IF EXISTS state;
