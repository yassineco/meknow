const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { Pool } = require('pg');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 9000;

// Debug function
function debugLog(message, data = null) {
  console.log('[DEBUG]', message, data ? JSON.stringify(data, null, 2) : '');
}

// =====================================================
// CONFIGURATION BASE DE DONNÉES
// =====================================================

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'meknow_production',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'meknow2024!',
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Test de connexion DB
pool.connect((err, client, release) => {
  if (err) {
    console.error('❌ Erreur connexion PostgreSQL:', err);
  } else {
    console.log('✅ Connexion PostgreSQL établie');
    release();
  }
});

// =====================================================
// CONFIGURATION MIDDLEWARE
// =====================================================

app.use(cors({
  origin: [
    'http://localhost:3000',
    'http://localhost:5000', 
    'http://localhost:8080',
    'https://meknow.fr',
    'http://127.0.0.1:8080',
    'http://127.0.0.1:3000'
  ],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept', 'Origin', 'X-Requested-With']
}));

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Servir les fichiers statiques
app.use('/assets', express.static('./assets'));
app.use('/public', express.static('./public'));

// Route pour l'interface admin
app.get('/admin', (req, res) => {
  res.sendFile(path.join(__dirname, 'admin-complete-ecommerce.html'));
});

// Route pour la page de login
app.get('/login', (req, res) => {
  res.sendFile(path.join(__dirname, 'admin-login.html'));
});

// =====================================================
// UTILITAIRES ET HELPERS
// =====================================================

// Générer un ID unique pour les produits
function generateProductId() {
  return 'prod_' + Date.now().toString(36) + Math.random().toString(36).substr(2);
}

// Générer un ID unique pour les variants
function generateVariantId() {
  return 'variant_' + Date.now().toString(36) + Math.random().toString(36).substr(2);
}

// Générer un numéro de commande
function generateOrderNumber() {
  const timestamp = Date.now().toString().slice(-6);
  const random = Math.floor(Math.random() * 1000).toString().padStart(3, '0');
  return `MK${timestamp}${random}`;
}

// Logger pour actions admin
async function logAdminAction(adminId, action, resourceType, resourceId, details, req) {
  try {
    await pool.query(`
      INSERT INTO admin_logs (admin_id, action, resource_type, resource_id, details, ip_address, user_agent)
      VALUES ($1, $2, $3, $4, $5, $6, $7)
    `, [
      adminId,
      action,
      resourceType,
      resourceId,
      JSON.stringify(details),
      req.ip,
      req.get('User-Agent')
    ]);
  } catch (err) {
    console.error('❌ Erreur log admin:', err);
  }
}

// =====================================================
// MIDDLEWARE D'AUTHENTIFICATION
// =====================================================

const JWT_SECRET = process.env.JWT_SECRET || 'meknow-super-secret-key-change-in-production';

// Middleware de vérification JWT
async function authenticateAdmin(req, res, next) {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ 
        success: false, 
        error: 'Token d\'authentification requis' 
      });
    }

    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, JWT_SECRET);

    // Vérifier que la session existe en base
    const sessionResult = await pool.query(`
      SELECT s.*, u.email, u.first_name, u.last_name, u.role, u.is_active
      FROM admin_sessions s
      JOIN admin_users u ON s.admin_id = u.id
      WHERE s.token = $1 AND s.expires_at > NOW() AND u.is_active = true
    `, [token]);

    if (sessionResult.rows.length === 0) {
      return res.status(401).json({ 
        success: false, 
        error: 'Session invalide ou expirée' 
      });
    }

    req.admin = {
      id: decoded.adminId,
      email: sessionResult.rows[0].email,
      name: `${sessionResult.rows[0].first_name} ${sessionResult.rows[0].last_name}`,
      role: sessionResult.rows[0].role
    };

    next();
  } catch (err) {
    console.error('❌ Erreur authentification:', err);
    return res.status(401).json({ 
      success: false, 
      error: 'Token invalide' 
    });
  }
}

// =====================================================
// ROUTES D'AUTHENTIFICATION
// =====================================================

// Connexion admin
app.post('/api/admin/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        error: 'Email et mot de passe requis'
      });
    }

    // Rechercher l'admin
    const adminResult = await pool.query(`
      SELECT id, email, password_hash, first_name, last_name, role, is_active
      FROM admin_users 
      WHERE email = $1 AND is_active = true
    `, [email]);

    if (adminResult.rows.length === 0) {
      return res.status(401).json({
        success: false,
        error: 'Identifiants invalides'
      });
    }

    const admin = adminResult.rows[0];

    // Vérifier le mot de passe
    const isValidPassword = await bcrypt.compare(password, admin.password_hash);
    if (!isValidPassword) {
      return res.status(401).json({
        success: false,
        error: 'Identifiants invalides'
      });
    }

    // Générer un token JWT
    const token = jwt.sign(
      { 
        adminId: admin.id, 
        email: admin.email, 
        role: admin.role 
      },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    // Sauvegarder la session en base
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 jours
    await pool.query(`
      INSERT INTO admin_sessions (admin_id, token, expires_at, ip_address, user_agent)
      VALUES ($1, $2, $3, $4, $5)
    `, [
      admin.id,
      token,
      expiresAt,
      req.ip,
      req.get('User-Agent')
    ]);

    // Mettre à jour last_login_at
    await pool.query(`
      UPDATE admin_users SET last_login_at = CURRENT_TIMESTAMP WHERE id = $1
    `, [admin.id]);

    // Logger la connexion
    await logAdminAction(admin.id, 'login', 'admin', admin.id, { success: true }, req);

    res.json({
      success: true,
      token,
      admin: {
        id: admin.id,
        email: admin.email,
        name: `${admin.first_name} ${admin.last_name}`,
        role: admin.role
      }
    });

  } catch (err) {
    console.error('❌ Erreur login admin:', err);
    res.status(500).json({
      success: false,
      error: 'Erreur serveur lors de la connexion'
    });
  }
});

// Déconnexion admin
app.post('/api/admin/logout', authenticateAdmin, async (req, res) => {
  try {
    const token = req.headers.authorization.split(' ')[1];

    // Supprimer la session de la base
    await pool.query(`
      DELETE FROM admin_sessions WHERE token = $1
    `, [token]);

    // Logger la déconnexion
    await logAdminAction(req.admin.id, 'logout', 'admin', req.admin.id, {}, req);

    res.json({
      success: true,
      message: 'Déconnexion réussie'
    });

  } catch (err) {
    console.error('❌ Erreur logout admin:', err);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la déconnexion'
    });
  }
});

// Vérifier le statut de connexion
app.get('/api/admin/me', authenticateAdmin, (req, res) => {
  res.json({
    success: true,
    admin: req.admin
  });
});

// =====================================================
// CONFIGURATION UPLOAD D'IMAGES
// =====================================================

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    const uploadDir = './public/images';
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const extension = path.extname(file.originalname);
    cb(null, 'product-' + uniqueSuffix + extension);
  }
});

const upload = multer({ 
  storage: storage,
  fileFilter: (req, file, cb) => {
    const allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
    if (allowedTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Type de fichier non autorisé'), false);
    }
  },
  limits: { fileSize: 5 * 1024 * 1024 } // 5MB max
});

// Servir les images statiques
app.use('/images', express.static('./public/images'));

// Route d'upload d'images
app.post('/api/upload', authenticateAdmin, upload.single('image'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ 
        success: false, 
        error: 'Aucune image fournie' 
      });
    }

    const imageUrl = `/images/${req.file.filename}`;
    
    // Logger l'upload
    await logAdminAction(req.admin.id, 'upload_image', 'image', req.file.filename, {
      originalName: req.file.originalname,
      size: req.file.size,
      url: imageUrl
    }, req);

    res.json({ 
      success: true, 
      url: imageUrl,
      filename: req.file.filename,
      originalName: req.file.originalname,
      size: req.file.size
    });

  } catch (err) {
    console.error('❌ Erreur upload:', err);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de l\'upload'
    });
  }
});

// =====================================================
// HEALTH CHECK
// =====================================================

