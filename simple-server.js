const express = require('express');
const cors = require('cors');
const path = require('path');

const app = express();
const PORT = 9001; // Port différent pour éviter les conflits

// Middlewares de base
app.use(cors());
app.use(express.json());
app.use(express.static('.'));

// Données mock pour tester
let products = [
  {
    id: 'prod_1',
    title: 'chemise',
    description: 'Belle chemise',
    price: 0,
    category: 'vetements',
    status: 'published',
    variants: [
      { id: 'var_1', title: 'S', inventory_quantity: 0, price: 0, option1: 'S' },
      { id: 'var_2', title: 'M', inventory_quantity: 0, price: 0, option1: 'M' },
      { id: 'var_3', title: 'L', inventory_quantity: 0, price: 0, option1: 'L' }
    ]
  }
];

// Routes API simples
app.get('/api/products', (req, res) => {
  console.log('GET /api/products');
  res.json({
    success: true,
    products: products,
    count: products.length
  });
});

app.post('/api/products', (req, res) => {
  console.log('POST /api/products', req.body);
  
  const { title, description, price, category, status, variants } = req.body;
  
  const newProduct = {
    id: `prod_${Date.now()}`,
    title: title || 'Nouveau produit',
    description: description || '',
    price: parseFloat(price) || 0,
    category: category || 'general',
    status: status || 'published',
    variants: []
  };
  
  // Créer les variants
  if (variants && typeof variants === 'object') {
    Object.entries(variants).forEach(([size, quantity]) => {
      if (quantity > 0) {
        newProduct.variants.push({
          id: `var_${Date.now()}_${size}`,
          title: `${title} - ${size}`,
          inventory_quantity: parseInt(quantity),
          price: parseFloat(price) || 0,
          option1: size
        });
      }
    });
  }
  
  products.push(newProduct);
  
  res.status(201).json({
    success: true,
    product: newProduct,
    message: `Produit "${title}" créé avec succès`
  });
});

app.post('/api/upload', (req, res) => {
  console.log('POST /api/upload');
  res.json({
    success: true,
    url: '/images/placeholder.jpg'
  });
});

// Servir les pages admin
app.get('/admin', (req, res) => {
  res.sendFile(path.join(__dirname, 'admin-complete-ecommerce.html'));
});

app.get('/login', (req, res) => {
  res.sendFile(path.join(__dirname, 'admin-login.html'));
});

// Login mock
app.post('/api/admin/login', (req, res) => {
  console.log('POST /api/admin/login', req.body);
  res.json({
    success: true,
    token: 'mock-token-123',
    admin: { id: 1, email: 'admin@meknow.fr', name: 'Admin' }
  });
});

app.listen(PORT, () => {
  console.log(`🚀 Serveur simple démarré sur port ${PORT}`);
  console.log(`📱 Admin: http://localhost:${PORT}/admin`);
  console.log(`📦 API: http://localhost:${PORT}/api/*`);
});