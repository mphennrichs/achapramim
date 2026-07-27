ALTER TABLE scan_settings ADD COLUMN min_interval_minutes INTEGER NOT NULL DEFAULT 30 CHECK (min_interval_minutes >= 1);
ALTER TABLE scan_settings ADD COLUMN max_interval_minutes INTEGER NOT NULL DEFAULT 120 CHECK (max_interval_minutes <= 1440);
ALTER TABLE scan_settings ADD CHECK (min_interval_minutes <= max_interval_minutes);