app.get('/health', async (req, res) => {
  try {
    // Test DB
    await pool.query('SELECT 1');
    res.json({ 
      status: 'ok', 
      service: 'meknow-backend-v2',
      database: 'connected',
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    res.status(503).json({ 
      status: 'error', 
      service: 'meknow-backend-v2',
      database: 'disconnected',
      error: err.message
    });
  }
});

// =====================================================
// API PRODUITS - LECTURE (PUBLIC)
// =====================================================

// Lister tous les produits (public - pour le frontend)
app.get('/api/products', async (req, res) => {
  try {
    const { limit = 50, offset = 0, status = 'published' } = req.query;

    const result = await pool.query(`
      SELECT 
        p.*,
        JSON_AGG(
          JSON_BUILD_OBJECT(
            'id', pv.id,
            'title', pv.title,
            'sku', pv.sku,
            'price', pv.price,
            'inventory_quantity', pv.inventory_quantity,
            'option1', pv.option1
          )
        ) as variants
      FROM products p
      LEFT JOIN product_variants pv ON p.id = pv.product_id
      WHERE p.status = $1
      GROUP BY p.id
      ORDER BY p.created_at DESC
      LIMIT $2 OFFSET $3
    `, [status, limit, offset]);

    res.json({
      success: true,
      products: result.rows,
      count: result.rows.length
    });

  } catch (err) {
    console.error('❌ Erreur récupération produits:', err);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la récupération des produits'
    });
  }
});

// Récupérer un produit par ID ou handle
app.get('/api/products/:identifier', async (req, res) => {
  try {
    const { identifier } = req.params;
    
    // Détecter si c'est un ID ou un handle
    const isId = identifier.startsWith('prod_');
    const field = isId ? 'id' : 'handle';

    const result = await pool.query(`
      SELECT 
        p.*,
        JSON_AGG(
          JSON_BUILD_OBJECT(
            'id', pv.id,
            'title', pv.title,
            'sku', pv.sku,
            'price', pv.price,
            'compare_at_price', pv.compare_at_price,
            'inventory_quantity', pv.inventory_quantity,
            'inventory_policy', pv.inventory_policy,
            'option1', pv.option1,
            'option2', pv.option2,
            'option3', pv.option3,
            'weight', pv.weight,
            'requires_shipping', pv.requires_shipping
          )
        ) as variants
      FROM products p
      LEFT JOIN product_variants pv ON p.id = pv.product_id
      WHERE p.${field} = $1
      GROUP BY p.id
    `, [identifier]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Produit non trouvé'
      });
    }

    res.json({
      success: true,
      product: result.rows[0]
    });

  } catch (err) {
    console.error('❌ Erreur récupération produit:', err);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la récupération du produit'
    });
  }
});

// Route simple pour créer des produits (pour debug interface admin)
app.post('/api/products', async (req, res) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    
    debugLog('Received product creation request:', req.body);
    
    const {
      title,
      description = '',
      price = 0,
      category = 'general',
      status = 'published',
      imageUrl,
      variants = {}
    } = req.body;

    // Générer un ID de produit
    const productId = generateProductId();
    
    // Créer le produit
    const productResult = await client.query(`
      INSERT INTO products (
        id, title, description, status, thumbnail, category, created_at, updated_at
      ) VALUES ($1, $2, $3, $4, $5, $6, NOW(), NOW())
      RETURNING *
    `, [productId, title, description, status, imageUrl, category]);

    const product = productResult.rows[0];

    // Créer les variants
    const createdVariants = [];
    
    if (variants && typeof variants === 'object') {
      for (const [size, quantity] of Object.entries(variants)) {
        if (quantity > 0) {
          const variantId = generateVariantId();
          const variantResult = await client.query(`
            INSERT INTO product_variants (
              id, product_id, title, sku, price, inventory_quantity, option1
            ) VALUES ($1, $2, $3, $4, $5, $6, $7)
            RETURNING *
          `, [
            variantId, productId, `${title} - ${size}`, 
            `${productId}-${size}`, price * 100, quantity, size
          ]);
          createdVariants.push(variantResult.rows[0]);
        }
      }
    }

    await client.query('COMMIT');
    
    debugLog(`Product created: ${productId} with ${createdVariants.length} variants`);

    res.status(201).json({
      success: true,
      product: {
        ...product,
        variants: createdVariants
      },
      message: `Produit "${title}" créé avec succès`
    });

  } catch (err) {
    await client.query('ROLLBACK');
    console.error('❌ Erreur création produit simple:', err);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la création du produit: ' + err.message
    });
  } finally {
    client.release();
  }
});

// =====================================================
// API PRODUITS ADMIN - GESTION COMPLÈTE
// =====================================================

// Lister tous les produits (admin - avec tous les statuts)
app.get('/api/admin/products', authenticateAdmin, async (req, res) => {
  try {
    const { 
      limit = 50, 
      offset = 0, 
      status, 
      search,
      sort_by = 'created_at',
      sort_order = 'DESC'
    } = req.query;

    let whereClause = 'WHERE 1=1';
    const queryParams = [];
    let paramCount = 0;

    // Filtrer par statut
    if (status) {
      paramCount++;
      whereClause += ` AND p.status = $${paramCount}`;
      queryParams.push(status);
    }

    // Recherche textuelle
    if (search) {
      paramCount++;
      whereClause += ` AND (p.title ILIKE $${paramCount} OR p.description ILIKE $${paramCount})`;
      queryParams.push(`%${search}%`);
    }

    // Paramètres de pagination
    paramCount++;
    const limitParam = paramCount;
    queryParams.push(limit);

    paramCount++;
    const offsetParam = paramCount;
    queryParams.push(offset);

    const query = `
      SELECT 
        p.*,
        JSON_AGG(
          JSON_BUILD_OBJECT(
            'id', pv.id,
            'title', pv.title,
            'sku', pv.sku,
            'price', pv.price,
            'compare_at_price', pv.compare_at_price,
            'inventory_quantity', pv.inventory_quantity,
            'option1', pv.option1
          )
        ) as variants,
        (SELECT SUM(pv2.inventory_quantity) FROM product_variants pv2 WHERE pv2.product_id = p.id) as total_inventory
      FROM products p
      LEFT JOIN product_variants pv ON p.id = pv.product_id
      ${whereClause}
      GROUP BY p.id
      ORDER BY p.${sort_by} ${sort_order}
      LIMIT $${limitParam} OFFSET $${offsetParam}
    `;

    const result = await pool.query(query, queryParams);

    // Compter le total pour la pagination
    const countQuery = `
      SELECT COUNT(DISTINCT p.id) as total
      FROM products p
      ${whereClause.replace(/\$\d+$/, '').replace(/\$\d+$/, '')}
    `;
    const countResult = await pool.query(countQuery, queryParams.slice(0, -2));

    res.json({
      success: true,
      products: result.rows,
      pagination: {
        total: parseInt(countResult.rows[0].total),
        limit: parseInt(limit),
        offset: parseInt(offset),
        has_more: (parseInt(offset) + parseInt(limit)) < parseInt(countResult.rows[0].total)
      }
    });

  } catch (err) {
    console.error('❌ Erreur récupération produits admin:', err);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la récupération des produits'
    });
  }
});

/*
// Récupérer un produit spécifique (admin) - TEMPORAIREMENT DÉSACTIVÉ
app.get('/api/admin/products/:id', authenticateAdmin, async (req, res) => {
  try {
    const { id } = req.params;

    const result = await pool.query(`
      SELECT 
        p.*,
        JSON_AGG(
          JSON_BUILD_OBJECT(
            'id', pv.id,
            'title', pv.title,
            'sku', pv.sku,
            'price', pv.price,
            'inventory_quantity', pv.inventory_quantity,
            'option1', pv.option1,
            'created_at', pv.created_at,
            'updated_at', pv.updated_at
          )
        ) as variants
      FROM products p
      LEFT JOIN product_variants pv ON p.id = pv.product_id
      WHERE p.id = $1
      GROUP BY p.id
    `, [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Produit non trouvé'
      });
    }

    const product = result.rows[0];

    // TODO: Enregistrer l'action dans les logs plus tard
    // await logAdminAction(req.admin.id, 'view', 'product', id, {}, req);

    res.json({
      success: true,
      product: product
    });

  } catch (err) {
    console.error('❌ Erreur récupération produit admin:', err);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la récupération du produit'
    });
  }
});
*/

