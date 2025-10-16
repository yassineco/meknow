const express = require('express');
const cors = require('cors');
const { createProxyMiddleware } = require('http-proxy-middleware');
const path = require('path');

const app = express();
const PORT = 3002;

// Enable CORS for all routes
app.use(cors());

// Serve static files from the current directory
app.use(express.static('.'));

// Add logging middleware
app.use((req, res, next) => {
  console.log(`${req.method} ${req.url}`);
  next();
});

// Proxy API requests to meknow.fr
app.use('/api', createProxyMiddleware({
  target: 'https://meknow.fr',
  changeOrigin: true,
  secure: true,
  logLevel: 'info',
  onProxyReq: (proxyReq, req, res) => {
    console.log(`[PROXY] ${req.method} ${req.url} -> https://meknow.fr${req.url}`);
  },
  onProxyRes: (proxyRes, req, res) => {
    console.log(`[PROXY] Response: ${proxyRes.statusCode} for ${req.url}`);
  },
  onError: (err, req, res) => {
    console.error(`[PROXY] Error for ${req.url}:`, err.message);
    res.status(500).json({ error: 'Proxy Error', message: err.message });
  }
}));

// Simple test endpoint
app.get('/test', (req, res) => {
  res.json({ status: 'Server is working', timestamp: new Date().toISOString() });
});

// Serve the admin interface at /admin
app.get('/admin', (req, res) => {
  res.sendFile(path.join(__dirname, 'admin-complete-ecommerce.html'));
});

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
  console.log(`Admin interface: http://localhost:${PORT}/admin`);
  console.log(`API proxy: http://localhost:${PORT}/api/*`);
  console.log(`Test endpoint: http://localhost:${PORT}/test`);
});