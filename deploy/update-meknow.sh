#!/bin/bash

# 🔄 Script de mise à jour rapide pour Meknow
# Usage: bash update-meknow.sh

set -e

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

APP_DIR="/var/www/meknow"
DEPLOY_USER="deploy"

log_info "🔄 Début de la mise à jour Meknow"

# Vérifier que nous sommes dans le bon répertoire
if [ ! -d "$APP_DIR" ]; then
    echo "Erreur: Répertoire $APP_DIR non trouvé"
    exit 1
fi

cd $APP_DIR

# Sauvegarder la base de données
log_info "💾 Sauvegarde de la base de données..."
sudo -u postgres pg_dump meknow_production > backup_before_update_$(date +%Y%m%d_%H%M%S).sql

# Arrêter les services
log_info "⏹️ Arrêt des services..."
sudo -u $DEPLOY_USER pm2 stop all

# Mettre à jour le code
log_info "📥 Récupération des dernières modifications..."
git fetch --all
git reset --hard origin/main
git pull origin main

# Mettre à jour les dépendances si package.json a changé
if git diff HEAD~1 HEAD --name-only | grep -q "package.json"; then
    log_info "📦 Mise à jour des dépendances..."
    npm install --production
    
    if [ -d "menow-web" ]; then
        cd menow-web
        npm install --production
        cd ..
    fi
fi

# Rebuilder le frontend si nécessaire
if [ -d "menow-web" ] && (git diff HEAD~1 HEAD --name-only | grep -q "menow-web/" || git diff HEAD~1 HEAD --name-only | grep -q "package.json"); then
    log_info "🏗️ Rebuild du frontend..."
    cd menow-web
    npm run build
    cd ..
fi

# Appliquer les migrations de base de données si elles existent
if [ -f "migrations.sql" ]; then
    log_info "🐘 Application des migrations..."
    sudo -u postgres psql meknow_production -f migrations.sql
fi

# Redémarrer les services
log_info "🚀 Redémarrage des services..."
sudo -u $DEPLOY_USER pm2 restart all

# Attendre que les services soient prêts
sleep 5

# Vérifier la santé des services
log_info "🧪 Vérification des services..."
if curl -s http://localhost:9000/health > /dev/null; then
    log_success "✅ Backend: OK"
else
    echo "⚠️ Backend: Problème détecté"
fi

if curl -s http://localhost:5000 > /dev/null; then
    log_success "✅ Frontend: OK"
else
    echo "⚠️ Frontend: Problème détecté"
fi

# Nettoyer les anciens logs
log_info "🧹 Nettoyage des anciens logs..."
find /var/log/meknow -name "*.log" -mtime +7 -delete || true

# Nettoyer les anciens backups
log_info "🗑️ Nettoyage des anciens backups..."
find $APP_DIR -name "backup_before_update_*.sql" -mtime +3 -delete || true

log_success "🎉 Mise à jour terminée avec succès!"

# Afficher le status final
echo ""
echo "📊 Status des services:"
sudo -u $DEPLOY_USER pm2 status
echo ""
echo "🌐 Votre site est accessible sur:"
echo "- Frontend: http://$(curl -s ifconfig.me)"
echo "- API: http://$(curl -s ifconfig.me)/api"
echo "- Admin: http://$(curl -s ifconfig.me):8082"