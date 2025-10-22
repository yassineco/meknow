#!/bin/bash
# SOLUTION DIRECTE MEKNOW - Copier ce script sur le VPS

echo "🚀 DÉPLOIEMENT DIRECT MEKNOW"
echo "============================"

# Mise à jour système
apt update && apt upgrade -y

# Installation Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
systemctl enable docker
systemctl start docker

# Installation Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Nettoyage
cd /root
rm -rf menow
docker system prune -af --volumes

# Création du projet
mkdir -p menow
cd menow

# Docker Compose simple
cat > docker-compose.yml << 'COMPOSE'
version: '3.8'
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: meknow_db
      POSTGRES_USER: meknow_user
      POSTGRES_PASSWORD: meknow_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  backend:
    build: ./backend
    ports:
      - "5001:5001"
    depends_on:
      - postgres
    environment:
      DATABASE_URL: postgresql://meknow_user:meknow_password@postgres:5432/meknow_db

  frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    depends_on:
      - backend

volumes:
  postgres_data:
COMPOSE

# Création backend
mkdir -p backend
cat > backend/package.json << 'BACKEND_PACKAGE'
{
  "name": "meknow-backend",
  "version": "1.0.0",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "pg": "^8.11.3"
  }
}
BACKEND_PACKAGE

cat > backend/server.js << 'BACKEND_JS'
const express = require('express');
const cors = require('cors');
const app = express();

app.use(cors());
app.use(express.json());

// Routes API
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    service: 'MEKNOW API',
    timestamp: new Date().toISOString()
  });
});

app.get('/api/products', (req, res) => {
  res.json([
    { id: 1, name: 'Veste de Luxe', price: 299.99, category: 'Fashion' },
    { id: 2, name: 'Pantalon Premium', price: 199.99, category: 'Fashion' },
    { id: 3, name: 'Chaussures Elite', price: 399.99, category: 'Shoes' }
  ]);
});

app.get('/api/categories', (req, res) => {
  res.json([
    { id: 1, name: 'Fashion', count: 25 },
    { id: 2, name: 'Shoes', count: 15 },
    { id: 3, name: 'Accessories', count: 30 }
  ]);
});

const PORT = process.env.PORT || 5001;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🔧 MEKNOW Backend running on port ${PORT}`);
});
BACKEND_JS

cat > backend/Dockerfile << 'BACKEND_DOCKER'
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 5001
CMD ["npm", "start"]
BACKEND_DOCKER

# Création frontend
mkdir -p frontend
cat > frontend/package.json << 'FRONTEND_PACKAGE'
{
  "name": "meknow-frontend",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "build": "next build",
    "start": "next start"
  },
  "dependencies": {
    "next": "14.0.0",
    "react": "18.2.0",
    "react-dom": "18.2.0"
  },
  "devDependencies": {
    "@types/node": "20.8.0",
    "@types/react": "18.2.0",
    "@types/react-dom": "18.2.0",
    "typescript": "5.2.0"
  }
}
FRONTEND_PACKAGE

mkdir -p frontend/src/app
cat > frontend/src/app/layout.tsx << 'LAYOUT'
export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="fr">
      <head>
        <title>MEKNOW E-commerce</title>
        <style>{`
          body { margin: 0; font-family: Arial, sans-serif; background: #0f172a; color: white; }
          .container { max-width: 1200px; margin: 0 auto; padding: 2rem; }
          .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 2rem; margin: 2rem 0; }
          .card { background: #1e293b; padding: 2rem; border-radius: 8px; text-align: center; }
          .btn { background: #3b82f6; color: white; padding: 1rem 2rem; text-decoration: none; border-radius: 4px; display: inline-block; margin: 0.5rem; }
          .btn:hover { background: #2563eb; }
        `}</style>
      </head>
      <body>{children}</body>
    </html>
  )
}
LAYOUT

cat > frontend/src/app/page.tsx << 'PAGE'
export default function Home() {
  return (
    <div className="container">
      <header style={{textAlign: 'center', marginBottom: '3rem'}}>
        <h1 style={{fontSize: '4rem', margin: '0 0 1rem 0'}}>🛍️ MEKNOW</h1>
        <h2 style={{fontSize: '2rem', color: '#94a3b8'}}>E-COMMERCE PLATFORM</h2>
      </header>

      <div className="grid">
        <div className="card">
          <h3>🎨 Frontend Modern</h3>
          <p>Interface Next.js responsive et performante</p>
        </div>
        <div className="card">
          <h3>🔧 API Robuste</h3>
          <p>Backend Express.js avec base de données</p>
        </div>
        <div className="card">
          <h3>👑 Administration</h3>
          <p>Dashboard complet de gestion</p>
        </div>
      </div>

      <div style={{textAlign: 'center', marginTop: '3rem'}}>
        <a href="/api/health" className="btn">🔧 Status API</a>
        <a href="/api/products" className="btn">📦 Produits</a>
        <a href="/api/categories" className="btn">📋 Catégories</a>
      </div>

      <footer style={{textAlign: 'center', marginTop: '4rem', padding: '2rem', borderTop: '1px solid #334155'}}>
        <p>© 2025 MEKNOW E-commerce - Déployé avec Docker 🐳</p>
      </footer>
    </div>
  )
}
PAGE

cat > frontend/next.config.js << 'NEXTCONFIG'
/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  trailingSlash: true,
  poweredByHeader: false,
}

module.exports = nextConfig
NEXTCONFIG

cat > frontend/Dockerfile << 'FRONTEND_DOCKER'
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build
EXPOSE 3000
CMD ["npm", "start"]
FRONTEND_DOCKER

# Installation Nginx
apt install -y nginx

# Configuration Nginx
cat > /etc/nginx/sites-available/meknow << 'NGINX'
server {
    listen 80;
    server_name meknow.fr www.meknow.fr _;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /api/ {
        proxy_pass http://localhost:5001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINX

ln -sf /etc/nginx/sites-available/meknow /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

# Construction et démarrage
echo "🏗️ Construction des services..."
docker-compose build --no-cache
docker-compose up -d

# Attente
echo "⏳ Attente du démarrage (45s)..."
sleep 45

# Vérification
echo "📊 Status:"
docker-compose ps
echo ""
curl -s http://localhost:3000 > /dev/null && echo "✅ Frontend OK" || echo "❌ Frontend KO"
curl -s http://localhost:5001/api/health > /dev/null && echo "✅ Backend OK" || echo "❌ Backend KO"

echo ""
echo "🎉 DÉPLOIEMENT TERMINÉ!"
echo "🌐 Site: http://meknow.fr"
echo "🔧 API: http://meknow.fr/api/health"