// Créer un nouveau produit
app.post('/api/admin/products', authenticateAdmin, async (req, res) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const {
      title,
      description,
      status = 'draft',
      thumbnail,
      images = [],
      weight,
      length,
      width,
      height,
      origin_country = 'FR',
      material,
      seo_title,
      seo_description,
      metadata = {},
      variants = []
    } = req.body;

    if (!title) {
      return res.status(400).json({
        success: false,
        error: 'Le titre du produit est requis'
      });
    }

    // Générer l'ID et le handle
    const productId = generateProductId();
    const handle = title
      .toLowerCase()
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '') // supprimer les accents
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-|-$/g, '');

    // Vérifier que le handle est unique
    const handleCheck = await client.query(
      'SELECT id FROM products WHERE handle = $1',
      [handle]
    );

    if (handleCheck.rows.length > 0) {
      return res.status(400).json({
        success: false,
        error: 'Un produit avec ce nom existe déjà'
      });
    }

    // Créer le produit
    const productResult = await client.query(`
      INSERT INTO products (
        id, title, handle, description, status, thumbnail, images,
        weight, length, width, height, origin_country, material,
        seo_title, seo_description, metadata
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16)
      RETURNING *
    `, [
      productId, title, handle, description, status, thumbnail, JSON.stringify(images),
      weight, length, width, height, origin_country, material,
      seo_title, seo_description, JSON.stringify(metadata)
    ]);

    const product = productResult.rows[0];

    // Créer les variants
    const createdVariants = [];
    if (variants.length > 0) {
      for (const variant of variants) {
        const variantId = generateVariantId();
        const variantResult = await client.query(`
          INSERT INTO product_variants (
            id, product_id, title, sku, price, compare_at_price, cost_price,
            inventory_quantity, inventory_policy, option1, option2, option3, weight
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
          RETURNING *
        `, [
          variantId, productId, variant.title, variant.sku, variant.price,
          variant.compare_at_price, variant.cost_price, variant.inventory_quantity || 0,
          variant.inventory_policy || 'deny', variant.option1, variant.option2,
          variant.option3, variant.weight
        ]);
        createdVariants.push(variantResult.rows[0]);
      }
    } else {
      // Créer un variant par défaut
      const variantId = generateVariantId();
      const defaultVariant = await client.query(`
        INSERT INTO product_variants (
          id, product_id, title, sku, price, inventory_quantity
        ) VALUES ($1, $2, $3, $4, $5, $6)
        RETURNING *
      `, [
        variantId, productId, 'Default', `${productId}-DEFAULT`, 0, 0
      ]);
      createdVariants.push(defaultVariant.rows[0]);
    }

    await client.query('COMMIT');

    // Logger la création
    await logAdminAction(req.admin.id, 'create_product', 'product', productId, {
      title,
      variants: createdVariants.length
    }, req);

    res.status(201).json({
      success: true,
      product: {
        ...product,
        variants: createdVariants
      },
      message: `Produit "${title}" créé avec succès`
    });

  } catch (err) {
    await client.query('ROLLBACK');
    console.error('❌ Erreur création produit:', err);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la création du produit'
    });
  } finally {
    client.release();
  }
});

/*
// Modifier un produit existant - TEMPORAIREMENT DÉSACTIVÉ
app.put('/api/admin/products/:id', authenticateAdmin, async (req, res) => {
  // ... code commenté ...
});

// Supprimer un produit - TEMPORAIREMENT DÉSACTIVÉ  
app.delete('/api/admin/products/:id', authenticateAdmin, async (req, res) => {
  // ... code commenté ...
});
*/

// =====================================================
// UTILITAIRES COMMANDES
// =====================================================

// Fonction utilitaire pour générer un numéro de commande unique
function generateOrderNumber() {
  const date = new Date();
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  const timestamp = Date.now().toString().slice(-6);
  
  return `MKW${year}${month}${day}${timestamp}`;
}

// Fonction pour calculer les frais de livraison
function calculateShippingCost(shippingMethod, total, country = 'FR') {
  const freeShippingThreshold = 50;
  
  if (total >= freeShippingThreshold) {
    return 0;
  }
  
  switch (shippingMethod) {
    case 'standard': return country === 'FR' ? 5.99 : 9.99;
    case 'express': return country === 'FR' ? 12.99 : 19.99;
    case 'premium': return country === 'FR' ? 19.99 : 29.99;
    default: return 5.99;
  }
}

// =====================================================
// API COMMANDES
// =====================================================

// Créer une nouvelle commande (depuis le frontend)
app.post('/api/orders', async (req, res) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const {
      customer_email,
      customer_first_name,
      customer_last_name,
      customer_phone,
      billing_address,
      shipping_address,
      items,
      shipping_method = 'standard',
      payment_method = 'cod',
      customer_note = ''
    } = req.body;

    // Validation des données requises
    if (!customer_email || !billing_address || !shipping_address || !items || items.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Données de commande incomplètes'
      });
    }

    // Créer ou récupérer le client
    let customer;
    const existingCustomer = await client.query(
      'SELECT * FROM customers WHERE email = $1',
      [customer_email]
    );

    if (existingCustomer.rows.length > 0) {
      customer = existingCustomer.rows[0];
      await client.query(`
        UPDATE customers 
        SET first_name = $1, last_name = $2, phone = $3, updated_at = CURRENT_TIMESTAMP
        WHERE id = $4
      `, [customer_first_name, customer_last_name, customer_phone, customer.id]);
    } else {
      const newCustomer = await client.query(`
        INSERT INTO customers (email, first_name, last_name, phone, billing_address, shipping_address)
        VALUES ($1, $2, $3, $4, $5, $6)
        RETURNING *
      `, [
        customer_email, customer_first_name, customer_last_name, customer_phone,
        JSON.stringify(billing_address), JSON.stringify(shipping_address)
      ]);
      customer = newCustomer.rows[0];
    }

    // Vérifier disponibilité et calculer montants
    let subtotal = 0;
    const orderItems = [];

    for (const item of items) {
      const variant = await client.query(`
        SELECT pv.*, p.title as product_title
        FROM product_variants pv
        JOIN products p ON pv.product_id = p.id
        WHERE pv.id = $1
      `, [item.variant_id]);

      if (variant.rows.length === 0) {
        throw new Error(`Variant ${item.variant_id} non trouvé`);
      }

      const variantData = variant.rows[0];

      if (variantData.inventory_quantity < item.quantity && variantData.inventory_policy === 'deny') {
        throw new Error(`Stock insuffisant pour ${variantData.product_title} - ${variantData.title}`);
      }

      const lineTotal = variantData.price * item.quantity;
      subtotal += lineTotal;

      orderItems.push({
        product_id: variantData.product_id,
        variant_id: variantData.id,
        quantity: item.quantity,
        price: variantData.price,
        total: lineTotal,
        product_title: variantData.product_title,
        variant_title: variantData.title,
        sku: variantData.sku
      });
    }

    // Calculer taxes et frais
    const taxRate = 0.20;
    const totalTax = Math.round(subtotal * taxRate);
    const shippingCost = calculateShippingCost(shipping_method, subtotal);
    const total = subtotal + totalTax + shippingCost;

    // Générer le numéro de commande
    const orderNumber = generateOrderNumber();

    // Créer la commande
    const orderResult = await client.query(`
      INSERT INTO orders (
        order_number, customer_id, billing_address, shipping_address,
        subtotal, total_tax, shipping_cost, total,
        payment_method, payment_status, shipping_method,
        customer_note, source_name
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
      RETURNING *
    `, [
      orderNumber, customer.id,
      JSON.stringify(billing_address), JSON.stringify(shipping_address),
      subtotal, totalTax, shippingCost, total,
      payment_method, 'pending', shipping_method,
      customer_note, 'web'
    ]);

    const order = orderResult.rows[0];

    // Créer les lignes de commande
    for (const item of orderItems) {
      await client.query(`
        INSERT INTO order_items (
          order_id, product_id, variant_id, quantity, price, total,
          product_title, variant_title, sku
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      `, [
        order.id, item.product_id, item.variant_id, item.quantity,
        item.price, item.total, item.product_title, item.variant_title, item.sku
      ]);

      // Décrémenter le stock
      await client.query(`
        UPDATE product_variants 
        SET inventory_quantity = inventory_quantity - $1, updated_at = CURRENT_TIMESTAMP
        WHERE id = $2
      `, [item.quantity, item.variant_id]);
    }

    // Mettre à jour les statistiques client
    await client.query(`
      UPDATE customers 
      SET orders_count = orders_count + 1,
          total_spent = total_spent + $1,
          last_order_at = CURRENT_TIMESTAMP
      WHERE id = $2
    `, [total, customer.id]);

    await client.query('COMMIT');

    res.status(201).json({
      success: true,
      order: {
        id: order.id,
        order_number: orderNumber,
        total: total,
        currency: 'EUR',
        payment_method,
        payment_status: 'pending',
        customer: {
          email: customer_email,
          name: `${customer_first_name} ${customer_last_name}`
        }
      },
      message: `Commande ${orderNumber} créée avec succès`
    });

  } catch (err) {
    await client.query('ROLLBACK');
    console.error('❌ Erreur création commande:', err);
    res.status(500).json({
      success: false,
      error: err.message || 'Erreur lors de la création de la commande'
    });
  } finally {
    client.release();
  }
});

