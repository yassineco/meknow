const http = require('http');
const fs = require('fs');
const path = require('path');
const url = require('url');

const PORT = 8080;

// Données mock
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

function serveFile(filePath, res) {
  fs.readFile(filePath, (err, data) => {
    if (err) {
      res.writeHead(404);
      res.end('File not found');
      return;
    }
    
    const ext = path.extname(filePath);
    let contentType = 'text/html';
    
    if (ext === '.js') contentType = 'text/javascript';
    else if (ext === '.css') contentType = 'text/css';
    else if (ext === '.json') contentType = 'application/json';
    
    res.writeHead(200, { 'Content-Type': contentType });
    res.end(data);
  });
}

const server = http.createServer((req, res) => {
  const parsedUrl = url.parse(req.url, true);
  const pathname = parsedUrl.pathname;
  
  console.log(`${req.method} ${pathname}`);
  
  // CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  
  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }
  
  // Routes
  if (pathname === '/admin') {
    serveFile('admin-complete-ecommerce.html', res);
  } else if (pathname === '/login') {
    serveFile('admin-login.html', res);
  } else if (pathname === '/api/products' && req.method === 'GET') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      success: true,
      products: products,
      count: products.length
    }));
  } else if (pathname === '/api/products' && req.method === 'POST') {
    let body = '';
    req.on('data', chunk => {
      body += chunk.toString();
    });
    req.on('end', () => {
      try {
        const data = JSON.parse(body);
        console.log('Creating product:', data);
        
        const newProduct = {
          id: `prod_${Date.now()}`,
          title: data.title || 'Nouveau produit',
          description: data.description || '',
          price: parseFloat(data.price) || 0,
          category: data.category || 'general',
          status: data.status || 'published',
          variants: []
        };
        
        // Créer les variants
        if (data.variants && typeof data.variants === 'object') {
          Object.entries(data.variants).forEach(([size, quantity]) => {
            if (quantity > 0) {
              newProduct.variants.push({
                id: `var_${Date.now()}_${size}`,
                title: `${data.title} - ${size}`,
                inventory_quantity: parseInt(quantity),
                price: parseFloat(data.price) || 0,
                option1: size
              });
            }
          });
        }
        
        products.push(newProduct);
        
        res.writeHead(201, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
          success: true,
          product: newProduct,
          message: `Produit "${data.title}" créé avec succès`
        }));
      } catch (err) {
        console.error('Error parsing JSON:', err);
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
          success: false,
          error: 'Invalid JSON'
        }));
      }
    });
  } else if (pathname === '/api/upload' && req.method === 'POST') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      success: true,
      url: '/images/placeholder.jpg'
    }));
  } else if (pathname === '/api/admin/login' && req.method === 'POST') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      success: true,
      token: 'mock-token-123',
      admin: { id: 1, email: 'admin@meknow.fr', name: 'Admin' }
    }));
  } else if (pathname.startsWith('/api/admin/products/') && req.method === 'GET') {
    // Récupérer un produit spécifique
    const productId = pathname.split('/').pop();
    const product = products.find(p => p.id === productId);
    
    if (product) {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({
        success: true,
        product: product
      }));
    } else {
      res.writeHead(404, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({
        success: false,
        error: 'Produit non trouvé'
      }));
    }
  } else if (pathname.startsWith('/api/products/') && req.method === 'PUT') {
    // Modifier un produit
    const productId = pathname.split('/').pop();
    let body = '';
    req.on('data', chunk => {
      body += chunk.toString();
    });
    req.on('end', () => {
      try {
        const data = JSON.parse(body);
        const productIndex = products.findIndex(p => p.id === productId);
        
        if (productIndex !== -1) {
          // Mettre à jour le produit
          products[productIndex] = {
            ...products[productIndex],
            title: data.title || products[productIndex].title,
            description: data.description || products[productIndex].description,
            price: parseFloat(data.price) || products[productIndex].price,
            category: data.category || products[productIndex].category,
            status: data.status || products[productIndex].status
          };
          
          // Mettre à jour les variants si fournis
          if (data.variants && typeof data.variants === 'object') {
            products[productIndex].variants = [];
            Object.entries(data.variants).forEach(([size, quantity]) => {
              if (quantity > 0) {
                products[productIndex].variants.push({
                  id: `var_${Date.now()}_${size}`,
                  title: `${data.title} - ${size}`,
                  inventory_quantity: parseInt(quantity),
                  price: parseFloat(data.price) || 0,
                  option1: size
                });
              }
            });
          }
          
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({
            success: true,
            product: products[productIndex],
            message: `Produit "${data.title}" modifié avec succès`
          }));
        } else {
          res.writeHead(404, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({
            success: false,
            error: 'Produit non trouvé'
          }));
        }
      } catch (err) {
        console.error('Error parsing JSON:', err);
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
          success: false,
          error: 'Invalid JSON'
        }));
      }
    });
  } else if (pathname.startsWith('/api/products/') && req.method === 'DELETE') {
    // Supprimer un produit
    const productId = pathname.split('/').pop();
    const productIndex = products.findIndex(p => p.id === productId);
    
    if (productIndex !== -1) {
      const deletedProduct = products.splice(productIndex, 1)[0];
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({
        success: true,
        message: `Produit "${deletedProduct.title}" supprimé avec succès`
      }));
    } else {
      res.writeHead(404, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({
        success: false,
        error: 'Produit non trouvé'
      }));
    }
  } else {
    // Serve static files
    const filePath = pathname === '/' ? 'index.html' : pathname.substring(1);
    serveFile(filePath, res);
  }
});

server.listen(PORT, () => {
  console.log(`🚀 Serveur HTTP basique démarré sur port ${PORT}`);
  console.log(`📱 Admin: http://localhost:${PORT}/admin`);
  console.log(`📦 API: http://localhost:${PORT}/api/*`);
});