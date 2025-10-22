const express = require('express');
const cors = require('cors');
const path = require('path');

const app = express();
const PORT = 9000;

// Middleware
app.use(cors({
  origin: [
    'http://localhost:5000', 
    'http://localhost:3000',
    'http://localhost:8080',
    'http://localhost:3001',
    'http://localhost:3002',
    'http://meknow.fr',
    'https://meknow.fr',
    'http://www.meknow.fr',
    'https://www.meknow.fr',
    'http://127.0.0.1:8080',
    'http://127.0.0.1:3000',
    'http://31.97.196.215'
  ],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept', 'Origin', 'X-Requested-With']
}));
app.use(express.json());

// 🚀 FONCTION DE REVALIDATION AUTOMATIQUE
async function triggerFrontendRevalidation() {
  try {
    const fetch = (await import('node-fetch')).default;
    const response = await fetch('http://localhost:3000/api/revalidate', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' }
    });
    
    if (response.ok) {
      console.log('✅ Frontend revalidation triggered successfully');
    } else {
      console.log('⚠️ Frontend revalidation failed:', response.status);
    }
  } catch (error) {
    console.log('ℹ️ Frontend not reachable for revalidation:', error.message);
  }
}

// Données de test avec gestion de stock
let products = [
  {
    id: "prod_01JA8H8VQZR3K4M2N5P6Q7S8T9",
    title: "Blouson Cuir Premium",
    handle: "blouson-cuir-premium",
    description: "Blouson en cuir véritable, confection artisanale française",
    thumbnail: "/images/luxury_fashion_jacke_28fde759.jpg",
    status: "published",
    collection_id: "coll_capsule",
    // 🎯 GESTION DES RUBRIQUES
    display_sections: ["catalog", "lookbook"], // Où afficher le produit
    lookbook_category: "collection-premium",    // Catégorie dans lookbook
    is_featured: true,                         // Produit vedette
    created_at: "2025-10-14T10:00:00Z",
    updated_at: "2025-10-14T10:00:00Z",
    weight: 1200,
    length: 30,
    width: 25,
    height: 5,
    origin_country: "FR",
    material: "Cuir véritable",
    metadata: { brand: "Meknow", collection: "Premium" },
    variants: [
      { 
        id: "variant_1", 
        title: "S", 
        sku: "BLOUSON-S", 
        inventory_quantity: 15,
        manage_inventory: true,
        allow_backorder: false,
        prices: [{ amount: 25900, currency_code: "eur" }] 
      },
      { 
        id: "variant_2", 
        title: "M", 
        sku: "BLOUSON-M", 
        inventory_quantity: 22,
        manage_inventory: true,
        allow_backorder: false,
        prices: [{ amount: 25900, currency_code: "eur" }] 
      },
      { 
        id: "variant_3", 
        title: "L", 
        sku: "BLOUSON-L", 
        inventory_quantity: 18,
        manage_inventory: true,
        allow_backorder: false,
        prices: [{ amount: 25900, currency_code: "eur" }] 
      },
      { 
        id: "variant_4", 
        title: "XL", 
        sku: "BLOUSON-XL", 
        inventory_quantity: 8,
        manage_inventory: true,
        allow_backorder: false,
        prices: [{ amount: 25900, currency_code: "eur" }] 
      }
    ]
  },
  {
    id: "prod_01JA8H8VQZR3K4M2N5P6Q7S8U0",
    title: "Jean Denim Selvage",
    handle: "jean-denim-selvage",
    description: "Jean en denim selvage authentique, coupe moderne",
    thumbnail: "/images/luxury_fashion_jacke_45c6de81.jpg",
    status: "published",
    collection_id: "coll_capsule",
    // 🎯 GESTION DES RUBRIQUES
    display_sections: ["catalog"],             // Catalogue uniquement
    lookbook_category: null,                   // Pas dans lookbook
    is_featured: false,                        // Pas vedette
    created_at: "2025-10-14T10:00:00Z",
    updated_at: "2025-10-14T10:00:00Z",
    weight: 800,
    length: 40,
    width: 20,
    height: 3,
    origin_country: "FR",
    material: "Denim 100% coton",
    metadata: { brand: "Meknow", collection: "Essentials" },
    variants: [
      { 
        id: "variant_5", 
        title: "S", 
        sku: "JEAN-S", 
        inventory_quantity: 25,
        manage_inventory: true,
        allow_backorder: false,
        prices: [{ amount: 18900, currency_code: "eur" }] 
      },
      { 
        id: "variant_6", 
        title: "M", 
        sku: "JEAN-M", 
        inventory_quantity: 30,
        manage_inventory: true,
        allow_backorder: false,
        prices: [{ amount: 18900, currency_code: "eur" }] 
      },
      { 
        id: "variant_7", 
        title: "L", 
        sku: "JEAN-L", 
        inventory_quantity: 20,
        manage_inventory: true,
        allow_backorder: false,
        prices: [{ amount: 18900, currency_code: "eur" }] 
      },
      { 
        id: "variant_8", 
        title: "XL", 
        sku: "JEAN-XL", 
        inventory_quantity: 12,
        manage_inventory: true,
        allow_backorder: false,
        prices: [{ amount: 18900, currency_code: "eur" }] 
      }
    ]
  },
  {
    id: "prod_01JA8H8VQZR3K4M2N5P6Q7S8V1",
    title: "Chemise Lin Naturel",
    handle: "chemise-lin-naturel",
    description: "Chemise en lin naturel, légère et respirante",
    thumbnail: "/images/premium_fashion_coll_0e2672aa.jpg",
    status: "published",
    collection_id: "coll_capsule",
    // 🎯 GESTION DES RUBRIQUES
    display_sections: ["lookbook"],            // Lookbook uniquement  
    lookbook_category: "style-contemporain",   // Catégorie lookbook
    is_featured: true,                         // Produit vedette
    created_at: "2025-10-14T10:00:00Z",
    updated_at: "2025-10-14T10:00:00Z",
    weight: 300,
    length: 25,
    width: 20,
    height: 2,
    origin_country: "FR",
    material: "Lin 100% naturel",
    metadata: { brand: "Meknow", collection: "Naturel" },
    variants: [
      { 
        id: "variant_9", 
        title: "S", 
        sku: "CHEMISE-S", 
        inventory_quantity: 35,
        manage_inventory: true,
        allow_backorder: true,
        prices: [{ amount: 14900, currency_code: "eur" }] 
      },
      { 
        id: "variant_10", 
        title: "M", 
        sku: "CHEMISE-M", 
        inventory_quantity: 40,
        manage_inventory: true,
        allow_backorder: true,
        prices: [{ amount: 14900, currency_code: "eur" }] 
      },
      { 
        id: "variant_11", 
        title: "L", 
        sku: "CHEMISE-L", 
        inventory_quantity: 28,
        manage_inventory: true,
        allow_backorder: true,
        prices: [{ amount: 14900, currency_code: "eur" }] 
      },
      { 
        id: "variant_12", 
        title: "XL", 
        sku: "CHEMISE-XL", 
        inventory_quantity: 15,
        manage_inventory: true,
        allow_backorder: true,
        prices: [{ amount: 14900, currency_code: "eur" }] 
      }
    ]
  },
  {
    id: "prod_01JA8H8VQZR3K4M2N5P6Q7S8W2",
    title: "T-Shirt Coton Bio",
    handle: "tshirt-coton-bio",
    description: "T-shirt en coton biologique, confortable et durable",
    thumbnail: "/images/premium_fashion_coll_55d86770.jpg",
    status: "published",
    collection_id: "coll_capsule",
    // 🎯 GESTION DES RUBRIQUES
    display_sections: ["catalog", "lookbook"], // Les deux rubriques
    lookbook_category: "savoir-faire-artisanal", // Catégorie lookbook
    is_featured: false,                        // Pas vedette
    created_at: "2025-10-14T10:00:00Z",
    updated_at: "2025-10-14T10:00:00Z",
    weight: 200,
    length: 20,
    width: 15,
    height: 1,
    origin_country: "FR",
    material: "Coton bio certifié",
    metadata: { brand: "Meknow", collection: "Bio" },
    variants: [
      { 
        id: "variant_13", 
        title: "S", 
        sku: "TSHIRT-S", 
        inventory_quantity: 50,
        manage_inventory: true,
        allow_backorder: true,
        prices: [{ amount: 9900, currency_code: "eur" }] 
      },
      { 
        id: "variant_14", 
        title: "M", 
        sku: "TSHIRT-M", 
        inventory_quantity: 60,
        manage_inventory: true,
        allow_backorder: true,
        prices: [{ amount: 9900, currency_code: "eur" }] 
      },
      { 
        id: "variant_15", 
        title: "L", 
        sku: "TSHIRT-L", 
        inventory_quantity: 45,
        manage_inventory: true,
        allow_backorder: true,
        prices: [{ amount: 9900, currency_code: "eur" }] 
      },
      { 
        id: "variant_16", 
        title: "XL", 
        sku: "TSHIRT-XL", 
        inventory_quantity: 30,
        manage_inventory: true,
        allow_backorder: true,
        prices: [{ amount: 9900, currency_code: "eur" }] 
      }
    ]
  }
];

