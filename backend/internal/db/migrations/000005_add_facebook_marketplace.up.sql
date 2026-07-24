-- Reintroduz o slug removido em 000004: Facebook Marketplace agora tem um
-- Fetcher viável via Apify (actor apify/facebook-marketplace-scraper), que
-- assume a conta/sessão autenticada por conta própria — ver ADR 0006.
INSERT INTO marketplaces (slug) VALUES ('facebook_marketplace');