// =====================================================
// API COMMANDES ADMIN - GESTION COMPLÈTE
// =====================================================

// Lister toutes les commandes (admin)
app.get('/api/admin/orders', authenticateAdmin, async (req, res) => {
  try {
    const { 
      limit = 50, 
      offset = 0, 
      status, 
      payment_status,
      search,
      sort_by = 'created_at',
      sort_order = 'DESC'
    } = req.query;

    let whereClause = 'WHERE 1=1';
    const queryParams = [];
    let paramCount = 0;

    if (status) {
      paramCount++;
      whereClause += ` AND o.fulfillment_status = $${paramCount}`;
      queryParams.push(status);
    }

    if (payment_status) {
      paramCount++;
      whereClause += ` AND o.financial_status = $${paramCount}`;
      queryParams.push(payment_status);
    }

    if (search) {
      paramCount++;
      whereClause += ` AND (o.order_number ILIKE $${paramCount} OR c.email ILIKE $${paramCount} OR c.first_name ILIKE $${paramCount})`;
      queryParams.push(`%${search}%`);
    }

    paramCount++;
    queryParams.push(limit);
    paramCount++;
    queryParams.push(offset);

    const query = `
      SELECT 
        o.*,
        c.email as customer_email,
        c.first_name as customer_first_name,
        c.last_name as customer_last_name,
        (SELECT COUNT(*) FROM order_items WHERE order_id = o.id) as items_count
      FROM orders o
      LEFT JOIN customers c ON o.customer_id = c.id
      ${whereClause}
      ORDER BY o.${sort_by} ${sort_order}
      LIMIT $${paramCount-1} OFFSET $${paramCount}
    `;

    const result = await pool.query(query, queryParams);

    const countQuery = `
      SELECT COUNT(*) as total
      FROM orders o
      LEFT JOIN customers c ON o.customer_id = c.id
      ${whereClause}
    `;
    const countResult = await pool.query(countQuery, queryParams.slice(0, -2));

    await logAdminAction(req.admin.id, 'view_orders', 'orders', null, {
      filters: { status, payment_status, search },
      count: result.rows.length
    }, req);

    res.json({
      success: true,
      orders: result.rows,
      pagination: {
        total: parseInt(countResult.rows[0].total),
        limit: parseInt(limit),
        offset: parseInt(offset),
        has_more: (parseInt(offset) + parseInt(limit)) < parseInt(countResult.rows[0].total)
      }
    });

  } catch (err) {
    console.error('❌ Erreur récupération commandes:', err);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la récupération des commandes'
    });
  }
});

// Récupérer une commande par ID
app.get('/api/admin/orders/:id', authenticateAdmin, async (req, res) => {
  try {
    const { id } = req.params;

    const result = await pool.query(`
      SELECT 
        o.*,
        c.email as customer_email,
        c.first_name as customer_first_name,
        c.last_name as customer_last_name,
        c.phone as customer_phone,
        c.orders_count as customer_orders_count,
        c.total_spent as customer_total_spent,
        (SELECT JSON_AGG(
          JSON_BUILD_OBJECT(
            'id', oi.id,
            'product_id', oi.product_id,
            'variant_id', oi.variant_id,
            'product_title', oi.product_title,
            'variant_title', oi.variant_title,
            'sku', oi.sku,
            'quantity', oi.quantity,
            'price', oi.price,
            'total', oi.total
          )
        ) FROM order_items oi WHERE oi.order_id = o.id) as items
      FROM orders o
      LEFT JOIN customers c ON o.customer_id = c.id
      WHERE o.id = $1
    `, [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Commande non trouvée'
      });
    }

    await logAdminAction(req.admin.id, 'view_order', 'order', id, {
      order_number: result.rows[0].order_number
    }, req);

    res.json({
      success: true,
      order: result.rows[0]
    });

  } catch (err) {
    console.error('❌ Erreur récupération commande:', err);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la récupération de la commande'
    });
  }
});

// Mettre à jour le statut d'une commande
app.put('/api/admin/orders/:id/status', authenticateAdmin, async (req, res) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const { id } = req.params;
    const { 
      fulfillment_status, 
      financial_status, 
      tracking_number, 
      carrier,
      note 
    } = req.body;

    const existingOrder = await client.query(
      'SELECT * FROM orders WHERE id = $1',
      [id]
    );

    if (existingOrder.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Commande non trouvée'
      });
    }

    const order = existingOrder.rows[0];
    const updates = [];
    const values = [];
    let paramCount = 0;

    if (fulfillment_status) {
      paramCount++;
      updates.push(`fulfillment_status = $${paramCount}`);
      values.push(fulfillment_status);

      if (fulfillment_status === 'fulfilled' && !order.shipped_at) {
        paramCount++;
        updates.push(`shipped_at = $${paramCount}`);
        values.push(new Date());
      }
    }

    if (financial_status) {
      paramCount++;
      updates.push(`financial_status = $${paramCount}`);
      values.push(financial_status);

      if (financial_status === 'paid' && !order.processed_at) {
        paramCount++;
        updates.push(`processed_at = $${paramCount}`);
        values.push(new Date());
      }
    }

    if (tracking_number) {
      paramCount++;
      updates.push(`tracking_number = $${paramCount}`);
      values.push(tracking_number);
    }

    if (carrier) {
      paramCount++;
      updates.push(`carrier = $${paramCount}`);
      values.push(carrier);
    }

    if (note) {
      paramCount++;
      updates.push(`note = $${paramCount}`);
      values.push(note);
    }

    paramCount++;
    updates.push(`updated_at = $${paramCount}`);
    values.push(new Date());

    paramCount++;
    values.push(id);

    const updateQuery = `
      UPDATE orders 
      SET ${updates.join(', ')}
      WHERE id = $${paramCount}
      RETURNING *
    `;

    const result = await client.query(updateQuery, values);

    await client.query('COMMIT');

    await logAdminAction(req.admin.id, 'update_order_status', 'order', id, {
      old_fulfillment_status: order.fulfillment_status,
      new_fulfillment_status: fulfillment_status,
      old_financial_status: order.financial_status,
      new_financial_status: financial_status,
      tracking_number,
      carrier
    }, req);

    res.json({
      success: true,
      order: result.rows[0],
      message: 'Statut de la commande mis à jour avec succès'
    });

  } catch (err) {
    await client.query('ROLLBACK');
    console.error('❌ Erreur mise à jour statut commande:', err);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la mise à jour du statut'
    });
  } finally {
    client.release();
  }
});

// =====================================================
// API CLIENTS ADMIN - GESTION COMPLÈTE
// =====================================================