const collections = [
  {
    id: "coll_capsule",
    title: "Capsule Meknow",
    handle: "capsule-menow"
  }
];

// Routes API Store (frontend)
app.get('/store/products', (req, res) => {
  console.log('📦 Store API - GET /store/products');
  res.json({ products });
});

app.get('/store/products/:id', (req, res) => {
  const product = products.find(p => p.id === req.params.id || p.handle === req.params.id);
  if (product) {
    res.json({ product });
  } else {
    res.status(404).json({ message: 'Product not found' });
  }
});

app.get('/store/collections', (req, res) => {
  console.log('📂 Store API - GET /store/collections');
  res.json({ collections });
});

// Routes Admin avancées avec gestion complète
app.get('/admin/products', (req, res) => {
  console.log('⚙️ Admin API - GET /admin/products');
  res.json({ 
    products,
    count: products.length,
    offset: 0,
    limit: 50
  });
});

app.get('/admin/products/:id', (req, res) => {
  const product = products.find(p => p.id === req.params.id);
  if (product) {
    res.json({ product });
  } else {
    res.status(404).json({ message: 'Product not found' });
  }
});

app.post('/admin/products', async (req, res) => {
  const newProduct = {
    id: `prod_${Date.now()}`,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
    status: 'published', // 🚀 AUTO-PUBLIÉ pour affichage immédiat
    variants: [],
    ...req.body
  };
  products.push(newProduct);
  console.log('✅ Produit créé:', newProduct.title);
  
  // 🚀 DÉCLENCHEMENT REVALIDATION AUTOMATIQUE
  await triggerFrontendRevalidation();
  
  res.json({ product: newProduct });
});

