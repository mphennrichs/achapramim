-- Região de busca: cidade/estado opcionais por Watch (com fallback para o
-- padrão global em scan_settings quando o Watch não define os seus).
ALTER TABLE watches
    ADD COLUMN city TEXT,
    ADD COLUMN state TEXT;

ALTER TABLE scan_settings
    ADD COLUMN default_city TEXT NOT NULL DEFAULT 'Belo Horizonte',
    ADD COLUMN default_state TEXT NOT NULL DEFAULT 'MG';

-- Palavras bloqueadas default: seed global (admin-controlado), copiado para
-- a lista por-Watch (watch_blocked_words) apenas no momento da criação do
-- Watch — edição posterior do usuário não é afetada pela lista global.
CREATE TABLE default_blocked_words (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    term TEXT NOT NULL UNIQUE
);

INSERT INTO default_blocked_words (term) VALUES
    ('quebrado'),
    ('quebrada'),
    ('sucata'),
    ('para peças'),
    ('para peca'),
    ('para pecas'),
    ('no estado'),
    ('avariado'),
    ('avariada'),
    ('danificado'),
    ('danificada'),
    ('defeito'),
    ('com defeito'),
    ('não funciona'),
    ('nao funciona');
