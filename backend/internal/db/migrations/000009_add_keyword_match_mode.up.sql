-- Modo de correspondência das palavras-chave de um Watch: 'any' (hoje, o
-- único comportamento existente) considera qualquer anúncio, com a fração
-- de palavras batidas só influenciando a Classificação/ranking; 'all' filtra
-- de verdade — um anúncio que não contém TODAS as keywords no título nem
-- chega a ser salvo como Offer (mesmo mecanismo de exclusão que
-- blocked_words já usa, mas invertido).
CREATE TYPE keyword_match_mode AS ENUM ('any', 'all');

ALTER TABLE watches ADD COLUMN keyword_match_mode keyword_match_mode NOT NULL DEFAULT 'any';