app.post('/admin/products/:id', async (req, res) => {
  const productIndex = products.findIndex(p => p.id === req.params.id);
  if (productIndex !== -1) {
    products[productIndex] = {
      ...products[productIndex],
      ...req.body,
      updated_at: new Date().toISOString()
    };
    console.log('✅ Produit mis à jour:', products[productIndex].title);
    
    // 🚀 DÉCLENCHEMENT REVALIDATION AUTOMATIQUE
    await triggerFrontendRevalidation();
    
    res.json({ product: products[productIndex] });
  } else {
    res.status(404).json({ message: 'Product not found' });
  }
});

app.delete('/admin/products/:id', (req, res) => {
  const productIndex = products.findIndex(p => p.id === req.params.id);
  if (productIndex !== -1) {
    const deletedProduct = products.splice(productIndex, 1)[0];
    console.log('🗑️ Produit supprimé:', deletedProduct.title);
    res.json({ message: 'Product deleted', product: deletedProduct });
  } else {
    res.status(404).json({ message: 'Product not found' });
  }
});

// Gestion des variants
app.post('/admin/products/:id/variants', (req, res) => {
  const product = products.find(p => p.id === req.params.id);
  if (product) {
    const newVariant = {
      id: `variant_${Date.now()}`,
      inventory_quantity: 0,
      manage_inventory: true,
      allow_backorder: false,
      ...req.body
    };
    product.variants.push(newVariant);
    res.json({ variant: newVariant });
  } else {
    res.status(404).json({ message: 'Product not found' });
  }
});

app.post('/admin/products/:productId/variants/:variantId', (req, res) => {
  const product = products.find(p => p.id === req.params.productId);
  if (product) {
    const variantIndex = product.variants.findIndex(v => v.id === req.params.variantId);
    if (variantIndex !== -1) {
      product.variants[variantIndex] = {
        ...product.variants[variantIndex],
        ...req.body
      };
      res.json({ variant: product.variants[variantIndex] });
    } else {
      res.status(404).json({ message: 'Variant not found' });
    }
  } else {
    res.status(404).json({ message: 'Product not found' });
  }
});

