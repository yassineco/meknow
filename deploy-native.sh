#!/bin/bash

# 🚀 Script de déploiement natif pour Meknow E-commerce
# Usage: ./deploy-native.sh [production|staging]

set -e

ENVIRONMENT=${1:-production}
PROJECT_PATH="/var/www/meknow"
API_PORT=9000
WEB_PORT=3000
LOG_DIR="/var/log/meknow"

# Couleurs pour l'output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}🚀 Déploiement Natif - Meknow${NC}"
echo -e "${BLUE}Environnement: $ENVIRONMENT${NC}"
echo -e "${BLUE}================================${NC}\n"

# 1. Vérifier les prérequis
echo -e "${YELLOW}[1/6] Vérification des prérequis...${NC}"
command -v node >/dev/null 2>&1 || { echo -e "${RED}❌ Node.js n'est pas installé${NC}"; exit 1; }
command -v npm >/dev/null 2>&1 || { echo -e "${RED}❌ npm n'est pas installé${NC}"; exit 1; }
command -v psql >/dev/null 2>&1 || { echo -e "${RED}❌ PostgreSQL n'est pas installé${NC}"; exit 1; }

echo -e "${GREEN}✅ Node.js $(node --version)${NC}"
echo -e "${GREEN}✅ npm $(npm --version)${NC}"
echo -e "${GREEN}✅ PostgreSQL $(psql --version | cut -d' ' -f3)${NC}"

# 2. Créer les répertoires de logs
echo -e "\n${YELLOW}[2/6] Préparation des répertoires...${NC}"
sudo mkdir -p $LOG_DIR
sudo chown $(whoami):$(whoami) $LOG_DIR
echo -e "${GREEN}✅ Répertoires logs créés${NC}"

# 3. Cloner/mettre à jour le projet
echo -e "\n${YELLOW}[3/6] Mise à jour du projet...${NC}"
if [ ! -d "$PROJECT_PATH" ]; then
    echo "Clonage du projet..."
    sudo mkdir -p $(dirname $PROJECT_PATH)
    sudo git clone https://github.com/yassineco/meknow.git $PROJECT_PATH
    sudo chown -R $(whoami):$(whoami) $PROJECT_PATH
fi

cd $PROJECT_PATH
git pull origin main
echo -e "${GREEN}✅ Projet mis à jour${NC}"

# 4. Installer les dépendances
echo -e "\n${YELLOW}[4/6] Installation des dépendances...${NC}"
npm install --production
cd menow-web
npm install --production
npm run build
cd ..
echo -e "${GREEN}✅ Dépendances installées${NC}"

# 5. Configurer les variables d'environnement
echo -e "\n${YELLOW}[5/6] Configuration des variables d'environnement...${NC}"
if [ ! -f ".env" ]; then
    echo "Créez le fichier .env avec les variables suivantes:"
    cat > .env.example << 'EOF'
NODE_ENV=production
PORT=9000
API_URL=http://localhost:9000
NEXT_PUBLIC_API_URL=http://localhost:9000

DB_HOST=localhost
DB_PORT=5432
DB_NAME=meknow_production
DB_USER=meknow_user
DB_PASSWORD=your_secure_password
JWT_SECRET=your_jwt_secret

NEXT_PUBLIC_BASE_URL=https://yourdomain.com
EOF
    echo -e "${RED}⚠️  Fichier .env.example créé. Veuillez créer .env et configurer les variables${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Variables d'environnement configurées${NC}"

# 6. Vérifier la base de données
echo -e "\n${YELLOW}[6/6] Vérification de la base de données...${NC}"
if ! psql -h localhost -U $(grep DB_USER .env | cut -d'=' -f2) -d $(grep DB_NAME .env | cut -d'=' -f2) -c "SELECT 1" >/dev/null 2>&1; then
    echo -e "${RED}❌ Impossible de se connecter à la base de données${NC}"
    echo "Créez la base de données:"
    echo "  sudo -u postgres psql"
    echo "  CREATE USER meknow_user WITH PASSWORD 'password';"
    echo "  CREATE DATABASE meknow_production OWNER meknow_user;"
    exit 1
fi
echo -e "${GREEN}✅ Base de données accessible${NC}"

# Installation de PM2 (optionnel)
echo -e "\n${YELLOW}Installation de PM2...${NC}"
npm install -g pm2 2>/dev/null || true

echo -e "\n${GREEN}================================${NC}"
echo -e "${GREEN}✅ Déploiement préparé avec succès!${NC}"
echo -e "${GREEN}================================${NC}"
echo -e "\nPour démarrer les services:\n"
echo -e "${BLUE}Option 1 - Avec PM2 (Recommandé):${NC}"
echo "  pm2 start ecosystem.config.js --env $ENVIRONMENT"
echo "  pm2 save"
echo ""
echo -e "${BLUE}Option 2 - Avec systemd:${NC}"
echo "  sudo systemctl start meknow-api"
echo "  sudo systemctl start meknow-web"
echo ""
echo -e "${BLUE}Option 3 - Manuellement:${NC}"
echo "  Terminal 1: npm run api"
echo "  Terminal 2: npm run web"
