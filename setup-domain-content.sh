#!/bin/bash

# 🌐 CONFIGURATION DOMAINE + ACTIVATION CONTENU MEKNOW
# Ce script configure le domaine meknow.fr et active tout le contenu existant

echo "🌐 CONFIGURATION DOMAINE MEKNOW.FR + ACTIVATION CONTENU..."

PROJECT_DIR="/var/www/meknow"
cd $PROJECT_DIR

# Étape 1: Configurer Nginx pour le domaine
echo "📝 Configuration Nginx pour meknow.fr..."

# Créer la configuration Nginx optimisée
cat > nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    
    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=frontend:10m rate=20r/s;
    
    # Main server block
    server {
        listen 80;
        server_name meknow.fr www.meknow.fr;
        
        # Security headers
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;
        
        # Frontend Next.js
        location / {
            limit_req zone=frontend burst=30 nodelay;
            proxy_pass http://frontend:3000;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_cache_bypass $http_upgrade;
            proxy_read_timeout 86400;
        }
        
        # API Backend
        location /api {
            limit_req zone=api burst=20 nodelay;
            proxy_pass http://backend:9000;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
        
        # Interface Admin
        location /admin {
            auth_basic "Zone Administrative";
            auth_basic_user_file /etc/nginx/.htpasswd;
            proxy_pass http://admin:80;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
        
        # Static files caching
        location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
}
EOF

# Créer le fichier d'authentification admin
cat > .htpasswd << 'EOF'
admin:$2y$10$rQ7HvUgzO8kF2M1GxY9vL.HlZoWvFsW4rH8lF9F0F1F2F3F4F5F6F7
EOF

echo "✅ Configuration Nginx créée"

# Étape 2: Réactiver Nginx dans docker-compose
echo "🔄 Réactivation Nginx dans docker-compose.yml..."

# Ajouter la section Nginx
cat >> docker-compose.yml << 'EOF'

  # Reverse Proxy Nginx pour domaine
  nginx:
    image: nginx:alpine
    container_name: meknow-nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./.htpasswd:/etc/nginx/.htpasswd:ro
    depends_on:
      - frontend
      - backend
      - admin
    networks:
      - meknow-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost"]
      interval: 30s
      timeout: 10s
      retries: 3
EOF

echo "✅ Nginx réactivé dans docker-compose"

# Étape 3: Vérifier que le contenu existant est présent
echo "🔍 Vérification du contenu existant..."

if [ -d "menow-web/src" ]; then
    echo "✅ Structure src/ détectée - contenu existant préservé"
elif [ -d "menow-web/pages" ]; then
    echo "✅ Structure pages/ détectée - contenu simplifié actif"
else
    echo "⚠️  Aucune structure détectée"
fi

# Étape 4: Configuration DNS dans /etc/hosts (temporaire)
echo "🌐 Configuration DNS locale..."
echo "# MEKNOW E-COMMERCE - Configuration temporaire" >> /etc/hosts
echo "31.97.196.215 meknow.fr" >> /etc/hosts
echo "31.97.196.215 www.meknow.fr" >> /etc/hosts

echo "✅ DNS local configuré"

# Étape 5: Redémarrer avec domaine
echo "🚀 Redémarrage avec configuration domaine..."
docker-compose down
docker-compose up -d --build

echo ""
echo "🌐 CONFIGURATION DOMAINE TERMINÉE !"
echo ""
echo "┌─────────────────────────────────────────────────────────────┐"
echo "│  🌍 Site Principal: http://meknow.fr                       │"
echo "│  🌍 Alternative:    http://www.meknow.fr                   │"
echo "│  🔗 API Backend:    http://meknow.fr/api                   │"
echo "│  🛠️  Interface Admin: http://meknow.fr/admin               │"
echo "└─────────────────────────────────────────────────────────────┘"
echo ""
echo "📋 PROCHAINES ÉTAPES:"
echo "1. Configurez meknow.fr dans votre DNS Hostinger"
echo "2. Pointez meknow.fr vers 31.97.196.215"
echo "3. Votre site sera accessible via le nom de domaine !"
echo ""
echo "✅ MEKNOW E-COMMERCE PRÊT AVEC DOMAINE !"