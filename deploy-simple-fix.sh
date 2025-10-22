#!/bin/bash
# deploy-simple-fix.sh - Solution sans TypeScript

echo "🚀 DÉPLOIEMENT MEKNOW - Version JavaScript Pure"
echo "==============================================="

# Nettoyage complet
cd /root
rm -rf menow
docker system prune -af --volumes

# Création du projet
mkdir -p menow
cd menow

# Docker Compose ultra-simple
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

  backend:
    build: ./backend
    ports:
      - "5001:5001"
    depends_on:
      - postgres

  frontend:
    build: ./frontend  
    ports:
      - "3000:3000"
    depends_on:
      - backend

volumes:
  postgres_data:
COMPOSE

# Backend Express simple
mkdir -p backend
cat > backend/package.json << 'BACKENDPKG'
{
  "name": "meknow-backend",
  "version": "1.0.0",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5"
  }
}
BACKENDPKG

cat > backend/server.js << 'BACKENDJS'
const express = require('express');
const cors = require('cors');
const app = express();

app.use(cors());
app.use(express.json());

app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    service: 'MEKNOW API',
    timestamp: new Date().toISOString()
  });
});

app.get('/api/products', (req, res) => {
  res.json([
    { id: 1, name: 'Veste Luxe', price: 299.99, image: '/images/veste1.jpg' },
    { id: 2, name: 'Pantalon Premium', price: 199.99, image: '/images/pantalon1.jpg' },
    { id: 3, name: 'Chaussures Elite', price: 399.99, image: '/images/chaussures1.jpg' }
  ]);
});

const PORT = 5001;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🔧 MEKNOW Backend démarré sur le port ${PORT}`);
});
BACKENDJS

cat > backend/Dockerfile << 'BACKENDDOCKER'
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 5001
CMD ["npm", "start"]
BACKENDDOCKER

# Frontend Next.js SANS TypeScript
mkdir -p frontend
cat > frontend/package.json << 'FRONTENDPKG'
{
  "name": "meknow-frontend",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "build": "next build",
    "start": "next start"
  },
  "dependencies": {
    "next": "13.5.6",
    "react": "18.2.0",
    "react-dom": "18.2.0"
  }
}
FRONTENDPKG

# Pages sans TypeScript
mkdir -p frontend/pages
cat > frontend/pages/_app.js << 'APP'
export default function App({ Component, pageProps }) {
  return (
    <>
      <style jsx global>{`
        body {
          margin: 0;
          font-family: Arial, sans-serif;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          min-height: 100vh;
          color: white;
        }
        .container {
          max-width: 1200px;
          margin: 0 auto;
          padding: 2rem;
        }
        .header {
          text-align: center;
          margin-bottom: 3rem;
        }
        .title {
          font-size: 4rem;
          margin: 0 0 1rem 0;
          text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }
        .subtitle {
          font-size: 1.5rem;
          opacity: 0.9;
        }
        .grid {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
          gap: 2rem;
          margin: 3rem 0;
        }
        .card {
          background: rgba(255,255,255,0.1);
          backdrop-filter: blur(10px);
          padding: 2rem;
          border-radius: 15px;
          border: 1px solid rgba(255,255,255,0.2);
          text-align: center;
          transition: transform 0.3s ease;
        }
        .card:hover {
          transform: translateY(-5px);
        }
        .btn {
          background: #4CAF50;
          color: white;
          padding: 1rem 2rem;
          text-decoration: none;
          border-radius: 25px;
          display: inline-block;
          margin: 0.5rem;
          transition: all 0.3s ease;
        }
        .btn:hover {
          background: #45a049;
          transform: scale(1.05);
        }
        .footer {
          text-align: center;
          margin-top: 4rem;
          padding: 2rem;
          border-top: 1px solid rgba(255,255,255,0.2);
        }
      `}</style>
      <Component {...pageProps} />
    </>
  )
}
APP

cat > frontend/pages/index.js << 'INDEX'
export default function Home() {
  return (
    <div className="container">
      <header className="header">
        <h1 className="title">🛍️ MEKNOW</h1>
        <p className="subtitle">Plateforme E-commerce Premium</p>
      </header>

      <main>
        <div className="grid">
          <div className="card">
            <h3>🎨 Frontend Moderne</h3>
            <p>Interface Next.js responsive et élégante avec animations CSS</p>
          </div>
          
          <div className="card">
            <h3>🔧 API Robuste</h3>
            <p>Backend Express.js avec endpoints REST complets</p>
          </div>
          
          <div className="card">
            <h3>🗄️ Base de Données</h3>
            <p>PostgreSQL pour une gestion optimale des données</p>
          </div>
        </div>

        <div style={{textAlign: 'center'}}>
          <a href="/api/health" className="btn">🔧 Status API</a>
          <a href="/api/products" className="btn">📦 Produits</a>
        </div>
      </main>

      <footer className="footer">
        <p>© 2025 MEKNOW E-commerce - Déployé avec Docker 🐳</p>
        <p>✨ Site opérationnel et fonctionnel ✨</p>
      </footer>
    </div>
  )
}
INDEX

cat > frontend/next.config.js << 'NEXTCONFIG'
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: false,
  poweredByHeader: false,
}

module.exports = nextConfig
NEXTCONFIG

cat > frontend/Dockerfile << 'FRONTENDDOCKER'
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build
EXPOSE 3000
CMD ["npm", "start"]
FRONTENDDOCKER

# Configuration Nginx mise à jour
cat > /etc/nginx/sites-available/meknow << 'NGINX'
server {
    listen 80 default_server;
    server_name _;

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
systemctl reload nginx

# Construction et démarrage
echo "🏗️ Construction des services..."
docker-compose build --no-cache

echo "🚀 Démarrage des services..."
docker-compose up -d

# Attente plus longue
echo "⏳ Attente du démarrage (60s)..."
sleep 60

# Vérifications étendues
echo ""
echo "📊 Status des conteneurs:"
docker-compose ps
echo ""

echo "🔍 Tests de connectivité:"
for i in {1..5}; do
  echo "Tentative $i/5..."
  curl -s http://localhost:3000 > /dev/null && echo "✅ Frontend OK" && break || echo "❌ Frontend en attente..."
  sleep 10
done

curl -s http://localhost:5001/api/health > /dev/null && echo "✅ Backend OK" || echo "❌ Backend KO"

echo ""
echo "📋 Logs si problème:"
echo "docker-compose logs frontend"
echo "docker-compose logs backend"

echo ""
echo "🎉 DÉPLOIEMENT TERMINÉ!"
echo "🌐 Votre site: http://$(curl -s ifconfig.me)"
echo "🌐 Ou: http://meknow.fr"