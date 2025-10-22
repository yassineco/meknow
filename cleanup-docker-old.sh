#!/bin/bash

# 🧹 Script de nettoyage VPS - Suppression de la version Docker précédente
# Usage: sudo bash cleanup-docker-old.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}🧹 Nettoyage VPS - Suppression Docker${NC}"
echo -e "${BLUE}================================${NC}\n"

# Vérifier si on est en root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ Ce script doit être exécuté avec sudo${NC}"
    exit 1
fi

# 1. Arrêter les conteneurs Docker
echo -e "${YELLOW}[1/7] Arrêt des conteneurs Docker...${NC}"
docker-compose -f /var/www/meknow/docker-compose.yml down 2>/dev/null || true
docker stop $(docker ps -a -q) 2>/dev/null || true
echo -e "${GREEN}✅ Conteneurs arrêtés${NC}"

# 2. Supprimer les images Docker
echo -e "\n${YELLOW}[2/7] Suppression des images Docker...${NC}"
docker rmi $(docker images -a -q) -f 2>/dev/null || true
echo -e "${GREEN}✅ Images Docker supprimées${NC}"

# 3. Nettoyer les volumes Docker
echo -e "\n${YELLOW}[3/7] Nettoyage des volumes Docker...${NC}"
docker volume rm $(docker volume ls -q) 2>/dev/null || true
docker system prune -a -f 2>/dev/null || true
echo -e "${GREEN}✅ Volumes nettoyés${NC}"

# 4. Supprimer les services PM2/systemd anciens
echo -e "\n${YELLOW}[4/7] Suppression des anciens services...${NC}"

# PM2
pm2 delete all 2>/dev/null || true
pm2 kill 2>/dev/null || true

# systemd (anciennes configurations)
systemctl stop meknow-api meknow-web 2>/dev/null || true
systemctl disable meknow-api meknow-web 2>/dev/null || true
rm -f /etc/systemd/system/meknow-*.service
systemctl daemon-reload 2>/dev/null || true

echo -e "${GREEN}✅ Anciens services supprimés${NC}"

# 5. Nettoyer les fichiers temporaires
echo -e "\n${YELLOW}[5/7] Nettoyage des fichiers temporaires...${NC}"

# Supprimer les anciens fichiers de cache Docker
rm -rf /var/lib/docker/containers/* 2>/dev/null || true
rm -rf /var/lib/docker/volumes/* 2>/dev/null || true

# Supprimer les fichiers node_modules anciens
find /var/www/meknow -type d -name node_modules -exec rm -rf {} + 2>/dev/null || true
find /var/www/meknow -type d -name .next -exec rm -rf {} + 2>/dev/null || true
find /var/www/meknow -type d -name dist -exec rm -rf {} + 2>/dev/null || true

# Nettoyer les logs
rm -f /var/log/meknow/*.log 2>/dev/null || true

echo -e "${GREEN}✅ Fichiers temporaires supprimés${NC}"

# 6. Nettoyer les ports
echo -e "\n${YELLOW}[6/7] Libération des ports...${NC}"

# Tuer les processus sur les ports 3000, 9000, 5432, 80, 443
for port in 3000 9000 5432; do
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo "Libération du port $port..."
        kill -9 $(lsof -t -i :$port) 2>/dev/null || true
    fi
done

echo -e "${GREEN}✅ Ports libérés${NC}"

# 7. Nettoyer les dossiers et fichiers de déploiement anciens
echo -e "\n${YELLOW}[7/7] Nettoyage des fichiers de déploiement...${NC}"

# Sauvegarder les fichiers importants
if [ -f /var/www/meknow/.env ]; then
    cp /var/www/meknow/.env /root/.env.backup.$(date +%s)
    echo "📌 Fichier .env sauvegardé"
fi

if [ -f /var/www/meknow/menow-web/.env.local ]; then
    cp /var/www/meknow/menow-web/.env.local /root/.env.local.backup.$(date +%s)
    echo "📌 Fichier menow-web/.env.local sauvegardé"
fi

# Supprimer les anciens fichiers Docker
rm -f /var/www/meknow/docker-compose.yml.bak
rm -f /var/www/meknow/Dockerfile.*
rm -f /var/www/meknow/menow-web/Dockerfile
rm -f /var/www/meknow/.dockerignore
rm -f /var/www/meknow/menow-web/.dockerignore

# Supprimer les anciens scripts de déploiement Docker
rm -f /var/www/meknow/deploy-*.sh
rm -f /var/www/meknow/docker-*.sh
rm -f /var/www/meknow/*docker*.sh

echo -e "${GREEN}✅ Fichiers de déploiement Docker supprimés${NC}"

# 8. Afficher l'espace disque libéré
echo -e "\n${YELLOW}Espace disque après nettoyage:${NC}"
df -h /var/www

# Afficher le résumé
echo -e "\n${GREEN}================================${NC}"
echo -e "${GREEN}✅ Nettoyage terminé!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo -e "${BLUE}Prochaines étapes:${NC}"
echo "1. Vérifier que PostgreSQL fonctionne: sudo systemctl status postgresql"
echo "2. Vérifier les ports libres: sudo lsof -i -P -n | grep LISTEN"
echo "3. Mettre à jour le projet: cd /var/www/meknow && git pull origin main"
echo "4. Installer les dépendances: npm install --production"
echo "5. Lancer le déploiement natif: bash deploy-native.sh"
echo ""
echo -e "${YELLOW}Fichiers de sauvegarde (.env):${NC}"
ls -la /root/.env*.backup.* 2>/dev/null || echo "Aucune sauvegarde"
