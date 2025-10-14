-- Initialisation de la base de données Meknow
-- Ce script est exécuté automatiquement au démarrage de PostgreSQL

-- Création des tables principales
CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL DEFAULT 0,
    stock INTEGER NOT NULL DEFAULT 0,
    image_url TEXT,
    category VARCHAR(100),
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS product_variants (
    id SERIAL PRIMARY KEY,
    product_id INTEGER REFERENCES products(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    sku VARCHAR(100) UNIQUE,
    price DECIMAL(10,2) NOT NULL,
    stock INTEGER NOT NULL DEFAULT 0,
    attributes JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS customers (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone VARCHAR(20),
    address TEXT,
    city VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(id),
    order_number VARCHAR(50) UNIQUE NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    payment_status VARCHAR(50) DEFAULT 'pending',
    payment_method VARCHAR(50) DEFAULT 'cod',
    subtotal DECIMAL(10,2) NOT NULL DEFAULT 0,
    shipping DECIMAL(10,2) NOT NULL DEFAULT 0,
    tax DECIMAL(10,2) NOT NULL DEFAULT 0,
    total DECIMAL(10,2) NOT NULL DEFAULT 0,
    shipping_address JSONB,
    billing_address JSONB,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products(id),
    variant_id INTEGER REFERENCES product_variants(id),
    quantity INTEGER NOT NULL DEFAULT 1,
    unit_price DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS inventory_movements (
    id SERIAL PRIMARY KEY,
    product_id INTEGER REFERENCES products(id),
    variant_id INTEGER REFERENCES product_variants(id),
    type VARCHAR(50) NOT NULL, -- 'in', 'out', 'adjustment'
    quantity INTEGER NOT NULL,
    reference VARCHAR(255), -- order_id, adjustment_id, etc.
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index pour les performances
CREATE INDEX IF NOT EXISTS idx_products_status ON products(status);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_customer ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_order_items_order ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_inventory_product ON inventory_movements(product_id);

-- Insertion de données de test
INSERT INTO products (name, description, price, stock, image_url, category) VALUES 
('Veste Premium Noir', 'Veste élégante en cuir noir, parfaite pour toutes occasions', 299.00, 15, '/uploads/jacket-black.jpg', 'Vestes'),
('Pantalon Chino Beige', 'Pantalon chino confortable en coton, coupe moderne', 89.00, 25, '/uploads/pants-beige.jpg', 'Pantalons'),
('Chemise Oxford Blanche', 'Chemise classique en coton Oxford, indispensable du dressing', 65.00, 30, '/uploads/shirt-white.jpg', 'Chemises'),
('Sneakers Cuir Blanc', 'Baskets en cuir véritable, design minimaliste et moderne', 159.00, 20, '/uploads/sneakers-white.jpg', 'Chaussures')
ON CONFLICT DO NOTHING;

-- Insertion de variantes pour le premier produit
INSERT INTO product_variants (product_id, name, sku, price, stock, attributes) VALUES 
(1, 'Veste Premium Noir - S', 'VPN-S', 299.00, 5, '{"size": "S", "color": "Noir"}'),
(1, 'Veste Premium Noir - M', 'VPN-M', 299.00, 5, '{"size": "M", "color": "Noir"}'),
(1, 'Veste Premium Noir - L', 'VPN-L', 299.00, 5, '{"size": "L", "color": "Noir"}')
ON CONFLICT DO NOTHING;

-- Trigger pour mettre à jour updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON orders FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Fonction pour générer un numéro de commande
CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS TEXT AS $$
BEGIN
    RETURN 'MKN' || TO_CHAR(NOW(), 'YYYYMMDD') || LPAD(nextval('orders_id_seq')::TEXT, 4, '0');
END;
$$ LANGUAGE plpgsql;

-- Vue pour les statistiques rapides
CREATE OR REPLACE VIEW admin_stats AS
SELECT 
    (SELECT COUNT(*) FROM products WHERE status = 'active') as total_products,
    (SELECT COUNT(*) FROM orders WHERE status != 'cancelled') as total_orders,
    (SELECT COALESCE(SUM(total), 0) FROM orders WHERE status = 'completed') as total_revenue,
    (SELECT COUNT(*) FROM customers) as total_customers,
    (SELECT COUNT(*) FROM products WHERE stock < 5) as low_stock_products;

COMMENT ON VIEW admin_stats IS 'Statistiques rapides pour le dashboard admin';

-- Notification pour les changements d'inventaire
CREATE OR REPLACE FUNCTION notify_stock_change()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.stock != OLD.stock AND NEW.stock < 5 THEN
        PERFORM pg_notify('low_stock', json_build_object('product_id', NEW.id, 'stock', NEW.stock, 'name', NEW.name)::text);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER stock_change_notification 
    AFTER UPDATE OF stock ON products 
    FOR EACH ROW 
    EXECUTE FUNCTION notify_stock_change();

-- Permissions (si nécessaire pour d'autres utilisateurs)
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO meknow_user;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO meknow_user;