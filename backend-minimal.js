const express = require('express');
const cors = require('cors');

const app = express();
const PORT = 9000;

// Middleware
app.use(cors({
  origin: ['http://localhost:5000', 'http://localhost:3000'],
  credentials: true
}));
app.use(express.json());

// Données de test avec gestion de stock
let products = [
  {
    id: "prod_01JA8H8VQZR3K4M2N5P6Q7S8T9",
    title: "Blouson Cuir Premium",
    handle: "blouson-cuir-premium",
    description: "Blouson en cuir véritable, confection artisanale française",
    thumbnail: "/products/luxury_fashion_jacke_28fde759.jpg",
    status: "published",
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
    thumbnail: "/products/luxury_fashion_jacke_45c6de81.jpg",
    status: "published",
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
    thumbnail: "/products/premium_fashion_coll_0e2672aa.jpg",
    status: "published",
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
    thumbnail: "/products/premium_fashion_coll_55d86770.jpg",
    status: "published",
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

app.post('/admin/products', (req, res) => {
  const newProduct = {
    id: `prod_${Date.now()}`,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
    status: 'draft',
    variants: [],
    ...req.body
  };
  products.push(newProduct);
  console.log('✅ Produit créé:', newProduct.title);
  res.json({ product: newProduct });
});

app.post('/admin/products/:id', (req, res) => {
  const productIndex = products.findIndex(p => p.id === req.params.id);
  if (productIndex !== -1) {
    products[productIndex] = {
      ...products[productIndex],
      ...req.body,
      updated_at: new Date().toISOString()
    };
    console.log('✅ Produit mis à jour:', products[productIndex].title);
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
  
  if (email === 'admin@medusa.com' && password === 'admin123') {
    res.json({
      user: {
        id: 'admin_01',
        email: 'admin@medusa.com',
        first_name: 'Admin',
        last_name: 'Meknow'
      }
    });
  } else {
    res.status(401).json({ message: 'Invalid credentials' });
  }
});

// Interface Admin simple
app.get('/app', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
        <title>Admin Meknow</title>
        <style>
            body { font-family: Arial; background: #0B0B0C; color: white; padding: 20px; }
            .container { max-width: 1200px; margin: 0 auto; }
            h1 { color: #F2C14E; }
            .card { background: #1A1A1B; padding: 20px; margin: 10px 0; border-radius: 8px; border: 1px solid #F2C14E; }
            .product { display: grid; grid-template-columns: 100px 1fr auto; gap: 15px; align-items: center; }
            img { width: 80px; height: 80px; object-fit: cover; border-radius: 6px; }
            .price { color: #F2C14E; font-weight: bold; }
            .status { background: #1A4A1A; padding: 4px 8px; border-radius: 4px; font-size: 12px; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🔧 Admin Meknow - Interface Simplifiée</h1>
            
            <div class="card">
                <h2>📊 Tableau de Bord</h2>
                <p>✅ <strong>4 produits</strong> actifs</p>
                <p>✅ <strong>Collection Capsule Meknow</strong> configurée</p>
                <p>✅ <strong>Paiement COD</strong> activé</p>
                <p>✅ <strong>Images</strong> corrigées</p>
            </div>

            <div class="card">
                <h2>📦 Produits</h2>
                ${products.map(p => `
                    <div class="product">
                        <img src="http://localhost:5000${p.thumbnail}" alt="${p.title}">
                        <div>
                            <h3>${p.title}</h3>
                            <p>${p.description}</p>
                            <span class="status">Publié</span>
                        </div>
                        <div class="price">${(p.variants[0].prices[0].amount / 100).toFixed(2)}€</div>
                    </div>
                `).join('')}
            </div>

            <div class="card">
                <h2>🔗 Liens Utiles</h2>
                <p><a href="http://localhost:5000" style="color: #F2C14E;">🛍️ Voir le site frontend</a></p>
                <p><a href="http://localhost:9000/store/products" style="color: #F2C14E;">📦 API Produits</a></p>
                <p><a href="http://localhost:8080" style="color: #F2C14E;">🔧 Interface de test</a></p>
            </div>
        </div>
    </body>
    </html>
  `);
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'meknow-backend-minimal' });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Backend Meknow minimal démarré sur port ${PORT}`);
  console.log(`📱 Frontend: http://localhost:5000`);
  console.log(`⚙️ Admin: http://localhost:${PORT}/app`);
  console.log(`📦 API: http://localhost:${PORT}/store/products`);
});