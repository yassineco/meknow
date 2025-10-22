#!/bin/bash

#############################################################################
# 🚀 DEPLOY MEKNOW - VPS NATIVE DEPLOYMENT STARTER
#
# Ce script prépare et guide le déploiement complet sur VPS
# À exécuter en tant que root sur le VPS
#
# Usage: sudo bash deploy-vps-native.sh
#############################################################################

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

#############################################################################
# CONFIGURATION
#############################################################################

APP_DIR="/var/www/meknow"
BACKUP_DIR="/root/backups"
GITHUB_REPO="https://github.com/yassineco/meknow.git"
GITHUB_BRANCH="frontend-sync-complete"

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

#############################################################################
# MAIN MENU
#############################################################################

show_menu() {
    clear
    echo ""
    echo "╔════════════════════════════════════════════════════════════════════════════╗"
    echo "║                  🚀 DEPLOYMENT MEKNOW - VPS NATIVE                          ║"
    echo "║                         $(date +%Y-%m-%d_%H:%M:%S)                                    ║"
    echo "╚════════════════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Choisissez une action:"
    echo ""
    echo "  [1] ⚡ DÉPLOIEMENT RAPIDE (recommandé)"
    echo "       - Backup complet"
    echo "       - Migration Docker → Natif"
    echo "       - Tests complets"
    echo ""
    echo "  [2] 💾 SAUVEGARDE UNIQUEMENT"
    echo "       - Créer un backup complet du projet"
    echo ""
    echo "  [3] 🧹 NETTOYAGE DOCKER UNIQUEMENT"
    echo "       - Supprimer tous les conteneurs Docker"
    echo "       - Supprimer les volumes"
    echo ""
    echo "  [4] ⚙️  INSTALLATION SERVICES NATIFS UNIQUEMENT"
    echo "       - Configurer systemd"
    echo "       - Démarrer les services"
    echo ""
    echo "  [5] 🧪 TESTS UNIQUEMENT"
    echo "       - Vérifier tous les services"
    echo "       - Valider la configuration"
    echo ""
    echo "  [0] ❌ QUITTER"
    echo ""
    read -p "Votre choix [0-5]: " choice
}

#############################################################################
# ÉTAPES DE DÉPLOIEMENT
#############################################################################

step_backup() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════════════════════╗"
    echo "║                         📦 ÉTAPE 1 : SAUVEGARDE                             ║"
    echo "╚════════════════════════════════════════════════════════════════════════════╝"
    echo ""
    
    log_info "Vérification des prérequis..."
    
    # Vérifier que nous sommes en root
    if [[ $EUID -ne 0 ]]; then
        log_error "Ce script doit être exécuté en tant que root (sudo)"
        exit 1
    fi
    
    # Créer le répertoire de backup
    mkdir -p "$BACKUP_DIR"
    
    log_info "Création d'une sauvegarde complète..."
    if [ -f "$APP_DIR/backup-complete.sh" ]; then
        bash "$APP_DIR/backup-complete.sh"
        log_success "Sauvegarde terminée"
    else
        log_warn "Script de backup non trouvé, création manuelle..."
        mkdir -p "$BACKUP_DIR/manual_backup_$(date +%Y%m%d_%H%M%S)"
    fi
    
    read -p "Appuyez sur ENTRÉE pour continuer..."
}

step_cleanup_docker() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════════════════════╗"
    echo "║                    🧹 ÉTAPE 2 : NETTOYAGE DOCKER                           ║"
    echo "╚════════════════════════════════════════════════════════════════════════════╝"
    echo ""
    
    log_warn "Cette action va supprimer tous les conteneurs Docker!"
    read -p "Êtes-vous sûr? (tapez 'OUI' pour continuer): " confirm
    
    if [ "$confirm" != "OUI" ]; then
        log_info "Annulé"
        return 0
    fi
    
    log_info "Arrêt et suppression des conteneurs Docker..."
    
    # Arrêter les conteneurs
    if command -v docker &> /dev/null; then
        docker-compose -f "$APP_DIR/docker-compose.yml" down 2>/dev/null || true
        docker stop $(docker ps -a -q) 2>/dev/null || true
        
        log_info "Suppression des images Docker..."
        docker rmi $(docker images -a -q) -f 2>/dev/null || true
        
        log_info "Suppression des volumes..."
        docker volume rm $(docker volume ls -q) 2>/dev/null || true
        
        log_info "Nettoyage du système Docker..."
        docker system prune -a -f 2>/dev/null || true
    else
        log_warn "Docker n'est pas installé"
    fi
    
    log_success "Nettoyage Docker terminé"
    read -p "Appuyez sur ENTRÉE pour continuer..."
}

