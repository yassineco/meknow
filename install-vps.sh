#!/bin/bash

# 🚀 Installation rapide MEKNOW sur VPS via GitHub
# Usage: curl -fsSL https://raw.githubusercontent.com/yassineco/meknow/main/install-vps.sh | bash

set -e

echo "🛍️  ███╗   ███╗███████╗██╗  ██╗███╗   ██╗ ██████╗ ██╗    ██╗"
echo "   ████╗ ████║██╔════╝██║ ██╔╝████╗  ██║██╔═══██╗██║    ██║"
echo "   ██╔████╔██║█████╗  █████╔╝ ██╔██╗ ██║██║   ██║██║ █╗ ██║"
echo "   ██║╚██╔╝██║██╔══╝  ██╔═██╗ ██║╚██╗██║██║   ██║██║███╗██║"
echo "   ██║ ╚═╝ ██║███████╗██║  ██╗██║ ╚████║╚██████╔╝╚███╔███╔╝"
echo "   ╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝  ╚══╝╚══╝ "
echo ""
echo "🚀 INSTALLATION VPS AUTOMATIQUE - Version Docker 2.0.0"
echo "======================================================="

# Variables
PROJECT_DIR="/var/www/meknow"
DOMAIN="meknow.fr"

echo "1. 🧹 Nettoyage de l'ancienne installation..."

# Arrêter PM2 si actif
if command -v pm2 &> /dev/null; then
    pm2 stop all 2>/dev/null || true
    pm2 delete all 2>/dev/null || true
    pm2 kill 2>/dev/null || true
fi

# Libérer les ports
sudo fuser -k 3000/tcp 2>/dev/null || true
sudo fuser -k 9000/tcp 2>/dev/null || true
sudo fuser -k 80/tcp 2>/dev/null || true

# Nettoyer les processus Node
pkill -f "node" 2>/dev/null || true
pkill -f "next" 2>/dev/null || true

echo "2. 🐳 Installation Docker si nécessaire..."

# Installer Docker
if ! command -v docker &> /dev/null; then
    echo "Installation Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
fi

# Installer Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "Installation Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

echo "3. 📦 Clonage du projet depuis GitHub..."

# Créer le dossier et cloner
sudo mkdir -p $PROJECT_DIR
sudo chown $USER:$USER $PROJECT_DIR
cd $PROJECT_DIR

# Cloner ou mettre à jour
if [ -d ".git" ]; then
    git fetch origin
    git reset --hard origin/main
else
    git clone https://github.com/yassineco/meknow.git .
fi

echo "4. ⚙️  Configuration de l'environnement production..."

# Créer .env.production pour VPS
cat > .env.production << 'EOL'
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
JWT_SECRET=meknow_prod_jwt_2024_ultra_secure_key_vps
BCRYPT_ROUNDS=12
EOL

echo "5. 🔧 Configuration Nginx..."

# Configuration Nginx pour le domaine
sudo tee /etc/nginx/sites-available/meknow.fr > /dev/null << 'EOL'
server {
    listen 80;
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
    }
    
    # API Backend
    location /api/ {
        proxy_pass http://127.0.0.1:9001/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;  
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Interface Admin  
    location /admin {
        proxy_pass http://127.0.0.1:8082;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for; 
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOL

# Activer le site
sudo ln -sf /etc/nginx/sites-available/meknow.fr /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

echo "6. 🚀 Déploiement Docker..."

# Nettoyer les anciens containers  
docker stop $(docker ps -aq) 2>/dev/null || true
docker rm $(docker ps -aq) 2>/dev/null || true

# Modifier les ports pour éviter les conflits
sed -i 's/"3000:3000"/"3001:3000"/g' docker-compose.yml
sed -i 's/"9000:9000"/"9001:9000"/g' docker-compose.yml  
sed -i 's/"5432:5432"/"5433:5432"/g' docker-compose.yml

# Déployer avec Docker Compose
docker-compose --env-file .env.production up -d --build

echo "7. 🔒 Configuration SSL..."

# Installer certbot si nécessaire
if ! command -v certbot &> /dev/null; then
    sudo apt update
    sudo apt install -y certbot python3-certbot-nginx
fi

# Configurer SSL
sudo certbot --nginx -d meknow.fr -d www.meknow.fr --non-interactive --agree-tos --email admin@meknow.fr --redirect

echo "8. ✅ Vérifications finales..."

sleep 10

echo "Services Docker:"
docker-compose ps

echo ""  
echo "Test de connectivité:"
curl -s http://localhost:9001/health && echo " ✅ Backend OK"
curl -s -I http://localhost:3001/ | head -n1 | grep "200" && echo "✅ Frontend OK"
curl -s -I http://localhost:8082/ | head -n1 | grep "200" && echo "✅ Admin OK"

echo ""
echo "🎉 INSTALLATION TERMINÉE AVEC SUCCÈS!"
echo ""
echo "🌐 Votre site est accessible sur:"
echo "   Frontend: https://meknow.fr"  
echo "   Admin:    https://meknow.fr/admin"
echo "   API:      https://meknow.fr/api"
echo ""
echo "📊 Services Docker actifs:"
echo "   - Frontend Next.js: port 3001"
echo "   - Backend API: port 9001" 
echo "   - Interface Admin: port 8082"
echo "   - PostgreSQL: port 5433"
echo ""
echo "🛍️ Votre e-commerce MEKNOW est maintenant opérationnel!"