// Gestion du stock
app.post('/admin/inventory/:variantId', (req, res) => {
  const { quantity, note } = req.body;
  let variant = null;
  let product = null;
  
  for (const p of products) {
    const v = p.variants.find(variant => variant.id === req.params.variantId);
    if (v) {
      variant = v;
      product = p;
      break;
    }
  }
  
  if (variant) {
    const oldQuantity = variant.inventory_quantity;
    variant.inventory_quantity = quantity;
    console.log(`📦 Stock mis à jour: ${product.title} (${variant.title}) ${oldQuantity} → ${quantity}`);
    res.json({ 
      variant,
      message: `Stock updated from ${oldQuantity} to ${quantity}`,
      note: note || ''
    });
  } else {
    res.status(404).json({ message: 'Variant not found' });
  }
});

// Rapport de stock
app.get('/admin/inventory', (req, res) => {
  const inventory = [];
  products.forEach(product => {
    product.variants.forEach(variant => {
      inventory.push({
        product_id: product.id,
        product_title: product.title,
        variant_id: variant.id,
        variant_title: variant.title,
        sku: variant.sku,
        inventory_quantity: variant.inventory_quantity,
        manage_inventory: variant.manage_inventory,
        allow_backorder: variant.allow_backorder,
        status: variant.inventory_quantity <= 5 ? 'low' : variant.inventory_quantity <= 15 ? 'medium' : 'good'
      });
    });
  });
  res.json({ inventory });
});

app.post('/admin/auth/session', (req, res) => {
  const { email, password } = req.body;
  console.log('🔐 Admin Login attempt:', email);
  
  if (email === 'admin@meknow.fr' && password === 'admin123') {
    res.json({
      success: true,
      token: 'admin_token_' + Date.now(),
      user: {
        id: 'admin_01',
        email: 'admin@meknow.fr',
        first_name: 'Admin',
        last_name: 'Meknow'
      },
      admin: {
        id: 'admin_01',
        email: 'admin@meknow.fr',
        first_name: 'Admin',
        last_name: 'Meknow'
      }
    });
  } else {
    res.status(401).json({ success: false, error: 'Email ou mot de passe incorrect' });
  }
});

// ===== ROUTES API =====
app.get('/api/products', (req, res) => {
  console.log('📦 API - GET /api/products', req.query);
  
  let filteredProducts = products;
  
  // Filtrage par collection_id
  if (req.query.collection_id) {
    const collectionFilter = Array.isArray(req.query.collection_id) 
      ? req.query.collection_id 
      : [req.query.collection_id];
    
    filteredProducts = products.filter(product => {
      if (!product.collection_id) return false;
      return collectionFilter.some(col => 
        product.collection_id === `coll_${col}` || 
        product.collection_id === col
      );
    });
  }
  
  // Pagination
  const limit = parseInt(req.query.limit) || 50;
  const offset = parseInt(req.query.offset) || 0;
  const paginatedProducts = filteredProducts.slice(offset, offset + limit);
  
  res.json({
    products: paginatedProducts,
    count: paginatedProducts.length,
    total: filteredProducts.length,
    offset: offset,
    limit: limit
  });
});

// 🎯 NOUVELLES ROUTES POUR GESTION DES RUBRIQUES (AVANT /:id pour éviter confusion)

// Route pour obtenir les produits du catalogue (section "Nos Produits")
app.get('/api/products/catalog', (req, res) => {
  console.log('🛍️ API - GET /api/products/catalog');
  
  const catalogProducts = products.filter(product => 
    product.display_sections && product.display_sections.includes('catalog')
  );
  
  res.json({
    products: catalogProducts,
    count: catalogProducts.length,
    section: 'catalog'
  });
});

// Route pour obtenir les produits du lookbook (section "Lookbook")
app.get('/api/products/lookbook', (req, res) => {
  console.log('👗 API - GET /api/products/lookbook');
  
  const lookbookProducts = products.filter(product => 
    product.display_sections && product.display_sections.includes('lookbook')
  );
  
  // Grouper par catégorie lookbook
  const groupedProducts = lookbookProducts.reduce((acc, product) => {
    const category = product.lookbook_category || 'uncategorized';
    if (!acc[category]) acc[category] = [];
    acc[category].push(product);
    return acc;
  }, {});
  
  res.json({
    products: lookbookProducts,
    grouped: groupedProducts,
    count: lookbookProducts.length,
    section: 'lookbook'
  });
});

