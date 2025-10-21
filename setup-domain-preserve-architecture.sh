#!/bin/bash

# 🌐 CONFIGURATION DOMAINE POUR ARCHITECTURE MEKNOW EXISTANTE
# Préserve l'architecture Express.js + Next.js + Admin existante

echo "🌐 CONFIGURATION DOMAINE MEKNOW.FR - PRÉSERVATION ARCHITECTURE EXISTANTE..."

PROJECT_DIR="/var/www/meknow"
cd $PROJECT_DIR

# Étape 1: Vérifier l'architecture existante
echo "🔍 Vérification de l'architecture existante..."

if [ -f "backend-v2.js" ]; then
    echo "✅ Backend Express.js détecté: backend-v2.js"
fi

if [ -d "menow-web" ]; then
    echo "✅ Frontend Next.js détecté: menow-web/"
fi

if [ -f "admin-complete-ecommerce.html" ]; then
    echo "✅ Interface Admin détectée: admin-complete-ecommerce.html"
fi

# Étape 2: Configuration Nginx pour architecture existante
echo "📝 Configuration Nginx pour domaine avec architecture existante..."

cat > nginx-production.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    
    # Configuration pour MEKNOW E-commerce
    upstream frontend {
        server 31.97.196.215:3001;
    }
    
    upstream backend {
        server 31.97.196.215:9001;
    }
    
    upstream admin {
        server 31.97.196.215:8082;
    }
    
    # Redirection HTTP vers HTTPS (futur)
    server {
        listen 80;
        server_name meknow.fr www.meknow.fr;
        
        # Temporaire : servir directement le contenu
        location / {
            proxy_pass http://frontend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
        
        # API Backend
        location /api/ {
            proxy_pass http://backend/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
        
        # Interface Admin
        location /admin {
            proxy_pass http://admin;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
        
        # Static assets
        location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            proxy_pass http://frontend;
        }
    }
}
EOF

echo "✅ Configuration Nginx créée pour domaine"

# Étape 3: Mise à jour docker-compose pour domaine
echo "🔄 Adaptation docker-compose.yml pour domaine..."

# Sauvegarder l'ancien
cp docker-compose.yml docker-compose.yml.backup

# Ajouter Nginx avec configuration domaine
cat >> docker-compose.yml << 'EOF'

  # Nginx Reverse Proxy pour domaine
  nginx:
    image: nginx:alpine
    container_name: meknow-nginx-domain
    restart: unless-stopped
    ports:
      - "80:80"
    volumes:
      - ./nginx-production.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - frontend
      - backend
      - admin
    networks:
      - meknow-network
EOF

echo "✅ Docker-compose adapté pour domaine"

# Étape 4: Instructions DNS Hostinger
echo ""
echo "🌍 CONFIGURATION DNS HOSTINGER REQUISE:"
echo "┌─────────────────────────────────────────────────────────────┐"
echo "│  Dans votre panel Hostinger DNS :                          │"
echo "│                                                             │"
echo "│  Type: A                                                    │"
echo "│  Nom: @                                                     │" 
echo "│  Valeur: 31.97.196.215                                      │"
echo "│  TTL: 14400                                                 │"
echo "│                                                             │"
echo "│  Type: A                                                    │"
echo "│  Nom: www                                                   │"
echo "│  Valeur: 31.97.196.215                                      │"
echo "│  TTL: 14400                                                 │"
echo "└─────────────────────────────────────────────────────────────┘"

# Étape 5: Test de connectivité
echo ""
echo "🔍 Test de connectivité vers votre VPS..."
if ping -c 1 31.97.196.215 >/dev/null 2>&1; then
    echo "✅ VPS accessible (31.97.196.215)"
else
    echo "⚠️  VPS non accessible - vérifiez la connectivité"
fi

# Étape 6: Redémarrage avec Nginx
echo ""
echo "🚀 Démarrage de l'architecture complète avec domaine..."
docker-compose down 2>/dev/null || true
docker-compose up -d --build

sleep 10

# Étape 7: Vérification des services
echo ""
echo "📊 VÉRIFICATION DES SERVICES:"
docker-compose ps

echo ""
echo "🎯 URLS DE VOTRE SITE E-COMMERCE:"
echo "┌─────────────────────────────────────────────────────────────┐"
echo "│  🌐 Site Principal: http://meknow.fr (après DNS)            │"
echo "│  🔗 Temporaire IP:  http://31.97.196.215                   │"
echo "│  🛠️  Interface Admin: http://meknow.fr/admin                │"
echo "│  ⚡ API Backend:    http://meknow.fr/api                   │"
echo "└─────────────────────────────────────────────────────────────┘"

echo ""
echo "✅ CONFIGURATION DOMAINE TERMINÉE !"
echo "📋 Configurez maintenant le DNS dans Hostinger avec les valeurs ci-dessus"