// Lister tous les clients (admin)
app.get('/api/admin/customers', authenticateAdmin, async (req, res) => {
  try {
    const { 
      limit = 50, 
      offset = 0, 
      search,
      sort_by = 'created_at',
      sort_order = 'DESC',
      min_orders = 0,
      min_spent = 0
    } = req.query;

    let whereClause = 'WHERE 1=1';
    const queryParams = [];
    let paramCount = 0;

    if (search) {
      paramCount++;
      whereClause += ` AND (c.email ILIKE $${paramCount} OR c.first_name ILIKE $${paramCount} OR c.last_name ILIKE $${paramCount} OR c.phone ILIKE $${paramCount})`;
      queryParams.push(`%${search}%`);
    }

    if (min_orders > 0) {
      paramCount++;
      whereClause += ` AND c.orders_count >= $${paramCount}`;
      queryParams.push(min_orders);
    }

    if (min_spent > 0) {
      paramCount++;
      whereClause += ` AND c.total_spent >= $${paramCount}`;
      queryParams.push(min_spent);
    }

    paramCount++;
    queryParams.push(limit);
    paramCount++;
    queryParams.push(offset);

    const validSortFields = ['created_at', 'email', 'first_name', 'last_name', 'orders_count', 'total_spent', 'last_order_at'];
    const sortField = validSortFields.includes(sort_by) ? sort_by : 'created_at';
    const sortDirection = sort_order.toLowerCase() === 'asc' ? 'ASC' : 'DESC';

    const query = `
      SELECT 
        c.*,
        (SELECT MAX(created_at) FROM orders WHERE customer_id = c.id) as last_order_date,
        (SELECT JSON_AGG(
          JSON_BUILD_OBJECT(
            'id', o.id,
            'order_number', o.order_number,
            'total', o.total,
            'created_at', o.created_at,
            'fulfillment_status', o.fulfillment_status,
            'financial_status', o.financial_status
          ) ORDER BY o.created_at DESC
        ) FROM orders o WHERE o.customer_id = c.id LIMIT 5) as recent_orders
      FROM customers c
      ${whereClause}
      ORDER BY c.${sortField} ${sortDirection}
      LIMIT $${paramCount-1} OFFSET $${paramCount}
    `;

    const result = await pool.query(query, queryParams);

    const countQuery = `
      SELECT COUNT(*) as total
      FROM customers c
      ${whereClause}
    `;
    const countResult = await pool.query(countQuery, queryParams.slice(0, -2));

    await logAdminAction(req.admin.id, 'view_customers', 'customers', null, {
      filters: { search, min_orders, min_spent },
      count: result.rows.length
    }, req);

    res.json({
      success: true,
      customers: result.rows,
      pagination: {
        total: parseInt(countResult.rows[0].total),
        limit: parseInt(limit),
        offset: parseInt(offset),
        has_more: (parseInt(offset) + parseInt(limit)) < parseInt(countResult.rows[0].total)
      }
    });

  } catch (err) {
    console.error('❌ Erreur récupération clients:', err);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la récupération des clients'
    });
  }
});

// Récupérer un client par ID avec historique complet
app.get('/api/admin/customers/:id', authenticateAdmin, async (req, res) => {
  try {
    const { id } = req.params;

    const result = await pool.query(`
      SELECT 
        c.*,
        (SELECT COUNT(*) FROM orders WHERE customer_id = c.id) as total_orders,
        (SELECT COALESCE(SUM(total), 0) FROM orders WHERE customer_id = c.id) as lifetime_value,
        (SELECT AVG(total) FROM orders WHERE customer_id = c.id) as average_order_value,
        (SELECT JSON_AGG(
          JSON_BUILD_OBJECT(
            'id', o.id,
            'order_number', o.order_number,
            'total', o.total,
            'subtotal', o.subtotal,
            'tax', o.total_tax,
            'shipping', o.shipping_cost,
            'created_at', o.created_at,
            'fulfillment_status', o.fulfillment_status,
            'financial_status', o.financial_status,
            'payment_method', o.payment_method,
            'items_count', (SELECT COUNT(*) FROM order_items WHERE order_id = o.id)
          ) ORDER BY o.created_at DESC
        ) FROM orders o WHERE o.customer_id = c.id) as order_history
      FROM customers c
      WHERE c.id = $1
    `, [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Client non trouvé'
      });
    }

    const customer = result.rows[0];

    // Récupérer les produits les plus achetés
    const topProducts = await pool.query(`
      SELECT 
        oi.product_title,
        oi.variant_title,
        SUM(oi.quantity) as total_quantity,
        SUM(oi.total) as total_spent,
        COUNT(DISTINCT oi.order_id) as times_ordered
      FROM order_items oi
      JOIN orders o ON oi.order_id = o.id
      WHERE o.customer_id = $1
      GROUP BY oi.product_title, oi.variant_title
      ORDER BY total_quantity DESC
      LIMIT 10
    `, [id]);

    customer.top_products = topProducts.rows;

    await logAdminAction(req.admin.id, 'view_customer', 'customer', id, {
      customer_email: customer.email,
      orders_count: customer.orders_count
    }, req);

    res.json({
      success: true,
      customer: customer
    });

  } catch (err) {
    console.error('❌ Erreur récupération client:', err);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la récupération du client'
    });
  }
});

// Statistiques des clients (admin)
app.get('/api/admin/customers/stats', authenticateAdmin, async (req, res) => {
  try {
    const stats = await pool.query(`
      SELECT 
        COUNT(*) as total_customers,
        COUNT(CASE WHEN orders_count > 0 THEN 1 END) as customers_with_orders,
        COUNT(CASE WHEN orders_count = 0 THEN 1 END) as customers_without_orders,
        COALESCE(AVG(CASE WHEN orders_count > 0 THEN total_spent END), 0) as avg_customer_value,
        COALESCE(MAX(total_spent), 0) as highest_customer_value,
        COUNT(CASE WHEN created_at >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as new_customers_last_30_days,
        COUNT(CASE WHEN last_order_at >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as active_customers_last_30_days
      FROM customers
    `);

    // Top 10 des meilleurs clients
    const topCustomers = await pool.query(`
      SELECT 
        id, email, first_name, last_name, 
        orders_count, total_spent, last_order_at
      FROM customers 
      WHERE orders_count > 0
      ORDER BY total_spent DESC 
      LIMIT 10
    `);

    await logAdminAction(req.admin.id, 'view_customer_stats', 'customers', null, {
      total_customers: stats.rows[0].total_customers
    }, req);

    res.json({
      success: true,
      stats: stats.rows[0],
      top_customers: topCustomers.rows
    });

  } catch (err) {
    console.error('❌ Erreur statistiques clients:', err);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la récupération des statistiques'
    });
  }
});

// =====================================================
// API INVENTAIRE ADMIN - GESTION COMPLÈTE
// =====================================================

// Tableau de bord inventaire avec alertes
app.get('/api/admin/inventory/dashboard', authenticateAdmin, async (req, res) => {
  try {
    // Statistiques générales du stock
    const stockStats = await pool.query(`
      SELECT 
        COUNT(DISTINCT pv.id) as total_variants,
        SUM(pv.inventory_quantity) as total_units_in_stock,
        COUNT(CASE WHEN pv.inventory_quantity <= 5 THEN 1 END) as low_stock_variants,
        COUNT(CASE WHEN pv.inventory_quantity = 0 THEN 1 END) as out_of_stock_variants,
        COALESCE(AVG(pv.inventory_quantity), 0) as avg_stock_per_variant,
        SUM(pv.inventory_quantity * pv.price) as total_inventory_value
      FROM product_variants pv
      WHERE pv.inventory_tracked = true
    `);

    // Alertes de stock faible
    const lowStockAlerts = await pool.query(`
      SELECT 
        pv.id,
        pv.title as variant_title,
        pv.sku,
        pv.inventory_quantity,
        pv.price,
        p.title as product_title,
        p.handle as product_handle
      FROM product_variants pv
      JOIN products p ON pv.product_id = p.id
      WHERE pv.inventory_tracked = true 
        AND pv.inventory_quantity <= 5
        AND pv.inventory_quantity > 0
      ORDER BY pv.inventory_quantity ASC
      LIMIT 20
    `);

    // Produits en rupture de stock
    const outOfStockProducts = await pool.query(`
      SELECT 
        pv.id,
        pv.title as variant_title,
        pv.sku,
        pv.price,
        p.title as product_title,
        p.handle as product_handle,
        (SELECT MAX(created_at) FROM inventory_movements 
         WHERE variant_id = pv.id AND quantity_change < 0) as last_sale_date
      FROM product_variants pv
      JOIN products p ON pv.product_id = p.id
      WHERE pv.inventory_tracked = true 
        AND pv.inventory_quantity = 0
      ORDER BY p.title ASC
      LIMIT 20
    `);

    await logAdminAction(req.admin.id, 'view_inventory_dashboard', 'inventory', null, {
      total_variants: stockStats.rows[0].total_variants,
      low_stock_count: stockStats.rows[0].low_stock_variants
    }, req);

    res.json({
      success: true,
      stats: stockStats.rows[0],
      alerts: {
        low_stock: lowStockAlerts.rows,
        out_of_stock: outOfStockProducts.rows
      }
    });

  } catch (err) {
    console.error('❌ Erreur dashboard inventaire:', err);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la récupération du dashboard inventaire'
    });
  }
});