// Route pour obtenir les produits vedettes
app.get('/api/products/featured', (req, res) => {
  console.log('⭐ API - GET /api/products/featured');
  
  const featuredProducts = products.filter(product => product.is_featured === true);
  
  res.json({
    products: featuredProducts,
    count: featuredProducts.length,
    section: 'featured'
  });
});

// Route pour créer un nouveau produit
app.post('/api/products', async (req, res) => {
  console.log('📦 API - POST /api/products', req.body);
  
  const { 
    title, 
    description, 
    imageUrl, 
    price, 
    variants, 
    collection_id,
    // 🎯 NOUVEAUX CHAMPS RUBRIQUES
    display_sections,
    lookbook_category,
    is_featured
  } = req.body;
  
  if (!title || !imageUrl) {
    return res.status(400).json({
      success: false,
      error: 'Titre et image requis'
    });
  }
  
  // Générer un ID unique
  const productId = `prod_${Date.now()}_${Math.round(Math.random() * 1000)}`;
  
  // Convertir le prix en centimes
  const priceInCents = price ? Math.round(price * 100) : 9900;
  
  // Créer les variants à partir des données du formulaire
  const productVariants = [];
  if (variants && typeof variants === 'object') {
    Object.entries(variants).forEach(([size, quantity]) => {
      productVariants.push({
        id: `variant_${productId}_${size.toLowerCase()}`,
        title: size,
        sku: `${productId.toUpperCase()}-${size}`,
        inventory_quantity: parseInt(quantity) || 0,
        manage_inventory: true,
        allow_backorder: false,
        prices: [{ amount: priceInCents, currency_code: "eur" }]
      });
    });
  } else {
    // Variants par défaut si non spécifiés
    ['S', 'M', 'L'].forEach(size => {
      productVariants.push({
        id: `variant_${productId}_${size.toLowerCase()}`,
        title: size,
        sku: `${productId.toUpperCase()}-${size}`,
        inventory_quantity: 10,
        manage_inventory: true,
        allow_backorder: false,
        prices: [{ amount: priceInCents, currency_code: "eur" }]
      });
    });
  }
  
  // Créer le nouveau produit
  const newProduct = {
    id: productId,
    title: title,
    handle: title.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/-+/g, '-').replace(/^-|-$/g, ''),
    description: description || '',
    thumbnail: imageUrl,
    status: "published",
    collection_id: collection_id || null,
    // 🎯 GESTION DES RUBRIQUES
    display_sections: display_sections || ["catalog"], // Par défaut: catalogue
    lookbook_category: lookbook_category || null,
    is_featured: is_featured === true || is_featured === "true",
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
    weight: 500,
    length: 25,
    width: 20,
    height: 3,
    origin_country: "FR",
    material: "Textile premium",
    metadata: { brand: "Meknow", collection: "Nouveau" },
    variants: productVariants
  };
  
  // Ajouter le produit à la liste
  products.push(newProduct);
  
  console.log(`✅ Produit créé: ${title} (ID: ${productId})`);
  
  // 🚀 DÉCLENCHEMENT REVALIDATION AUTOMATIQUE
  await triggerFrontendRevalidation();
  
  res.json({
    success: true,
    product: newProduct,
    message: `Produit "${title}" créé avec succès`
  });
});

