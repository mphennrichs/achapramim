ALTER TABLE users
    DROP CONSTRAINT IF EXISTS username_format;

ALTER TABLE users
    DROP COLUMN IF EXISTS username;