step_install_services() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════════════════════╗"
    echo "║              ⚙️  ÉTAPE 3 : INSTALLATION DES SERVICES NATIFS                ║"
    echo "╚════════════════════════════════════════════════════════════════════════════╝"
    echo ""
    
    log_info "Mise à jour du projet Git..."
    cd "$APP_DIR"
    git fetch origin
    git checkout "$GITHUB_BRANCH"
    git pull origin "$GITHUB_BRANCH"
    log_success "Projet mis à jour"
    
    log_info "Installation des dépendances backend..."
    npm install --production
    log_success "Dépendances backend installées"
    
    log_info "Installation des dépendances frontend..."
    cd "$APP_DIR/menow-web"
    npm install --production
    log_success "Dépendances frontend installées"
    
    log_info "Build du frontend Next.js..."
    npm run build
    log_success "Frontend construit"
    
    cd "$APP_DIR"
    
    log_info "Configuration de systemd..."
    
    # Créer l'utilisateur www-data
    useradd -r -s /bin/bash www-data 2>/dev/null || true
    
    # Créer les répertoires de logs
    mkdir -p /var/log/meknow
    chown www-data:www-data /var/log/meknow
    
    # Copier les fichiers systemd
    cp "$APP_DIR/meknow-api.service" /etc/systemd/system/
    cp "$APP_DIR/meknow-web.service" /etc/systemd/system/
    
    # Assurer les permissions correctes
    chown -R www-data:www-data "$APP_DIR"
    chmod -R 755 "$APP_DIR"
    
    # Recharger systemd
    systemctl daemon-reload
    
    log_info "Activation des services..."
    systemctl enable meknow-api meknow-web
    
    log_info "Démarrage des services..."
    systemctl start meknow-api meknow-web
    
    log_success "Services natifs configurés et démarrés"
    read -p "Appuyez sur ENTRÉE pour continuer..."
}

step_tests() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════════════════════╗"
    echo "║                       🧪 ÉTAPE 4 : TESTS COMPLETS                          ║"
    echo "╚════════════════════════════════════════════════════════════════════════════╝"
    echo ""
    
    if [ -f "$APP_DIR/test-post-migration.sh" ]; then
        bash "$APP_DIR/test-post-migration.sh"
    else
        log_warn "Script de test non trouvé"
        log_info "Tests manuels recommandés:"
        echo ""
        echo "  systemctl status meknow-api meknow-web"
        echo "  curl http://localhost:9000/api/products"
        echo "  curl http://localhost:3000"
        echo ""
    fi
    
    read -p "Appuyez sur ENTRÉE pour continuer..."
}

step_quick_deploy() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════════════════════╗"
    echo "║                   ⚡ DÉPLOIEMENT RAPIDE COMPLET                            ║"
    echo "╚════════════════════════════════════════════════════════════════════════════╝"
    echo ""
    
    log_warn "Cette opération va:"
    echo "  1. Créer une sauvegarde complète"
    echo "  2. Arrêter et nettoyer Docker"
    echo "  3. Installer les services natifs"
    echo "  4. Exécuter les tests"
    echo ""
    echo "⏱️  Durée estimée: 15-20 minutes"
    echo ""
    
    read -p "Êtes-vous prêt? (tapez 'OUI' pour continuer): " confirm
    
    if [ "$confirm" != "OUI" ]; then
        log_info "Annulé"
        return 0
    fi
    
    step_backup
    step_cleanup_docker
    step_install_services
    step_tests
    
    echo ""
    echo "╔════════════════════════════════════════════════════════════════════════════╗"
    echo "║                   ✅ DÉPLOIEMENT COMPLET RÉUSSI!                           ║"
    echo "╚════════════════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "🎉 Votre application Meknow est maintenant déployée en mode natif!"
    echo ""
    echo "📊 Statut des services:"
    systemctl status meknow-api meknow-web --no-pager || true
    echo ""
    echo "🌐 URLs d'accès:"
    echo "  API: http://$(hostname -I | awk '{print $1}'):9000"
    echo "  Frontend: http://$(hostname -I | awk '{print $1}'):3000"
    echo "  Admin: http://$(hostname -I | awk '{print $1}'):9000/admin"
    echo ""
    echo "📋 Commandes utiles:"
    echo "  Statut:     systemctl status meknow-api meknow-web"
    echo "  Logs API:   journalctl -u meknow-api -f"
    echo "  Logs Front: journalctl -u meknow-web -f"
    echo "  Redémarrer: systemctl restart meknow-api meknow-web"
    echo ""
}

#############################################################################
# BOUCLE PRINCIPALE
#############################################################################

while true; do
    show_menu
    
    case $choice in
        1) step_quick_deploy ;;
        2) step_backup ;;
        3) step_cleanup_docker ;;
        4) step_install_services ;;
        5) step_tests ;;
        0) 
            echo ""
            log_info "Au revoir!"
            exit 0
            ;;
        *)
            log_error "Choix invalide"
            sleep 2
            ;;
    esac
done
