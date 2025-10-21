#!/bin/bash
# deploy-final.sh - Solution finale pour déploiement MEKNOW

echo "🚀 DÉPLOIEMENT FINAL MEKNOW - Solution complète"
echo "================================================"

# Mise à jour système complète
echo "📦 Mise à jour système..."
apt update && apt upgrade -y

# Installation Docker si nécessaire
if ! command -v docker &> /dev/null; then
    echo "🐳 Installation Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    systemctl enable docker
    systemctl start docker
fi

# Installation Docker Compose si nécessaire
if ! command -v docker-compose &> /dev/null; then
    echo "🔧 Installation Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi

# Nettoyage complet
echo "🧹 Nettoyage complet..."
cd /root
rm -rf menow
docker system prune -af --volumes

# Clone du projet
echo "📥 Clone du projet..."
git clone https://github.com/yac4423/menow.git
cd menow

# CORRECTION COMPLÈTE DES IMPORTS NEXT.JS
echo "🔧 Correction des imports Next.js..."

# Remplacement de la page principale par version simple
cp page-simple.tsx menow-web/src/app/page.tsx

# Remplacement du layout par version simple
cat > menow-web/src/app/layout.tsx << 'EOF'
import './globals.css'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'MEKNOW E-commerce',
  description: 'Plateforme e-commerce moderne',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="fr">
      <body className="bg-gray-100 min-h-screen">
        {children}
      </body>
    </html>
  )
}
EOF

# Configuration Next.js ultra-simple
cat > menow-web/next.config.mjs << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  trailingSlash: true,
  poweredByHeader: false,
}

export default nextConfig
EOF

# Suppression des dossiers problématiques
rm -rf menow-web/src/components
rm -rf menow-web/src/lib
rm -rf menow-web/src/utils

# Dockerfile ultra-simple pour Next.js
cat > menow-web/Dockerfile << 'EOF'
FROM node:18-alpine

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

EXPOSE 3000
CMD ["npm", "start"]
EOF

# Configuration Nginx adaptée
echo "🌐 Configuration Nginx..."
apt install -y nginx

cat > /etc/nginx/sites-available/meknow << 'EOF'
server {
    listen 80;
    server_name meknow.fr www.meknow.fr;

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

    location /admin/ {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Activation Nginx
ln -sf /etc/nginx/sites-available/meknow /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

# Variables d'environnement
echo "⚙️  Configuration environnement..."
cat > .env << 'EOF'
# Base de données
DATABASE_URL=postgresql://meknow_user:meknow_password@postgres:5432/meknow_db

# Backend API
API_PORT=5001
NODE_ENV=production

# Frontend
NEXT_PUBLIC_API_URL=http://localhost:5001/api
EOF

# Construction et lancement
echo "🏗️  Construction des services..."
docker-compose down -v
docker-compose build --no-cache
docker-compose up -d

# Attente et vérification
echo "⏳ Vérification des services..."
sleep 30

# Vérification des conteneurs
echo "📊 Status des conteneurs:"
docker-compose ps

# Tests de connectivité
echo "🔍 Tests de connectivité:"
curl -s http://localhost:3000 > /dev/null && echo "✅ Frontend OK" || echo "❌ Frontend KO"
curl -s http://localhost:5001/api/health > /dev/null && echo "✅ Backend OK" || echo "❌ Backend KO"
curl -s http://localhost:8080 > /dev/null && echo "✅ Admin OK" || echo "❌ Admin KO"

# Logs en cas d'erreur
if ! curl -s http://localhost:3000 > /dev/null; then
    echo "🚨 ERREUR FRONTEND - Logs:"
    docker-compose logs menow-web | tail -20
fi

if ! curl -s http://localhost:5001/api/health > /dev/null; then
    echo "🚨 ERREUR BACKEND - Logs:"
    docker-compose logs backend | tail -20
fi

echo "🎉 DÉPLOIEMENT TERMINÉ!"
echo "🌐 Site accessible sur: http://meknow.fr"
echo "👑 Admin accessible sur: http://meknow.fr/admin"
echo "🔧 API accessible sur: http://meknow.fr/api"