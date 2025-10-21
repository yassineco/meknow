#!/bin/bash

# 🧹 Script de nettoyage VPS pour migration Docker
# Usage: ./cleanup-vps.sh

echo "🧹 NETTOYAGE VPS - Migration vers Docker"
echo "========================================"

# 1. Arrêter PM2 processes
echo "1. Arrêt des processus PM2..."
pm2 stop all
pm2 delete all
pm2 kill

# 2. Arrêter nginx si actif
echo "2. Arrêt de Nginx..."
sudo systemctl stop nginx
sudo systemctl disable nginx

# 3. Nettoyer les ports occupés
echo "3. Liberation des ports 3000, 9000..."
sudo fuser -k 3000/tcp || true
sudo fuser -k 9000/tcp || true
sudo fuser -k 80/tcp || true
sudo fuser -k 443/tcp || true

# 4. Nettoyer les processus Node.js
echo "4. Nettoyage des processus Node.js..."
pkill -f "node" || true
pkill -f "next" || true

# 5. Vérifier Docker
echo "5. Vérification Docker..."
if ! command -v docker &> /dev/null; then
    echo "❌ Docker non installé - Installation nécessaire"
    # Installation Docker
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose non installé - Installation nécessaire"
    # Installation Docker Compose
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# 6. Nettoyer les anciens containers si ils existent
echo "6. Nettoyage des anciens containers Docker..."
docker stop $(docker ps -aq) 2>/dev/null || true
docker rm $(docker ps -aq) 2>/dev/null || true
docker system prune -af

# 7. Vérifier les ports libérés
echo "7. Vérification des ports..."
echo "Ports occupés:"
netstat -tulpn | grep -E ':80|:443|:3000|:9000' || echo "Aucun port occupé"

echo "✅ Nettoyage VPS terminé!"
echo ""
echo "📋 Prochaines étapes:"
echo "1. Transférer les fichiers du projet"
echo "2. Configurer les variables d'environnement production"
echo "3. Déployer avec Docker"
echo "4. Configurer Nginx reverse proxy"
echo "5. Configurer SSL avec certbot"