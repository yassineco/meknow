-- =====================================================
-- TABLE DE STOCKAGE DES PRODUITS (PERSISTENT)
-- =====================================================
-- Cette table persiste les données produits en PostgreSQL
-- au lieu d'utiliser un fichier JSON temporaire

CREATE TABLE IF NOT EXISTS products_data (
    id SERIAL PRIMARY KEY,
    products JSONB NOT NULL,                    -- Tous les produits en JSON
    collections JSONB DEFAULT '[]'::jsonb,     -- Collections associées
    version INTEGER DEFAULT 1,                 -- Version des données
    last_modified_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Index pour les performances
    UNIQUE(version)
);

-- Commentaire de la table
COMMENT ON TABLE products_data IS 'Stockage persistant des produits et collections en JSON';
COMMENT ON COLUMN products_data.products IS 'Array JSONB contenant tous les produits';
COMMENT ON COLUMN products_data.collections IS 'Array JSONB contenant les collections';
COMMENT ON COLUMN products_data.version IS 'Numéro de version pour la migration';
COMMENT ON COLUMN products_data.last_modified_at IS 'Timestamp de la dernière modification';

-- Index pour les requêtes rapides
CREATE INDEX IF NOT EXISTS idx_products_data_version ON products_data(version);
CREATE INDEX IF NOT EXISTS idx_products_data_modified ON products_data(last_modified_at);

-- Fonction pour obtenir les produits actuels
CREATE OR REPLACE FUNCTION get_current_products()
RETURNS JSONB AS $$
SELECT COALESCE(products, '[]'::jsonb)
FROM products_data
ORDER BY version DESC
LIMIT 1;
$$ LANGUAGE SQL;

-- Fonction pour mettre à jour les produits
CREATE OR REPLACE FUNCTION update_products_data(new_products JSONB, new_collections JSONB DEFAULT '[]'::jsonb)
RETURNS TABLE(success boolean, message text, version integer) AS $$
DECLARE
    new_version integer;
BEGIN
    -- Incrémenter la version
    new_version := COALESCE((SELECT MAX(version) FROM products_data), 0) + 1;
    
    -- Insérer les nouvelles données
    INSERT INTO products_data (products, collections, version, last_modified_at)
    VALUES (new_products, new_collections, new_version, CURRENT_TIMESTAMP)
    ON CONFLICT (version) DO UPDATE
    SET products = new_products,
        collections = new_collections,
        last_modified_at = CURRENT_TIMESTAMP;
    
    RETURN QUERY SELECT true, 'Products updated successfully'::text, new_version;
END;
$$ LANGUAGE plpgsql;

-- Insérer les données initiales si la table est vide
INSERT INTO products_data (products, collections, version)
SELECT '[]'::jsonb, '[]'::jsonb, 1
WHERE NOT EXISTS (SELECT 1 FROM products_data);