// Ajuster le stock d'un variant (admin)
app.post('/api/admin/inventory/adjust', authenticateAdmin, async (req, res) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const {
      variant_id,
      quantity_change,
      reason = 'adjustment',
      note = '',
      new_quantity
    } = req.body;

    if (!variant_id) {
      return res.status(400).json({
        success: false,
        error: 'variant_id est requis'
      });
    }

    // Récupérer le variant actuel
    const variantResult = await client.query(
      'SELECT * FROM product_variants WHERE id = $1',
      [variant_id]
    );

    if (variantResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Variant non trouvé'
      });
    }

    const variant = variantResult.rows[0];
    let actualQuantityChange = quantity_change;

    // Si new_quantity est défini, calculer le changement
    if (new_quantity !== undefined) {
      actualQuantityChange = new_quantity - variant.inventory_quantity;
    }

    if (actualQuantityChange === 0) {
      return res.status(400).json({
        success: false,
        error: 'Aucun changement de stock nécessaire'
      });
    }

    const newQuantity = variant.inventory_quantity + actualQuantityChange;

    if (newQuantity < 0) {
      return res.status(400).json({
        success: false,
        error: 'La quantité ne peut pas être négative'
      });
    }

    // Mettre à jour le stock
    await client.query(`
      UPDATE product_variants 
      SET inventory_quantity = $1, updated_at = CURRENT_TIMESTAMP
      WHERE id = $2
    `, [newQuantity, variant_id]);

    // Enregistrer le mouvement
    await client.query(`
      INSERT INTO inventory_movements (
        variant_id, quantity_change, quantity_before, quantity_after,
        reason, reference_type, reference_id, note, admin_id
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
    `, [
      variant_id, actualQuantityChange, variant.inventory_quantity, newQuantity,
      reason, 'manual_adjustment', null, note, req.admin.id
    ]);

    await client.query('COMMIT');

    await logAdminAction(req.admin.id, 'adjust_inventory', 'inventory', variant_id, {
      old_quantity: variant.inventory_quantity,
      new_quantity: newQuantity,
      change: actualQuantityChange,
      reason,
      note
    }, req);

    res.json({
      success: true,
      message: 'Stock ajusté avec succès',
      adjustment: {
        variant_id,
        old_quantity: variant.inventory_quantity,
        new_quantity: newQuantity,
        change: actualQuantityChange,
        reason,
        note
      }
    });

  } catch (err) {
    await client.query('ROLLBACK');
    console.error('❌ Erreur ajustement stock:', err);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de l\'ajustement du stock'
    });
  } finally {
    client.release();
  }
});

// Rapport d'inventaire avec valeurs
app.get('/api/admin/inventory/report', authenticateAdmin, async (req, res) => {
  try {
    const { 
      format = 'summary',
      include_zero_stock = false,
      product_id
    } = req.query;

    let whereClause = 'WHERE pv.inventory_tracked = true';
    const queryParams = [];
    let paramCount = 0;

    if (!include_zero_stock) {
      whereClause += ' AND pv.inventory_quantity > 0';
    }

    if (product_id) {
      paramCount++;
      whereClause += ` AND p.id = $${paramCount}`;
      queryParams.push(product_id);
    }

    let query;
    if (format === 'detailed') {
      query = `
        SELECT 
          p.id as product_id,
          p.title as product_title,
          pv.id as variant_id,
          pv.title as variant_title,
          pv.sku,
          pv.price,
          pv.inventory_quantity,
          (pv.inventory_quantity * pv.price) as inventory_value,
          (SELECT COALESCE(SUM(oi.quantity), 0) FROM order_items oi 
           JOIN orders o ON oi.order_id = o.id 
           WHERE oi.variant_id = pv.id 
           AND o.created_at >= CURRENT_DATE - INTERVAL '30 days') as units_sold_last_30_days
        FROM product_variants pv
        JOIN products p ON pv.product_id = p.id
        ${whereClause}
        ORDER BY p.title ASC, pv.title ASC
      `;
    } else {
      query = `
        SELECT 
          p.id as product_id,
          p.title as product_title,
          COUNT(pv.id) as total_variants,
          SUM(pv.inventory_quantity) as total_quantity,
          SUM(pv.inventory_quantity * pv.price) as total_value
        FROM product_variants pv
        JOIN products p ON pv.product_id = p.id
        ${whereClause}
        GROUP BY p.id, p.title
        ORDER BY total_value DESC
      `;
    }

    const result = await pool.query(query, queryParams);

    await logAdminAction(req.admin.id, 'generate_inventory_report', 'inventory', null, {
      format,
      include_zero_stock,
      product_id,
      items_count: result.rows.length
    }, req);

    res.json({
      success: true,
      report: {
        format,
        generated_at: new Date(),
        items: result.rows
      }
    });

  } catch (err) {
    console.error('❌ Erreur rapport inventaire:', err);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la génération du rapport'
    });
  }
});

// =====================================================
// DASHBOARD ADMIN - ANALYTICS ET KPIs
// =====================================================

// Dashboard principal avec toutes les métriques
app.get('/api/admin/dashboard', authenticateAdmin, async (req, res) => {
  try {
    const { period = '30d' } = req.query;
    
    // Définir les périodes
    let dateFilter;
    switch (period) {
      case '7d':
        dateFilter = "created_at >= CURRENT_DATE - INTERVAL '7 days'";
        break;
      case '30d':
        dateFilter = "created_at >= CURRENT_DATE - INTERVAL '30 days'";
        break;
      case '90d':
        dateFilter = "created_at >= CURRENT_DATE - INTERVAL '90 days'";
        break;
      case '1y':
        dateFilter = "created_at >= CURRENT_DATE - INTERVAL '1 year'";
        break;
      default:
        dateFilter = "created_at >= CURRENT_DATE - INTERVAL '30 days'";
    }

    // KPIs des ventes
    const salesKPIs = await pool.query(`
      SELECT 
        COUNT(*) as total_orders,
        COALESCE(SUM(total), 0) as total_revenue,
        COALESCE(AVG(total), 0) as average_order_value,
        COUNT(CASE WHEN fulfillment_status = 'fulfilled' THEN 1 END) as fulfilled_orders,
        COUNT(CASE WHEN financial_status = 'paid' THEN 1 END) as paid_orders,
        COUNT(CASE WHEN financial_status = 'pending' THEN 1 END) as pending_orders
      FROM orders 
      WHERE ${dateFilter}
    `);

    // KPIs produits
    const productKPIs = await pool.query(`
      SELECT 
        COUNT(DISTINCT p.id) as total_products,
        COUNT(DISTINCT pv.id) as total_variants,
        SUM(pv.inventory_quantity) as total_stock_units,
        COUNT(CASE WHEN pv.inventory_quantity <= 5 THEN 1 END) as low_stock_variants,
        COUNT(CASE WHEN pv.inventory_quantity = 0 THEN 1 END) as out_of_stock_variants
      FROM products p
      LEFT JOIN product_variants pv ON p.id = pv.product_id
    `);

    // KPIs clients
    const customerKPIs = await pool.query(`
      SELECT 
        COUNT(*) as total_customers,
        COUNT(CASE WHEN orders_count > 0 THEN 1 END) as customers_with_orders,
        COALESCE(AVG(total_spent), 0) as avg_customer_value,
        COUNT(CASE WHEN ${dateFilter.replace('created_at', 'c.created_at')} THEN 1 END) as new_customers
      FROM customers c
    `);

    // Top produits vendus dans la période
    const topProducts = await pool.query(`
      SELECT 
        oi.product_title,
        oi.variant_title,
        SUM(oi.quantity) as units_sold,
        SUM(oi.total) as revenue,
        COUNT(DISTINCT oi.order_id) as orders_count
      FROM order_items oi
      JOIN orders o ON oi.order_id = o.id
      WHERE o.${dateFilter}
      GROUP BY oi.product_title, oi.variant_title
      ORDER BY units_sold DESC
      LIMIT 10
    `);

    // Commandes récentes
    const recentOrders = await pool.query(`
      SELECT 
        o.id,
        o.order_number,
        o.total,
        o.fulfillment_status,
        o.financial_status,
        o.created_at,
        c.first_name,
        c.last_name,
        c.email
      FROM orders o
      LEFT JOIN customers c ON o.customer_id = c.id
      ORDER BY o.created_at DESC
      LIMIT 10
    `);

    // Evolution des ventes par jour (derniers 30 jours)
    const salesTrend = await pool.query(`
      SELECT 
        DATE(created_at) as date,
        COUNT(*) as orders_count,
        COALESCE(SUM(total), 0) as daily_revenue
      FROM orders
      WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
      GROUP BY DATE(created_at)
      ORDER BY date ASC
    `);

    // Répartition des commandes par statut
    const ordersByStatus = await pool.query(`
      SELECT 
        fulfillment_status,
        COUNT(*) as count,
        SUM(total) as total_value
      FROM orders
      WHERE ${dateFilter}
      GROUP BY fulfillment_status
    `);

    // Méthodes de paiement
    const paymentMethods = await pool.query(`
      SELECT 
        payment_method,
        COUNT(*) as count,
        SUM(total) as total_value
      FROM orders
      WHERE ${dateFilter}
      GROUP BY payment_method
    `);

    await logAdminAction(req.admin.id, 'view_dashboard', 'dashboard', null, {
      period,
      total_orders: salesKPIs.rows[0].total_orders,
      total_revenue: salesKPIs.rows[0].total_revenue
    }, req);

    res.json({
      success: true,
      dashboard: {
        period,
        generated_at: new Date(),
        kpis: {
          sales: salesKPIs.rows[0],
          products: productKPIs.rows[0],
          customers: customerKPIs.rows[0]
        },
        charts: {
          sales_trend: salesTrend.rows,
          orders_by_status: ordersByStatus.rows,
          payment_methods: paymentMethods.rows
        },
        lists: {
          top_products: topProducts.rows,
          recent_orders: recentOrders.rows
        }
      }
    });

  } catch (err) {
    console.error('❌ Erreur dashboard:', err);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la récupération du dashboard'
    });
  }
});

