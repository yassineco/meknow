#!/bin/bash

#############################################################################
# 📦 BACKUP COMPLET MEKNOW - Avant migration Docker → Natif
#
# Ce script effectue une sauvegarde complète du projet et de la BD
# Créez un backup avant chaque migration importante
#
# Usage: sudo bash backup-complete.sh
#############################################################################

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Répertoire de backup
BACKUP_DIR="/root/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="meknow_backup_${TIMESTAMP}"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"

# Configuration
APP_DIR="/var/www/meknow"
DB_NAME="meknow_production"
DB_USER="meknow_user"

#############################################################################
# FONCTIONS
#############################################################################

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

check_requirements() {
    log_info "Vérification des prérequis..."
    
    # Vérifier que l'on est en root
    if [[ $EUID -ne 0 ]]; then
        log_error "Ce script doit être exécuté en tant que root"
        exit 1
    fi
    
    # Vérifier les outils nécessaires
    for cmd in tar gzip pg_dump; do
        if ! command -v $cmd &> /dev/null; then
            log_error "$cmd n'est pas installé"
            exit 1
        fi
    done
    
    # Vérifier que le répertoire app existe
    if [ ! -d "$APP_DIR" ]; then
        log_error "Répertoire $APP_DIR introuvable"
        exit 1
    fi
    
    # Vérifier l'espace disque
    AVAILABLE_SPACE=$(df "$BACKUP_DIR" | awk 'NR==2 {print $4}')
    REQUIRED_SPACE=$((500 * 1024)) # 500 MB
    
    if [ "$AVAILABLE_SPACE" -lt "$REQUIRED_SPACE" ]; then
        log_warn "Espace disque limité: ${AVAILABLE_SPACE}KB disponible"
    fi
    
    log_success "Tous les prérequis sont satisfaits"
}

create_backup_dir() {
    log_info "Création du répertoire de backup..."
    mkdir -p "$BACKUP_PATH"/{app,db,config}
    log_success "Répertoire créé: $BACKUP_PATH"
}

backup_database() {
    log_info "Sauvegarde de la base de données PostgreSQL..."
    
    if ! sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
        log_warn "Base de données '$DB_NAME' introuvable, ignoré"
        return 0
    fi
    
    sudo -u postgres pg_dump "$DB_NAME" > "$BACKUP_PATH/db/database.sql"
    log_success "Base de données sauvegardée"
    
    # Compresser
    gzip "$BACKUP_PATH/db/database.sql"
    log_success "Base de données compressée: database.sql.gz"
}

backup_env_files() {
    log_info "Sauvegarde des fichiers .env..."
    
    # Backend .env
    if [ -f "$APP_DIR/.env" ]; then
        cp "$APP_DIR/.env" "$BACKUP_PATH/config/.env.backend"
        log_success "Backend .env sauvegardé"
    fi
    
    # Frontend .env
    if [ -f "$APP_DIR/menow-web/.env.local" ]; then
        cp "$APP_DIR/menow-web/.env.local" "$BACKUP_PATH/config/.env.frontend"
        log_success "Frontend .env sauvegardé"
    fi
}

backup_ssl_certs() {
    log_info "Sauvegarde des certificats SSL..."
    
    if [ -d "/etc/letsencrypt/live" ]; then
        cp -r /etc/letsencrypt/live "$BACKUP_PATH/config/ssl_live"
        cp -r /etc/letsencrypt/archive "$BACKUP_PATH/config/ssl_archive" 2>/dev/null || true
        log_success "Certificats SSL sauvegardés"
    else
        log_warn "Aucun certificat SSL trouvé"
    fi
}

backup_nginx_config() {
    log_info "Sauvegarde de la configuration Nginx..."
    
    if [ -d "/etc/nginx" ]; then
        cp -r /etc/nginx "$BACKUP_PATH/config/"
        log_success "Configuration Nginx sauvegardée"
    else
        log_warn "Nginx non trouvé"
    fi
}

backup_uploads() {
    log_info "Sauvegarde des fichiers uploads..."
    
    if [ -d "$APP_DIR/public/uploads" ]; then
        mkdir -p "$BACKUP_PATH/app/uploads"
        cp -r "$APP_DIR/public/uploads/"* "$BACKUP_PATH/app/uploads/" 2>/dev/null || true
        log_success "Fichiers uploads sauvegardés"
    else
        log_warn "Aucun fichier uploads trouvé"
    fi
}

backup_docker_config() {
    log_info "Sauvegarde de la configuration Docker..."
    
    if [ -f "$APP_DIR/docker-compose.yml" ]; then
        cp "$APP_DIR/docker-compose.yml" "$BACKUP_PATH/config/"
        log_success "docker-compose.yml sauvegardé"
    fi
    
    if [ -f "$APP_DIR/Dockerfile" ]; then
        cp "$APP_DIR/Dockerfile" "$BACKUP_PATH/config/"
        log_success "Dockerfile sauvegardé"
    fi
}

backup_package_locks() {
    log_info "Sauvegarde des fichiers lock (npm/pnpm)..."
    
    # Backend
    if [ -f "$APP_DIR/package-lock.json" ]; then
        cp "$APP_DIR/package-lock.json" "$BACKUP_PATH/config/"
        log_success "Backend package-lock.json sauvegardé"
    fi
    
    if [ -f "$APP_DIR/pnpm-lock.yaml" ]; then
        cp "$APP_DIR/pnpm-lock.yaml" "$BACKUP_PATH/config/"
        log_success "Backend pnpm-lock.yaml sauvegardé"
    fi
    
    # Frontend
    if [ -f "$APP_DIR/menow-web/package-lock.json" ]; then
        cp "$APP_DIR/menow-web/package-lock.json" "$BACKUP_PATH/config/"
        log_success "Frontend package-lock.json sauvegardé"
    fi
    
    if [ -f "$APP_DIR/menow-web/pnpm-lock.yaml" ]; then
        cp "$APP_DIR/menow-web/pnpm-lock.yaml" "$BACKUP_PATH/config/"
        log_success "Frontend pnpm-lock.yaml sauvegardé"
    fi
}

