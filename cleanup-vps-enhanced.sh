#!/bin/bash

# 🧹 Script de nettoyage VPS AVANCÉ - MEKNOW
# Nettoie complètement l'ancien déploiement natif

echo "🧹 NETTOYAGE VPS COMPLET - MIGRATION VERS DOCKER"
echo "================================================"

# Fonction de log
log() { echo "[$(date '+%H:%M:%S')] $1"; }

# 1. ARRÊT PM2 COMPLET
log "🛑 Arrêt de tous les processus PM2..."
if command -v pm2 &> /dev/null; then
    pm2 stop all 2>/dev/null || true
    pm2 delete all 2>/dev/null || true  
    pm2 kill 2>/dev/null || true
    log "✅ PM2 arrêté"
else
    log "ℹ️  PM2 non installé"
fi

# 2. LIBÉRATION DES PORTS CRITIQUES
log "🔓 Libération des ports critiques..."
for port in 80 443 3000 9000 5432; do
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        log "🔧 Port $port occupé - libération..."
        sudo fuser -k $port/tcp 2>/dev/null || true
        sleep 1
    fi
done

# 3. NETTOYAGE PROCESSUS NODE
log "🔄 Nettoyage des processus Node.js..."
pkill -f "node.*backend-minimal" 2>/dev/null || true  
pkill -f "next.*dev\|next.*start" 2>/dev/null || true
pkill -f "npm.*start" 2>/dev/null || true
sleep 2

# 4. ARRÊT NGINX SI ACTIF
log "🌐 Gestion Nginx..."
if systemctl is-active --quiet nginx 2>/dev/null; then
    log "🔧 Nginx actif - configuration..."
    sudo systemctl stop nginx || true
else
    log "ℹ️  Nginx non actif"
fi

# 5. NETTOYAGE DOCKER ANCIEN
log "🐳 Nettoyage Docker existant..."
if command -v docker &> /dev/null; then
    # Arrêter tous les containers
    docker stop $(docker ps -aq) 2>/dev/null || true
    docker rm $(docker ps -aq) 2>/dev/null || true
    # Nettoyer les images inutilisées
    docker system prune -f 2>/dev/null || true
    log "✅ Docker nettoyé"
else
    log "⚠️  Docker non installé - installation nécessaire"
fi

# 6. VÉRIFICATIONS FINALES
log "🔍 Vérifications post-nettoyage..."
echo "Ports encore occupés:"
netstat -tulpn 2>/dev/null | grep -E ':80|:443|:3000|:9000|:5432' || echo "✅ Tous les ports libérés"

echo "Processus Node restants:"
pgrep -f "node" | wc -l | xargs -I {} echo "{} processus Node détectés"

log "✅ NETTOYAGE VPS TERMINÉ!"
echo ""
echo "📋 Prochaines étapes:"
echo "1. Cloner le projet depuis GitHub" 
echo "2. Installer Docker si nécessaire"
echo "3. Configurer l'environnement production"
echo "4. Déployer avec docker-compose"
echo "5. Configurer Nginx reverse proxy"
echo "6. Activer SSL avec certbot"