// Statistiques avancées pour les graphiques
app.get('/api/admin/analytics/sales', authenticateAdmin, async (req, res) => {
  try {
    const { 
      period = '30d', 
      granularity = 'day' // 'day', 'week', 'month'
    } = req.query;

    let dateFilter, groupByClause, dateFormat;
    
    switch (period) {
      case '7d':
        dateFilter = "created_at >= CURRENT_DATE - INTERVAL '7 days'";
        break;
      case '30d':
        dateFilter = "created_at >= CURRENT_DATE - INTERVAL '30 days'";
        break;
      case '90d':
        dateFilter = "created_at >= CURRENT_DATE - INTERVAL '90 days'";
        break;
      case '1y':
        dateFilter = "created_at >= CURRENT_DATE - INTERVAL '1 year'";
        break;
      default:
        dateFilter = "created_at >= CURRENT_DATE - INTERVAL '30 days'";
    }

    switch (granularity) {
      case 'week':
        groupByClause = "DATE_TRUNC('week', created_at)";
        dateFormat = "YYYY-'W'IW";
        break;
      case 'month':
        groupByClause = "DATE_TRUNC('month', created_at)";
        dateFormat = "YYYY-MM";
        break;
      default:
        groupByClause = "DATE(created_at)";
        dateFormat = "YYYY-MM-DD";
    }

    const salesData = await pool.query(`
      SELECT 
        ${groupByClause} as period,
        COUNT(*) as orders_count,
        COALESCE(SUM(total), 0) as revenue,
        COALESCE(AVG(total), 0) as avg_order_value,
        COUNT(DISTINCT customer_id) as unique_customers
      FROM orders
      WHERE ${dateFilter}
      GROUP BY ${groupByClause}
      ORDER BY period ASC
    `);

    // Comparaison avec la période précédente
    const comparisonData = await pool.query(`
      SELECT 
        COUNT(*) as prev_orders,
        COALESCE(SUM(total), 0) as prev_revenue
      FROM orders
      WHERE created_at >= CURRENT_DATE - INTERVAL '${period === '7d' ? '14' : period === '30d' ? '60' : '180'} days'
        AND created_at < CURRENT_DATE - INTERVAL '${period.replace('d', '')} days'
    `);

    res.json({
      success: true,
      analytics: {
        period,
        granularity,
        data: salesData.rows,
        comparison: comparisonData.rows[0]
      }
    });

  } catch (err) {
    console.error('❌ Erreur analytics ventes:', err);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la récupération des analytics'
    });
  }
});

// Rapport détaillé exportable
app.get('/api/admin/reports/sales', authenticateAdmin, async (req, res) => {
  try {
    const { 
      start_date, 
      end_date, 
      format = 'json' // 'json', 'csv'
    } = req.query;

    if (!start_date || !end_date) {
      return res.status(400).json({
        success: false,
        error: 'start_date et end_date sont requis'
      });
    }

    const salesReport = await pool.query(`
      SELECT 
        o.id,
        o.order_number,
        o.created_at,
        o.subtotal,
        o.total_tax,
        o.shipping_cost,
        o.total,
        o.fulfillment_status,
        o.financial_status,
        o.payment_method,
        c.email as customer_email,
        c.first_name as customer_first_name,
        c.last_name as customer_last_name,
        (SELECT COUNT(*) FROM order_items WHERE order_id = o.id) as items_count,
        (SELECT JSON_AGG(
          JSON_BUILD_OBJECT(
            'product', oi.product_title,
            'variant', oi.variant_title,
            'quantity', oi.quantity,
            'price', oi.price,
            'total', oi.total
          )
        ) FROM order_items oi WHERE oi.order_id = o.id) as items
      FROM orders o
      LEFT JOIN customers c ON o.customer_id = c.id
      WHERE o.created_at >= $1 AND o.created_at <= $2
      ORDER BY o.created_at DESC
    `, [start_date, end_date]);

    // Résumé du rapport
    const summary = await pool.query(`
      SELECT 
        COUNT(*) as total_orders,
        SUM(total) as total_revenue,
        AVG(total) as avg_order_value,
        SUM(subtotal) as total_subtotal,
        SUM(total_tax) as total_tax,
        SUM(shipping_cost) as total_shipping
      FROM orders
      WHERE created_at >= $1 AND created_at <= $2
    `, [start_date, end_date]);

    await logAdminAction(req.admin.id, 'export_sales_report', 'reports', null, {
      start_date,
      end_date,
      format,
      orders_count: salesReport.rows.length
    }, req);

    if (format === 'csv') {
      // Générer CSV
      const csv = salesReport.rows.map(order => [
        order.order_number,
        order.created_at,
        order.customer_email,
        `${order.customer_first_name} ${order.customer_last_name}`,
        order.subtotal,
        order.total_tax,
        order.shipping_cost,
        order.total,
        order.fulfillment_status,
        order.financial_status,
        order.payment_method
      ].join(',')).join('\n');

      const headers = [
        'Numéro commande',
        'Date',
        'Email client',
        'Nom client',
        'Sous-total',
        'Taxes',
        'Livraison',
        'Total',
        'Statut livraison',
        'Statut paiement',
        'Méthode paiement'
      ].join(',');

      res.setHeader('Content-Type', 'text/csv');
      res.setHeader('Content-Disposition', 'attachment; filename="rapport-ventes.csv"');
      res.send(headers + '\n' + csv);
    } else {
      res.json({
        success: true,
        report: {
          period: { start_date, end_date },
          generated_at: new Date(),
          summary: summary.rows[0],
          orders: salesReport.rows
        }
      });
    }

  } catch (err) {
    console.error('❌ Erreur rapport ventes:', err);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la génération du rapport'
    });
  }
});

// =====================================================
// SYSTÈME D'AUDIT ET DE LOGS ADMIN
// =====================================================