// Route pour modifier un produit existant
app.put('/api/products/:id', async (req, res) => {
  console.log(`📦 API - PUT /api/products/${req.params.id}`, req.body);
  
  const productIndex = products.findIndex(p => p.id === req.params.id);
  if (productIndex === -1) {
    return res.status(404).json({
      success: false,
      error: 'Produit non trouvé'
    });
  }
  
  const originalProduct = products[productIndex];
  
  // Gérer spécialement les variants si ils viennent du frontend admin
  if (req.body.variants && typeof req.body.variants === 'object' && !Array.isArray(req.body.variants)) {
    // Format admin: {S: 10, M: 15, L: 8} → mise à jour des quantités des variants existants
    const variantStocks = req.body.variants;
    const updatedVariants = originalProduct.variants.map(variant => {
      if (variantStocks[variant.title] !== undefined) {
        return {
          ...variant,
          inventory_quantity: variantStocks[variant.title]
        };
      }
      return variant;
    });
    
    // Mettre à jour le produit en préservant la structure des variants
    products[productIndex] = {
      ...originalProduct,
      title: req.body.title || originalProduct.title,
      description: req.body.description || originalProduct.description,
      category: req.body.category || originalProduct.category,
      status: req.body.status || originalProduct.status,
      variants: updatedVariants,
      // Mise à jour explicite de display_sections
      display_sections: req.body.display_sections || originalProduct.display_sections,
      updated_at: new Date().toISOString()
    };
    
    // Mettre à jour le prix si fourni (en centimes)
    if (req.body.price) {
      const priceInCents = Math.round(req.body.price * 100);
      products[productIndex].variants.forEach(variant => {
        variant.prices[0].amount = priceInCents;
      });
    }
  } else {
    // Mise à jour normale (préserve les variants originaux)
    products[productIndex] = {
      ...originalProduct,
      ...req.body,
      variants: originalProduct.variants, // Préserver les variants originaux
      // Mise à jour explicite de display_sections
      display_sections: req.body.display_sections || originalProduct.display_sections,
      updated_at: new Date().toISOString()
    };
  }
  
  console.log(`✅ Produit modifié: ${products[productIndex].title}`);
  
  // 🚀 DÉCLENCHEMENT REVALIDATION AUTOMATIQUE
  await triggerFrontendRevalidation();
  
  res.json({
    success: true,
    product: products[productIndex],
    message: 'Produit modifié avec succès'
  });
});

// Route pour supprimer un produit
app.delete('/api/products/:id', (req, res) => {
  console.log(`📦 API - DELETE /api/products/${req.params.id}`);
  
  const productIndex = products.findIndex(p => p.id === req.params.id);
  if (productIndex === -1) {
    return res.status(404).json({
      success: false,
      error: 'Produit non trouvé'
    });
  }
  
  const deletedProduct = products.splice(productIndex, 1)[0];
  console.log(`🗑️ Produit supprimé: ${deletedProduct.title}`);
  
  res.json({
    success: true,
    message: `Produit "${deletedProduct.title}" supprimé avec succès`
  });
});

// Route pour la gestion des stocks
app.put('/api/inventory/:variantId', (req, res) => {
  console.log(`📋 API - PUT /api/inventory/${req.params.variantId}`, req.body);
  
  const { quantity, note } = req.body;
  let variant = null;
  let product = null;
  
  // Trouver la variante dans tous les produits
  for (let p of products) {
    const v = p.variants.find(variant => variant.id === req.params.variantId);
    if (v) {
      variant = v;
      product = p;
      break;
    }
  }
  
  if (!variant) {
    return res.status(404).json({
      success: false,
      error: 'Variante non trouvée'
    });
  }
  
  const oldQuantity = variant.inventory_quantity;
  variant.inventory_quantity = quantity;
  
  console.log(`📦 Stock mis à jour: ${product.title} (${variant.title}) ${oldQuantity} → ${quantity}`);
  
  res.json({
    success: true,
    variant,
    oldQuantity,
    newQuantity: quantity,
    note: note || '',
    message: `Stock mis à jour de ${oldQuantity} à ${quantity}`
  });
});

// Route pour obtenir l'inventaire complet
app.get('/api/inventory', (req, res) => {
  console.log('📋 API - GET /api/inventory');
  
  const inventory = [];
  products.forEach(product => {
    product.variants.forEach(variant => {
      inventory.push({
        product_id: product.id,
        product_title: product.title,
        variant_id: variant.id,
        variant_title: variant.title,
        sku: variant.sku,
        inventory_quantity: variant.inventory_quantity,
        manage_inventory: variant.manage_inventory,
        allow_backorder: variant.allow_backorder,
        status: variant.inventory_quantity <= 5 ? 'low' : variant.inventory_quantity <= 15 ? 'medium' : 'good',
        price: variant.prices[0].amount / 100
      });
    });
  });
  
  res.json({
    inventory,
    count: inventory.length,
    low_stock_count: inventory.filter(item => item.status === 'low').length
  });
});

