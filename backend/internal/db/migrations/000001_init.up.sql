CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE roles (
    name TEXT PRIMARY KEY
);

INSERT INTO roles (name) VALUES ('admin'), ('user');

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    role TEXT NOT NULL REFERENCES roles (name),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    token_hash TEXT NOT NULL UNIQUE,
    expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens (user_id);

-- Configuração global de Scan (linha única, admin-controlada)
CREATE TABLE scan_settings (
    id BOOLEAN PRIMARY KEY DEFAULT TRUE CHECK (id),
    min_interval_minutes INTEGER NOT NULL DEFAULT 30 CHECK (min_interval_minutes >= 1),
    max_interval_minutes INTEGER NOT NULL DEFAULT 120 CHECK (max_interval_minutes <= 1440),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (min_interval_minutes <= max_interval_minutes)
);

INSERT INTO scan_settings (id) VALUES (TRUE);

CREATE TABLE marketplaces (
    slug TEXT PRIMARY KEY
);

INSERT INTO marketplaces (slug) VALUES ('mercado_livre'), ('olx'), ('facebook_marketplace');

CREATE TABLE watches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    target_price_cents BIGINT NOT NULL CHECK (target_price_cents >= 0),
    tolerance_percent NUMERIC(5, 2) NOT NULL CHECK (tolerance_percent >= 0),
    max_offers INTEGER NOT NULL CHECK (max_offers >= 1),
    price_drop_threshold_percent NUMERIC(5, 2) NOT NULL CHECK (price_drop_threshold_percent >= 0),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    next_scan_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_watches_user_id ON watches (user_id);
CREATE INDEX idx_watches_next_scan_at ON watches (next_scan_at) WHERE active;

CREATE TABLE watch_marketplaces (
    watch_id UUID NOT NULL REFERENCES watches (id) ON DELETE CASCADE,
    marketplace_slug TEXT NOT NULL REFERENCES marketplaces (slug),
    PRIMARY KEY (watch_id, marketplace_slug)
);

-- Palavras-chave e palavras bloqueadas: listas simples de strings, sem
-- vínculo rastreável entre uma palavra e os sinônimos aceitos a partir dela.
CREATE TABLE watch_keywords (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    watch_id UUID NOT NULL REFERENCES watches (id) ON DELETE CASCADE,
    term TEXT NOT NULL
);

CREATE INDEX idx_watch_keywords_watch_id ON watch_keywords (watch_id);

CREATE TABLE watch_blocked_words (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    watch_id UUID NOT NULL REFERENCES watches (id) ON DELETE CASCADE,
    term TEXT NOT NULL
);

CREATE INDEX idx_watch_blocked_words_watch_id ON watch_blocked_words (watch_id);

CREATE TYPE scan_status AS ENUM ('success', 'partial', 'failed');

CREATE TABLE scans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    watch_id UUID NOT NULL REFERENCES watches (id) ON DELETE CASCADE,
    status scan_status NOT NULL,
    started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    finished_at TIMESTAMPTZ,
    offers_found INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX idx_scans_watch_id ON scans (watch_id);

-- Marketplaces que falharam num Scan de sucesso parcial.
CREATE TABLE scan_marketplace_failures (
    scan_id UUID NOT NULL REFERENCES scans (id) ON DELETE CASCADE,
    marketplace_slug TEXT NOT NULL REFERENCES marketplaces (slug),
    error_message TEXT,
    PRIMARY KEY (scan_id, marketplace_slug)
);

CREATE TABLE offers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    watch_id UUID NOT NULL REFERENCES watches (id) ON DELETE CASCADE,
    marketplace_slug TEXT NOT NULL REFERENCES marketplaces (slug),
    external_id TEXT NOT NULL,
    url TEXT NOT NULL,
    title TEXT NOT NULL,
    image_url TEXT NOT NULL,
    price_cents BIGINT NOT NULL CHECK (price_cents >= 0),
    classification NUMERIC(10, 4) NOT NULL,
    available BOOLEAN NOT NULL DEFAULT TRUE,
    first_seen_scan_id UUID NOT NULL REFERENCES scans (id),
    last_checked_scan_id UUID NOT NULL REFERENCES scans (id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    -- Identidade da Offer = external_id do marketplace, escopado por Watch.
    UNIQUE (watch_id, marketplace_slug, external_id)
);

CREATE INDEX idx_offers_watch_id ON offers (watch_id);
CREATE INDEX idx_offers_watch_available_classification
    ON offers (watch_id, available, classification DESC);

-- Histórico de Preço: um ponto por mudança de valor observada, não por Scan.
CREATE TABLE offer_price_points (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    offer_id UUID NOT NULL REFERENCES offers (id) ON DELETE CASCADE,
    price_cents BIGINT NOT NULL CHECK (price_cents >= 0),
    observed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    scan_id UUID NOT NULL REFERENCES scans (id)
);

CREATE INDEX idx_offer_price_points_offer_id ON offer_price_points (offer_id, observed_at);

CREATE TYPE channel_type AS ENUM ('whatsapp', 'telegram', 'email');

CREATE TABLE user_channels (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    channel_type channel_type NOT NULL,
    -- telefone p/ whatsapp, chat_id p/ telegram, email p/ email
    destination TEXT NOT NULL,
    -- token usado no deep-link t.me/<bot>?start=<token> até a vinculação ser confirmada
    telegram_link_token TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, channel_type)
);

CREATE TYPE notification_trigger AS ENUM ('new_offer', 'price_drop');
CREATE TYPE notification_status AS ENUM ('pending', 'sent', 'failed');

CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    offer_id UUID NOT NULL REFERENCES offers (id) ON DELETE CASCADE,
    channel_type channel_type NOT NULL,
    trigger notification_trigger NOT NULL,
    status notification_status NOT NULL DEFAULT 'pending',
    attempts INTEGER NOT NULL DEFAULT 0,
    last_error TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    sent_at TIMESTAMPTZ
);

CREATE INDEX idx_notifications_user_id ON notifications (user_id);
CREATE INDEX idx_notifications_status ON notifications (status) WHERE status = 'pending';