// Consulter les logs d'activité admin
app.get('/api/admin/logs', authenticateAdmin, async (req, res) => {
  try {
    const { 
      limit = 100, 
      offset = 0, 
      action,
      admin_id,
      resource_type,
      date_from,
      date_to,
      ip_address
    } = req.query;

    let whereClause = 'WHERE 1=1';
    const queryParams = [];
    let paramCount = 0;

    if (action) {
      paramCount++;
      whereClause += ` AND al.action = $${paramCount}`;
      queryParams.push(action);
    }

    if (admin_id) {
      paramCount++;
      whereClause += ` AND al.admin_id = $${paramCount}`;
      queryParams.push(admin_id);
    }

    if (resource_type) {
      paramCount++;
      whereClause += ` AND al.resource_type = $${paramCount}`;
      queryParams.push(resource_type);
    }

    if (date_from) {
      paramCount++;
      whereClause += ` AND al.created_at >= $${paramCount}`;
      queryParams.push(date_from);
    }

    if (date_to) {
      paramCount++;
      whereClause += ` AND al.created_at <= $${paramCount}`;
      queryParams.push(date_to);
    }

    if (ip_address) {
      paramCount++;
      whereClause += ` AND al.ip_address = $${paramCount}`;
      queryParams.push(ip_address);
    }

    paramCount++;
    queryParams.push(limit);
    paramCount++;
    queryParams.push(offset);

    const query = `
      SELECT 
        al.*,
        au.username as admin_username,
        au.email as admin_email
      FROM admin_logs al
      LEFT JOIN admin_users au ON al.admin_id = au.id
      ${whereClause}
      ORDER BY al.created_at DESC
      LIMIT $${paramCount-1} OFFSET $${paramCount}
    `;

    const result = await pool.query(query, queryParams);

    // Compter le total
    const countQuery = `
      SELECT COUNT(*) as total
      FROM admin_logs al
      ${whereClause}
    `;
    const countResult = await pool.query(countQuery, queryParams.slice(0, -2));

    // Statistiques des logs
    const logStats = await pool.query(`
      SELECT 
        COUNT(*) as total_logs,
        COUNT(DISTINCT admin_id) as unique_admins,
        COUNT(CASE WHEN created_at >= CURRENT_DATE THEN 1 END) as logs_today,
        COUNT(CASE WHEN created_at >= CURRENT_DATE - INTERVAL '7 days' THEN 1 END) as logs_last_7_days
      FROM admin_logs
    `);

    // Actions les plus fréquentes
    const topActions = await pool.query(`
      SELECT 
        action,
        COUNT(*) as count,
        COUNT(DISTINCT admin_id) as unique_admins
      FROM admin_logs
      WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
      GROUP BY action
      ORDER BY count DESC
      LIMIT 10
    `);

    res.json({
      success: true,
      logs: result.rows,
      pagination: {
        total: parseInt(countResult.rows[0].total),
        limit: parseInt(limit),
        offset: parseInt(offset),
        has_more: (parseInt(offset) + parseInt(limit)) < parseInt(countResult.rows[0].total)
      },
      stats: {
        general: logStats.rows[0],
        top_actions: topActions.rows
      }
    });

  } catch (err) {
    console.error('❌ Erreur récupération logs:', err);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la récupération des logs'
    });
  }
});

// Statistiques de sécurité et surveillance
app.get('/api/admin/security/stats', authenticateAdmin, async (req, res) => {
  try {
    // Tentatives de connexion récentes
    const loginAttempts = await pool.query(`
      SELECT 
        COUNT(*) as total_attempts,
        COUNT(CASE WHEN action = 'login_success' THEN 1 END) as successful_logins,
        COUNT(CASE WHEN action = 'login_failed' THEN 1 END) as failed_logins,
        COUNT(DISTINCT ip_address) as unique_ips,
        COUNT(CASE WHEN created_at >= CURRENT_DATE THEN 1 END) as attempts_today
      FROM admin_logs
      WHERE action IN ('login_success', 'login_failed')
        AND created_at >= CURRENT_DATE - INTERVAL '7 days'
    `);

    // IPs suspectes (plusieurs échecs)
    const suspiciousIPs = await pool.query(`
      SELECT 
        ip_address,
        COUNT(*) as failed_attempts,
        MAX(created_at) as last_attempt,
        COUNT(DISTINCT admin_id) as targeted_accounts
      FROM admin_logs
      WHERE action = 'login_failed'
        AND created_at >= CURRENT_DATE - INTERVAL '24 hours'
      GROUP BY ip_address
      HAVING COUNT(*) >= 3
      ORDER BY failed_attempts DESC
    `);

    // Sessions actives
    const activeSessions = await pool.query(`
      SELECT 
        COUNT(*) as active_sessions,
        COUNT(CASE WHEN created_at >= CURRENT_TIMESTAMP - INTERVAL '1 hour' THEN 1 END) as recent_sessions
      FROM admin_sessions
      WHERE expires_at > CURRENT_TIMESTAMP
    `);

    // Actions sensibles récentes
    const sensitiveActions = await pool.query(`
      SELECT 
        action,
        COUNT(*) as count,
        MAX(created_at) as last_occurrence
      FROM admin_logs
      WHERE action IN ('delete_product', 'delete_customer', 'cancel_order', 'adjust_inventory')
        AND created_at >= CURRENT_DATE - INTERVAL '7 days'
      GROUP BY action
      ORDER BY count DESC
    `);

    await logAdminAction(req.admin.id, 'view_security_stats', 'security', null, {}, req);

    res.json({
      success: true,
      security_stats: {
        login_attempts: loginAttempts.rows[0],
        suspicious_ips: suspiciousIPs.rows,
        active_sessions: activeSessions.rows[0],
        sensitive_actions: sensitiveActions.rows,
        generated_at: new Date()
      }
    });

  } catch (err) {
    console.error('❌ Erreur stats sécurité:', err);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la récupération des statistiques de sécurité'
    });
  }
});

// Exporter les logs d'audit
app.get('/api/admin/logs/export', authenticateAdmin, async (req, res) => {
  try {
    const { 
      format = 'json',
      date_from,
      date_to,
      action,
      admin_id
    } = req.query;

    if (!date_from || !date_to) {
      return res.status(400).json({
        success: false,
        error: 'date_from et date_to sont requis pour l\'export'
      });
    }

    let whereClause = 'WHERE al.created_at >= $1 AND al.created_at <= $2';
    const queryParams = [date_from, date_to];
    let paramCount = 2;

    if (action) {
      paramCount++;
      whereClause += ` AND al.action = $${paramCount}`;
      queryParams.push(action);
    }

    if (admin_id) {
      paramCount++;
      whereClause += ` AND al.admin_id = $${paramCount}`;
      queryParams.push(admin_id);
    }

    const exportQuery = `
      SELECT 
        al.id,
        al.created_at,
        al.action,
        al.resource_type,
        al.resource_id,
        al.ip_address,
        al.user_agent,
        al.details,
        au.username as admin_username,
        au.email as admin_email
      FROM admin_logs al
      LEFT JOIN admin_users au ON al.admin_id = au.id
      ${whereClause}
      ORDER BY al.created_at DESC
    `;

    const result = await pool.query(exportQuery, queryParams);

    await logAdminAction(req.admin.id, 'export_audit_logs', 'logs', null, {
      date_from,
      date_to,
      format,
      records_count: result.rows.length
    }, req);

    if (format === 'csv') {
      const csv = result.rows.map(log => [
        log.id,
        log.created_at,
        log.action,
        log.resource_type,
        log.resource_id || '',
        log.admin_username || '',
        log.admin_email || '',
        log.ip_address || '',
        (log.user_agent || '').replace(/,/g, ';'),
        JSON.stringify(log.details || {}).replace(/,/g, ';')
      ].join(',')).join('\n');

      const headers = [
        'ID',
        'Date',
        'Action',
        'Type ressource',
        'ID ressource',
        'Admin username',
        'Admin email',
        'IP',
        'User Agent',
        'Détails'
      ].join(',');

      res.setHeader('Content-Type', 'text/csv');
      res.setHeader('Content-Disposition', `attachment; filename="audit-logs-${date_from}-${date_to}.csv"`);
      res.send(headers + '\n' + csv);
    } else {
      res.json({
        success: true,
        export: {
          period: { date_from, date_to },
          filters: { action, admin_id },
          generated_at: new Date(),
          records_count: result.rows.length,
          data: result.rows
        }
      });
    }

  } catch (err) {
    console.error('❌ Erreur export logs:', err);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de l\'export des logs'
    });
  }
});

// Nettoyer les anciennes sessions expirées
app.post('/api/admin/maintenance/cleanup-sessions', authenticateAdmin, async (req, res) => {
  try {
    const result = await pool.query(`
      DELETE FROM admin_sessions 
      WHERE expires_at < CURRENT_TIMESTAMP
      RETURNING COUNT(*) as deleted_count
    `);

    await logAdminAction(req.admin.id, 'cleanup_expired_sessions', 'maintenance', null, {
      deleted_sessions: result.rowCount
    }, req);

    res.json({
      success: true,
      message: `${result.rowCount} sessions expirées supprimées`,
      deleted_count: result.rowCount
    });

  } catch (err) {
    console.error('❌ Erreur nettoyage sessions:', err);
    res.status(500).json({
      success: false,
      error: 'Erreur lors du nettoyage des sessions'
    });
  }
});

// =====================================================
// DÉMARRAGE DU SERVEUR
// =====================================================

app.listen(PORT, () => {
  console.log(`🚀 Backend Meknow v2 démarré sur port ${PORT}`);
  console.log(`📱 Admin: http://localhost:${PORT}/admin`);
  console.log(`📦 API: http://localhost:${PORT}/api/*`);
  console.log(`🔐 Authentification: JWT activée`);
  console.log(`📊 Base de données: PostgreSQL`);
});

module.exports = app;