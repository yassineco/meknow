#!/bin/bash

# 🚀 Script de déploiement VPS Docker pour MEKNOW
# Usage: ./deploy-vps-docker.sh

echo "🚀 DÉPLOIEMENT VPS DOCKER - MEKNOW E-COMMERCE"
echo "=============================================="

# Configuration
DOMAIN="meknow.fr"
PROJECT_DIR="/var/www/meknow"
BACKUP_DIR="/var/backups/meknow"

# 1. Créer les dossiers nécessaires
echo "1. Création des dossiers..."
sudo mkdir -p $PROJECT_DIR
sudo mkdir -p $BACKUP_DIR
sudo mkdir -p /var/log/meknow

# 2. Créer le fichier .env.production pour VPS
echo "2. Configuration environnement production..."
cat > $PROJECT_DIR/.env.production << 'EOL'
# Configuration production VPS
NODE_ENV=production

# Base de données PostgreSQL
DATABASE_URL=postgresql://postgres:meknow2024!@database:5432/meknow_production
DB_HOST=database
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=meknow2024!
DB_NAME=meknow_production

# API Configuration
API_URL=http://backend:9000
NEXT_PUBLIC_API_URL=https://meknow.fr/api

# Rubriques Management
ENABLE_RUBRIQUES=true
CATALOGUE_ENABLED=true
LOOKBOOK_ENABLED=true

# Sécurité
JWT_SECRET=meknow_production_jwt_secret_2024_secure_key
BCRYPT_ROUNDS=12

# Uploads et stockage
UPLOAD_PATH=/app/uploads
MAX_FILE_SIZE=10485760
ALLOWED_EXTENSIONS=jpg,jpeg,png,webp,gif

# Logs
LOG_LEVEL=info
LOG_FILE=/var/log/meknow/application.log
EOL

# 3. Créer la configuration Nginx pour production
echo "3. Configuration Nginx production..."
sudo tee /etc/nginx/sites-available/meknow.fr << 'EOL'
# Configuration Nginx pour MEKNOW E-commerce
server {
    listen 80;
    server_name meknow.fr www.meknow.fr;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name meknow.fr www.meknow.fr;

    # Frontend Next.js
    location / {
        proxy_pass http://127.0.0.1:3001;
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
    location /api/ {
        proxy_pass http://127.0.0.1:9001/api/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 30s;
    }

    # Interface Admin
    location /admin {
        proxy_pass http://127.0.0.1:8082;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Logs
    access_log /var/log/nginx/meknow.access.log;
    error_log /var/log/nginx/meknow.error.log;
}
EOL

# 4. Déployer avec Docker
echo "4. Déploiement Docker..."
cd $PROJECT_DIR
docker-compose -f docker-compose.yml --env-file .env.production up -d --build

# 5. Configurer SSL avec certbot
echo "5. Configuration SSL..."
sudo certbot --nginx -d meknow.fr -d www.meknow.fr --non-interactive --agree-tos --email admin@meknow.fr

echo "✅ DÉPLOIEMENT VPS TERMINÉ!"
echo "🌐 Site accessible: https://meknow.fr"