// Route pour les statistiques du tableau de bord
app.get('/api/dashboard', (req, res) => {
  console.log('📊 API - GET /api/dashboard');
  
  const totalProducts = products.length;
  const totalVariants = products.reduce((sum, p) => sum + p.variants.length, 0);
  const lowStockItems = products.reduce((sum, p) => {
    return sum + p.variants.filter(v => v.inventory_quantity <= 5).length;
  }, 0);
  
  const totalStock = products.reduce((sum, p) => {
    return sum + p.variants.reduce((vSum, v) => vSum + v.inventory_quantity, 0);
  }, 0);
  
  const totalValue = products.reduce((sum, p) => {
    return sum + p.variants.reduce((vSum, v) => vSum + (v.prices[0].amount * v.inventory_quantity), 0);
  }, 0);
  
  res.json({
    totalProducts,
    totalVariants,
    totalStock,
    lowStockItems,
    totalValue: totalValue / 100, // Convert to euros
    averageStockPerProduct: Math.round(totalStock / totalProducts),
    categories: products.reduce((acc, p) => {
      const cat = p.metadata?.category || 'Non catégorisé';
      acc[cat] = (acc[cat] || 0) + 1;
      return acc;
    }, {})
  });
});

// Route pour obtenir un produit spécifique (DOIT être après les routes spécifiques)
app.get('/api/products/:id', (req, res) => {
  console.log(`📦 API - GET /api/products/${req.params.id}`);
  
  const product = products.find(p => p.id === req.params.id);
  if (!product) {
    return res.status(404).json({
      success: false,
      error: 'Produit non trouvé'
    });
  }
  
  res.json({
    success: true,
    product
  });
});

// Routes API Collections pour Next.js
app.get('/api/collections', (req, res) => {
  console.log('📂 API - GET /api/collections');
  res.json({ collections });
});

app.get('/api/collections/:handle', (req, res) => {
  console.log(`📂 API - GET /api/collections/${req.params.handle}`);
  
  const collection = collections.find(c => c.handle === req.params.handle || c.id === req.params.handle);
  if (!collection) {
    return res.status(404).json({
      success: false,
      error: 'Collection non trouvée'
    });
  }
  
  // Ajouter les produits de la collection (pour l'instant tous les produits)
  const collectionWithProducts = {
    ...collection,
    products: products.filter(p => p.status === 'published')
  };
  
  res.json({
    success: true,
    collection: collectionWithProducts
  });
});

// Interface Admin complète
app.get('/admin', (req, res) => {
  // Headers pour éviter le cache
  res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
  res.setHeader('Pragma', 'no-cache');
  res.setHeader('Expires', '0');
  res.sendFile(path.join(__dirname, 'admin-complete-ecommerce.html'));
});

// Page de login admin
app.get('/login', (req, res) => {
  res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
  res.setHeader('Pragma', 'no-cache');
  res.setHeader('Expires', '0');
  res.sendFile(path.join(__dirname, 'admin-login.html'));
});

// ===== UPLOAD D'IMAGES =====
const multer = require('multer');
const fs = require('fs');

// Configuration stockage images
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

// Servir les fichiers statiques HTML (APRÈS les routes spécifiques)
app.use(express.static('./', {
  extensions: ['html'],
  index: false
}));

// Servir les images statiques
app.use('/images', express.static('./public/images'));

// Route d'upload d'images
app.post('/api/upload', upload.single('image'), (req, res) => {
  console.log('📷 API - POST /api/upload');
  
  if (!req.file) {
    return res.status(400).json({ 
      success: false, 
      error: 'Aucune image fournie' 
    });
  }

  const imageUrl = `/images/${req.file.filename}`;
  
  res.json({ 
    success: true, 
    url: imageUrl,
    filename: req.file.filename,
    originalName: req.file.originalname,
    size: req.file.size
  });
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'meknow-backend-minimal' });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Backend Meknow minimal démarré sur port ${PORT}`);
  console.log(`📱 Frontend: http://localhost:3000`);
  console.log(`⚙️ Admin: http://localhost:${PORT}/admin`);
  console.log(`🔐 Login: http://localhost:${PORT}/login`);
  console.log(`📦 API: http://localhost:${PORT}/api/products`);
  console.log(`📷 Upload: /api/upload | Images: /images/*`);
});