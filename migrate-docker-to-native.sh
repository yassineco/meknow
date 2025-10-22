#!/bin/bash

# 🔄 Script de migration de Docker à déploiement natif
# Usage: sudo bash migrate-docker-to-native.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_PATH="/var/www/meknow"

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}🔄 Migration Docker → Natif${NC}"
echo -e "${BLUE}================================${NC}\n"

# Vérifier si on est en root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ Ce script doit être exécuté avec sudo${NC}"
    exit 1
fi

# 1. Nettoyage de Docker
echo -e "${YELLOW}[1/5] Nettoyage de la version Docker...${NC}"
bash $PROJECT_PATH/cleanup-docker-old.sh
echo -e "${GREEN}✅ Nettoyage Docker complété${NC}"

# 2. Mettre à jour le projet Git
echo -e "\n${YELLOW}[2/5] Mise à jour du projet...${NC}"
cd $PROJECT_PATH
git fetch origin
git pull origin main
echo -e "${GREEN}✅ Projet mis à jour${NC}"

# 3. Installer les dépendances natives
echo -e "\n${YELLOW}[3/5] Installation des dépendances...${NC}"
npm install --production

cd menow-web
npm install --production
npm run build
cd ..

echo -e "${GREEN}✅ Dépendances installées et frontend compilé${NC}"

# 4. Configuration systemd
echo -e "\n${YELLOW}[4/5] Configuration des services systemd...${NC}"

# Copier les fichiers de service
cp $PROJECT_PATH/meknow-api.service /etc/systemd/system/
cp $PROJECT_PATH/meknow-web.service /etc/systemd/system/

# Créer l'utilisateur www-data s'il n'existe pas
if ! id "www-data" &>/dev/null; then
    useradd -r -s /bin/bash www-data
fi

# Créer les répertoires de logs
mkdir -p /var/log/meknow
chown www-data:www-data /var/log/meknow

# Changer le propriétaire du projet
chown -R www-data:www-data $PROJECT_PATH

# Charger les nouveaux services
systemctl daemon-reload
systemctl enable meknow-api.service meknow-web.service

echo -e "${GREEN}✅ Services systemd configurés${NC}"

# 5. Démarrer les services
echo -e "\n${YELLOW}[5/5] Démarrage des services...${NC}"
systemctl start meknow-api meknow-web

# Vérifier le statut
sleep 3

if systemctl is-active --quiet meknow-api; then
    echo -e "${GREEN}✅ Backend démarré avec succès${NC}"
else
    echo -e "${RED}❌ Erreur au démarrage du backend${NC}"
    journalctl -u meknow-api -n 20
    exit 1
fi

if systemctl is-active --quiet meknow-web; then
    echo -e "${GREEN}✅ Frontend démarré avec succès${NC}"
else
    echo -e "${RED}❌ Erreur au démarrage du frontend${NC}"
    journalctl -u meknow-web -n 20
    exit 1
fi

# Résumé final
echo -e "\n${GREEN}================================${NC}"
echo -e "${GREEN}✅ Migration terminée avec succès!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo -e "${BLUE}📊 Statut des services:${NC}"
systemctl status meknow-api --no-pager | grep -E "Active|since"
systemctl status meknow-web --no-pager | grep -E "Active|since"
echo ""
echo -e "${BLUE}🔗 Accès:${NC}"
echo "Frontend: http://localhost:3000"
echo "API: http://localhost:9000/api/products"
echo "Admin: http://localhost:9000/admin"
echo ""
echo -e "${BLUE}📋 Commandes utiles:${NC}"
echo "Voir les logs: sudo journalctl -u meknow-api -f"
echo "            sudo journalctl -u meknow-web -f"
echo "Redémarrer: sudo systemctl restart meknow-api meknow-web"
echo "Arrêter: sudo systemctl stop meknow-api meknow-web"
echo ""
echo -e "${YELLOW}ℹ️  Les conteneurs Docker ont été complètement supprimés${NC}"
echo -e "${YELLOW}ℹ️  Le projet tourne maintenant en natif sur le VPS${NC}"
