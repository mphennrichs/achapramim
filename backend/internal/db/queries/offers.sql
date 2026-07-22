-- name: UpsertOffer :one
-- Cria a Offer se for a primeira vez que este anúncio aparece neste Watch,
-- ou atualiza os dados observados se já existia (reverificação). first_seen_scan_id
-- só é setado na criação; last_checked_scan_id é sempre atualizado.
INSERT INTO offers (
    watch_id, marketplace_slug, external_id, url, title, image_url,
    price_cents, classification, available, first_seen_scan_id, last_checked_scan_id
)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, TRUE, $9, $9)
ON CONFLICT (watch_id, marketplace_slug, external_id) DO UPDATE SET
    url = EXCLUDED.url,
    title = EXCLUDED.title,
    image_url = EXCLUDED.image_url,
    price_cents = EXCLUDED.price_cents,
    classification = EXCLUDED.classification,
    available = TRUE,
    last_checked_scan_id = EXCLUDED.last_checked_scan_id,
    updated_at = now()
RETURNING *, (xmax = 0) AS is_new;

-- name: TopOffersByWatch :many
-- Offers atualmente exibidas (top-N pelo limite do Watch): são as únicas
-- reverificadas a cada Scan, conforme o domínio.
SELECT * FROM offers
WHERE watch_id = $1 AND available
ORDER BY classification DESC
LIMIT $2;

-- name: MarkOffersUnavailableNotIn :exec
-- Marca como indisponíveis as Offers que estavam no top-N e não vieram mais
-- no resultado do Scan atual (anúncio vendido/removido).
UPDATE offers SET available = FALSE, updated_at = now()
WHERE watch_id = $1
  AND available
  AND external_id != ALL(sqlc.arg(seen_external_ids)::text[]);

-- name: GetOfferByID :one
SELECT * FROM offers WHERE id = $1;

-- name: ListOfferPricePoints :many
SELECT * FROM offer_price_points WHERE offer_id = $1 ORDER BY observed_at ASC;

-- name: InsertOfferPricePointIfChanged :exec
-- Um novo ponto de Histórico de Preço só é registrado quando o valor difere
-- do último observado (reverificação sem mudança não gera ponto novo).
INSERT INTO offer_price_points (offer_id, price_cents, scan_id)
SELECT $1, $2, $3
WHERE NOT EXISTS (
    SELECT 1 FROM offer_price_points
    WHERE offer_id = $1
    ORDER BY observed_at DESC
    LIMIT 1
) OR (
    SELECT price_cents FROM offer_price_points
    WHERE offer_id = $1
    ORDER BY observed_at DESC
    LIMIT 1
) != $2;
