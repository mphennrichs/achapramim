-- OLX é o único Marketplace com Fetcher funcional (ver ADR 0003) — Mercado
-- Livre e Facebook Marketplace nunca tiveram uma implementação de fato (só o
-- slug reservado desde o início), então removê-los é seguro sem migração de
-- dados: nenhum Watch/Offer/Scan em produção referencia esses slugs.
DELETE FROM marketplaces WHERE slug IN ('mercado_livre', 'facebook_marketplace');
