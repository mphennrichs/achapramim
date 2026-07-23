ALTER TABLE users
    ADD COLUMN username TEXT UNIQUE;

ALTER TABLE users
    ADD CONSTRAINT username_format CHECK (username IS NULL OR username ~ '^[a-z0-9_]{3,30}$');
