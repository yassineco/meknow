-- =====================================================
-- SCHEMA DE BASE DE DONNÉES MEKNOW E-COMMERCE
-- Version 1.0 - Architecture complète
-- =====================================================

-- Suppression des tables existantes (si elles existent)
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS product_variants CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS inventory_movements CASCADE;
DROP TABLE IF EXISTS admin_users CASCADE;
DROP TABLE IF EXISTS admin_sessions CASCADE;
DROP TABLE IF EXISTS admin_logs CASCADE;
DROP TABLE IF EXISTS settings CASCADE;

-- =====================================================
-- 1. GESTION DES ADMINISTRATEURS
-- =====================================================

CREATE TABLE admin_users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    role VARCHAR(50) DEFAULT 'admin',
    is_active BOOLEAN DEFAULT true,
    last_login_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE admin_sessions (
    id SERIAL PRIMARY KEY,
    admin_id INTEGER REFERENCES admin_users(id) ON DELETE CASCADE,
    token VARCHAR(255) UNIQUE NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE admin_logs (
    id SERIAL PRIMARY KEY,
    admin_id INTEGER REFERENCES admin_users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(50),
    resource_id VARCHAR(100),
    details JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 2. GESTION DES PRODUITS
-- =====================================================

CREATE TABLE products (
    id VARCHAR(50) PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    handle VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
    
    -- Images
    thumbnail VARCHAR(500),
    images JSONB DEFAULT '[]',
    
    -- Informations produit
    weight INTEGER, -- en grammes
    length INTEGER, -- en cm
    width INTEGER,  -- en cm
    height INTEGER, -- en cm
    
    -- Origine et matériau
    origin_country VARCHAR(3) DEFAULT 'FR',
    material VARCHAR(255),
    
    -- SEO
    seo_title VARCHAR(255),
    seo_description TEXT,
    
    -- Métadonnées
    metadata JSONB DEFAULT '{}',
    
    -- Dates
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    published_at TIMESTAMP
);

CREATE TABLE product_variants (
    id VARCHAR(50) PRIMARY KEY,
    product_id VARCHAR(50) REFERENCES products(id) ON DELETE CASCADE,
    
    -- Informations variant
    title VARCHAR(100) NOT NULL, -- ex: "S", "M", "Rouge - M"
    sku VARCHAR(100) UNIQUE,
    barcode VARCHAR(100),
    
    -- Prix (en centimes pour éviter les problèmes de floating point)
    price INTEGER NOT NULL, -- en centimes EUR
    compare_at_price INTEGER, -- prix barré
    cost_price INTEGER, -- prix d'achat
    
    -- Gestion du stock
    inventory_quantity INTEGER DEFAULT 0,
    inventory_policy VARCHAR(20) DEFAULT 'deny' CHECK (inventory_policy IN ('continue', 'deny')),
    fulfillment_service VARCHAR(50) DEFAULT 'manual',
    inventory_management VARCHAR(20) DEFAULT 'meknow',
    
    -- Poids et dimensions (peut différer du produit principal)
    weight INTEGER,
    
    -- Attributs spécifiques (couleur, taille, etc.)
    option1 VARCHAR(100), -- ex: "Taille"
    option2 VARCHAR(100), -- ex: "Couleur"
    option3 VARCHAR(100), -- ex: "Matière"
    
    -- Disponibilité
    requires_shipping BOOLEAN DEFAULT true,
    taxable BOOLEAN DEFAULT true,
    
    -- Dates
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 3. GESTION DES CLIENTS
-- =====================================================

CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone VARCHAR(20),
    
    -- Adresse de facturation par défaut
    billing_address JSONB,
    
    -- Adresse de livraison par défaut
    shipping_address JSONB,
    
    -- Informations client
    accepts_marketing BOOLEAN DEFAULT false,
    tax_exempt BOOLEAN DEFAULT false,
    
    -- Statistiques
    orders_count INTEGER DEFAULT 0,
    total_spent INTEGER DEFAULT 0, -- en centimes
    
    -- Métadonnées
    note TEXT,
    tags TEXT[], -- array de tags
    metadata JSONB DEFAULT '{}',
    
    -- Dates
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_order_at TIMESTAMP
);

-- =====================================================
-- 4. GESTION DES COMMANDES
-- =====================================================

CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    order_number VARCHAR(50) UNIQUE NOT NULL,
    customer_id INTEGER REFERENCES customers(id) ON DELETE SET NULL,
    
    -- Statuts
    fulfillment_status VARCHAR(20) DEFAULT 'unfulfilled' CHECK (fulfillment_status IN ('fulfilled', 'partial', 'unfulfilled')),
    financial_status VARCHAR(20) DEFAULT 'pending' CHECK (financial_status IN ('pending', 'paid', 'partially_paid', 'refunded', 'voided')),
    
    -- Adresses
    billing_address JSONB NOT NULL,
    shipping_address JSONB NOT NULL,
    
    -- Montants (en centimes)
    subtotal INTEGER NOT NULL,
    total_tax INTEGER DEFAULT 0,
    total_discounts INTEGER DEFAULT 0,
    shipping_cost INTEGER DEFAULT 0,
    total INTEGER NOT NULL,
    
    -- Informations de paiement
    payment_method VARCHAR(50) DEFAULT 'cod', -- 'cod', 'stripe', 'paypal'
    payment_status VARCHAR(20) DEFAULT 'pending',
    payment_details JSONB DEFAULT '{}',
    
    -- Livraison
    shipping_method VARCHAR(100),
    tracking_number VARCHAR(100),
    carrier VARCHAR(100),
    
    -- Notes
    note TEXT,
    customer_note TEXT,
    
    -- Métadonnées
    source_name VARCHAR(50) DEFAULT 'web',
    tags TEXT[],
    metadata JSONB DEFAULT '{}',
    
    -- Dates importantes
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP,
    shipped_at TIMESTAMP,
    delivered_at TIMESTAMP,
    cancelled_at TIMESTAMP,
    cancel_reason TEXT
);

CREATE TABLE order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE,
    product_id VARCHAR(50) REFERENCES products(id) ON DELETE SET NULL,
    variant_id VARCHAR(50) REFERENCES product_variants(id) ON DELETE SET NULL,
    
    -- Informations de la ligne
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    price INTEGER NOT NULL, -- prix unitaire en centimes
    total INTEGER NOT NULL, -- prix total de la ligne
    
    -- Informations produit au moment de la commande (snapshot)
    product_title VARCHAR(255),
    variant_title VARCHAR(255),
    sku VARCHAR(100),
    
    -- Dates
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 5. GESTION DU STOCK ET INVENTAIRE
-- =====================================================

CREATE TABLE inventory_movements (
    id SERIAL PRIMARY KEY,
    variant_id VARCHAR(50) REFERENCES product_variants(id) ON DELETE CASCADE,
    
    -- Mouvement
    quantity_change INTEGER NOT NULL, -- peut être négatif
    quantity_before INTEGER NOT NULL,
    quantity_after INTEGER NOT NULL,
    
    -- Raison du mouvement
    reason VARCHAR(50) NOT NULL CHECK (reason IN ('manual_adjustment', 'sale', 'return', 'damage', 'restock', 'transfer')),
    reference_type VARCHAR(50), -- 'order', 'manual', 'return'
    reference_id VARCHAR(100), -- ID de la commande, etc.
    
    -- Informations
    note TEXT,
    admin_id INTEGER REFERENCES admin_users(id) ON DELETE SET NULL,
    
    -- Dates
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 6. PARAMÈTRES SYSTÈME
-- =====================================================

CREATE TABLE settings (
    id SERIAL PRIMARY KEY,
    key VARCHAR(100) UNIQUE NOT NULL,
    value JSONB,
    description TEXT,
    category VARCHAR(50) DEFAULT 'general',
    is_public BOOLEAN DEFAULT false, -- si accessible côté frontend
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 7. INDEX POUR LES PERFORMANCES
-- =====================================================

-- Index pour les produits
CREATE INDEX idx_products_status ON products(status);
CREATE INDEX idx_products_handle ON products(handle);
CREATE INDEX idx_products_created_at ON products(created_at);

-- Index pour les variants
CREATE INDEX idx_variants_product_id ON product_variants(product_id);
CREATE INDEX idx_variants_sku ON product_variants(sku);
CREATE INDEX idx_variants_inventory ON product_variants(inventory_quantity);

-- Index pour les commandes
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_orders_status ON orders(fulfillment_status, financial_status);
CREATE INDEX idx_orders_created_at ON orders(created_at);
CREATE INDEX idx_orders_order_number ON orders(order_number);

-- Index pour les clients
CREATE INDEX idx_customers_email ON customers(email);
CREATE INDEX idx_customers_created_at ON customers(created_at);

-- Index pour les mouvements de stock
CREATE INDEX idx_inventory_variant_id ON inventory_movements(variant_id);
CREATE INDEX idx_inventory_created_at ON inventory_movements(created_at);

-- Index pour les logs admin
CREATE INDEX idx_admin_logs_admin_id ON admin_logs(admin_id);
CREATE INDEX idx_admin_logs_created_at ON admin_logs(created_at);

-- =====================================================
-- 8. TRIGGERS POUR MISE À JOUR AUTOMATIQUE
-- =====================================================

-- Fonction pour mettre à jour updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers
CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_variants_updated_at BEFORE UPDATE ON product_variants FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_customers_updated_at BEFORE UPDATE ON customers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON orders FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_admin_users_updated_at BEFORE UPDATE ON admin_users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 9. DONNÉES INITIALES
-- =====================================================

-- Utilisateur admin par défaut
INSERT INTO admin_users (email, password_hash, first_name, last_name, role) VALUES 
('admin@meknow.fr', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Admin', 'Meknow', 'admin');

-- Paramètres système de base
INSERT INTO settings (key, value, description, category, is_public) VALUES 
('store_name', '"Meknow"', 'Nom de la boutique', 'general', true),
('store_email', '"contact@meknow.fr"', 'Email de contact', 'general', true),
('currency', '"EUR"', 'Devise par défaut', 'general', true),
('tax_rate', '0.20', 'Taux de TVA (20%)', 'tax', false),
('shipping_cost', '0', 'Frais de livraison en centimes', 'shipping', true),
('cod_enabled', 'true', 'Paiement comptant activé', 'payment', true),
('low_stock_threshold', '10', 'Seuil d''alerte stock faible', 'inventory', false);

-- =====================================================
-- SCHEMA TERMINÉ
-- =====================================================