compress_backup() {
    log_info "Compression du backup complet..."
    
    cd "$BACKUP_DIR"
    tar czf "${BACKUP_NAME}.tar.gz" "$BACKUP_NAME"
    
    BACKUP_SIZE=$(du -sh "${BACKUP_NAME}.tar.gz" | cut -f1)
    log_success "Backup compressé: ${BACKUP_NAME}.tar.gz (${BACKUP_SIZE})"
    
    # Nettoyer le répertoire non compressé
    rm -rf "$BACKUP_PATH"
}

create_manifest() {
    log_info "Création du manifeste de backup..."
    
    cat > "${BACKUP_DIR}/${BACKUP_NAME}_manifest.txt" << EOF
╔════════════════════════════════════════════════════════════════════════════╗
║                    BACKUP MEKNOW - MANIFESTE                                ║
╚════════════════════════════════════════════════════════════════════════════╝

📅 Date de backup: $(date)
📁 Fichier: ${BACKUP_NAME}.tar.gz
💾 Taille: $(du -sh "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" | cut -f1)

📦 CONTENU DU BACKUP:
─────────────────────────────────────────────────────────────────────────────

DATABASE:
  ✓ PostgreSQL dump: database.sql.gz
  • Base de données: $DB_NAME
  • Créé avec: pg_dump

CONFIGURATION:
  ✓ Backend .env: .env.backend
  ✓ Frontend .env: .env.frontend
  ✓ Docker Compose: docker-compose.yml
  ✓ Dockerfile: Dockerfile
  ✓ Package locks: package-lock.json, pnpm-lock.yaml
  ✓ Nginx config: /etc/nginx/*
  ✓ SSL certificates: /etc/letsencrypt/*

UPLOADS & ASSETS:
  ✓ Fichiers uploads: /public/uploads/*

🔍 VÉRIFICATION:
─────────────────────────────────────────────────────────────────────────────

Dossier app: /var/www/meknow
Git status: $(cd "$APP_DIR" && git log -1 --oneline)
Node version: $(node --version 2>/dev/null || echo "N/A")
PostgreSQL version: $(sudo -u postgres psql --version 2>/dev/null || echo "N/A")

📂 RESTAURATION:
─────────────────────────────────────────────────────────────────────────────

Pour restaurer ce backup:

  1. Extraire l'archive:
     tar xzf ${BACKUP_NAME}.tar.gz

  2. Restaurer la base de données:
     sudo -u postgres psql < ${BACKUP_NAME}/db/database.sql

  3. Restaurer les fichiers:
     cp ${BACKUP_NAME}/config/.env.* /var/www/meknow/
     cp -r ${BACKUP_NAME}/app/uploads/* /var/www/meknow/public/uploads/

  4. Redémarrer les services:
     sudo systemctl restart meknow-api meknow-web

⚠️  NOTES IMPORTANTES:
─────────────────────────────────────────────────────────────────────────────

• Vérifiez la taille disponible avant restauration
• Assurez-vous que PostgreSQL est en cours d'exécution
• Les certificats SSL doivent être restaurés manuellement
• Testez la restauration dans un environnement de test d'abord

═════════════════════════════════════════════════════════════════════════════
Backup créé par: backup-complete.sh
Commande: $0 $@
═════════════════════════════════════════════════════════════════════════════
EOF
    
    log_success "Manifeste créé: ${BACKUP_NAME}_manifest.txt"
}

cleanup_old_backups() {
    log_info "Nettoyage des anciens backups (>30 jours)..."
    
    find "$BACKUP_DIR" -name "meknow_backup_*.tar.gz" -mtime +30 -delete
    log_success "Anciens backups supprimés"
}

#############################################################################
# MAIN
#############################################################################

main() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════════════════════╗"
    echo "║          📦 BACKUP COMPLET MEKNOW - $(date +%Y-%m-%d_%H:%M:%S)                          ║"
    echo "╚════════════════════════════════════════════════════════════════════════════╝"
    echo ""
    
    check_requirements
    create_backup_dir
    backup_database
    backup_env_files
    backup_ssl_certs
    backup_nginx_config
    backup_uploads
    backup_docker_config
    backup_package_locks
    compress_backup
    create_manifest
    cleanup_old_backups
    
    echo ""
    echo "╔════════════════════════════════════════════════════════════════════════════╗"
    echo "║                         ✅ BACKUP COMPLET TERMINÉ                            ║"
    echo "╚════════════════════════════════════════════════════════════════════════════╝"
    echo ""
    echo -e "${GREEN}📂 Chemin du backup:${NC}"
    echo "   ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
    echo ""
    echo -e "${GREEN}📋 Manifeste:${NC}"
    echo "   ${BACKUP_DIR}/${BACKUP_NAME}_manifest.txt"
    echo ""
    echo -e "${GREEN}💾 Taille:${NC}"
    echo "   $(du -sh "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" | cut -f1)"
    echo ""
    echo -e "${YELLOW}⏰ Rétention automatique: 30 jours${NC}"
    echo ""
}

main "$@"
