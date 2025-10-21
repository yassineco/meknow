#!/bin/bash

# 🚀 Meknow E-commerce - Déploiement Production avec Gestion Rubriques
# Script de déploiement moderne pour plateforme e-commerce complète

set -e

# Configuration
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

APP_NAME="meknow"
DOMAIN="${DOMAIN:-meknow.fr}"
ENVIRONMENT="${ENVIRONMENT:-production}"

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

print_banner() {
    cat << "EOF"
🛍️  ███╗   ███╗███████╗██╗  ██╗███╗   ██╗ ██████╗ ██╗    ██╗
   ████╗ ████║██╔════╝██║ ██╔╝████╗  ██║██╔═══██╗██║    ██║
   ██╔████╔██║█████╗  █████╔╝ ██╔██╗ ██║██║   ██║██║ █╗ ██║
   ██║╚██╔╝██║██╔══╝  ██╔═██╗ ██║╚██╗██║██║   ██║██║███╗██║
   ██║ ╚═╝ ██║███████╗██║  ██╗██║ ╚████║╚██████╔╝╚███╔███╔╝
   ╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝  ╚══╝╚══╝ 
   
🎨 E-COMMERCE PREMIUM - DÉPLOIEMENT PRODUCTION
✅ Synchronisation Admin ↔ Frontend
✅ Gestion Rubriques Catalogue/Lookbook
✅ Architecture PM2 + Docker
EOF
    echo ""
}

# Vérifications préalables
check_requirements() {
    log_info "Vérification des prérequis..."
    
    # Vérifier Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker n'est pas installé. Installez Docker d'abord."
    fi
    
    # Vérifier Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose n'est pas installé."
    fi
    
    # Vérifier PM2
    if ! command -v pm2 &> /dev/null; then
        log_warning "PM2 n'est pas installé. Installation automatique..."
        npm install -g pm2
    fi
    
    log_success "Prérequis OK ✅"
}

# Configuration des variables d'environnement
setup_environment() {
    log_info "Configuration de l'environnement $ENVIRONMENT..."
    
    # Créer .env pour production si n'existe pas
    if [ ! -f ".env.production" ]; then
        cat > .env.production << EOF
# 🚀 Meknow Production Environment
NODE_ENV=production
PORT=9000
DOMAIN=$DOMAIN

# Base de données
DATABASE_URL=postgresql://postgres:meknow2024!@localhost:5432/meknow_production
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASS=meknow2024!
DB_NAME=meknow_production

# Sécurité
JWT_SECRET=\$(openssl rand -base64 32)
COOKIE_SECRET=\$(openssl rand -base64 32)

# URLs Frontend
NEXT_PUBLIC_API_URL=https://$DOMAIN
API_URL=http://localhost:9000
NEXT_PUBLIC_BASE_URL=https://$DOMAIN

# Fonctionnalités
ENABLE_RUBRIQUES=true
ENABLE_LOOKBOOK=true
ENABLE_ADMIN_INTERFACE=true
EOF
        log_success "Fichier .env.production créé"
    fi
}

# Build des images Docker
build_images() {
    log_info "Construction des images Docker..."
    
    # Build backend avec nouvelles fonctionnalités
    log_info "Build backend Express.js avec gestion rubriques..."
    docker build -f Dockerfile.backend -t meknow/backend:latest .
    
    # Build frontend Next.js
    log_info "Build frontend Next.js avec composants rubriques..."
    cd menow-web
    docker build -t meknow/frontend:latest .
    cd ..
    
    log_success "Images Docker construites ✅"
}

# Déploiement avec Docker Compose
deploy_docker() {
    log_info "Déploiement avec Docker Compose..."
    
    # Arrêter les services existants
    log_info "Arrêt des services existants..."
    docker-compose down --remove-orphans || true
    
    # Démarrer les services
    log_info "Démarrage des nouveaux services..."
    docker-compose up -d
    
    # Attendre que les services démarrent
    log_info "Attente du démarrage des services..."
    sleep 30
    
    # Vérifier la santé des services
    if docker-compose ps | grep -q "Up"; then
        log_success "Services Docker démarrés ✅"
    else
        log_error "Erreur lors du démarrage des services Docker"
    fi
}

# Déploiement PM2 (alternative)
deploy_pm2() {
    log_info "Déploiement avec PM2..."
    
    # Arrêter les processus existants
    pm2 stop all || true
    pm2 delete all || true
    
    # Démarrer avec l'ecosystem
    log_info "Démarrage du backend avec PM2..."
    pm2 start ecosystem.config.js --env production
    
    # Démarrer le frontend
    log_info "Démarrage du frontend Next.js..."
    cd menow-web
    npm run build
    pm2 start npm --name "meknow-frontend" -- start
    cd ..
    
    # Sauvegarder la configuration PM2
    pm2 save
    pm2 startup
    
    log_success "Services PM2 démarrés ✅"
}

# Configuration Nginx
setup_nginx() {
    log_info "Configuration Nginx pour $DOMAIN..."
    
    # Créer la configuration Nginx
    sudo tee /etc/nginx/sites-available/meknow << EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;

    # SSL Configuration (Certbot)
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    
    # Frontend Next.js
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
    
    # API Backend + Admin
    location /api/ {
        proxy_pass http://localhost:9000;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # Interface Admin
    location /admin {
        proxy_pass http://localhost:9000;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # Images et assets
    location /images/ {
        proxy_pass http://localhost:9000;
        expires 7d;
        add_header Cache-Control "public, immutable";
    }
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
}
EOF

    # Activer le site
    sudo ln -sf /etc/nginx/sites-available/meknow /etc/nginx/sites-enabled/
    
    # Tester la configuration
    sudo nginx -t && sudo systemctl reload nginx
    
    log_success "Nginx configuré pour $DOMAIN ✅"
}

# Obtenir certificat SSL
setup_ssl() {
    log_info "Configuration SSL avec Let's Encrypt..."
    
    # Installer Certbot si nécessaire
    if ! command -v certbot &> /dev/null; then
        sudo apt update
        sudo apt install -y certbot python3-certbot-nginx
    fi
    
    # Obtenir le certificat
    sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos -m admin@$DOMAIN
    
    log_success "Certificat SSL configuré ✅"
}

# Tests de validation
run_tests() {
    log_info "Tests de validation du déploiement..."
    
    # Test API Backend
    if curl -s http://localhost:9000/api/products | grep -q "products"; then
        log_success "✅ API Backend fonctionnelle"
    else
        log_error "❌ Problème API Backend"
    fi
    
    # Test nouvelles routes rubriques
    if curl -s http://localhost:9000/api/products/catalog | grep -q "catalog"; then
        log_success "✅ API Catalogue fonctionnelle"
    else
        log_warning "⚠️  API Catalogue non accessible"
    fi
    
    if curl -s http://localhost:9000/api/products/lookbook | grep -q "lookbook"; then
        log_success "✅ API Lookbook fonctionnelle"
    else
        log_warning "⚠️  API Lookbook non accessible"
    fi
    
    # Test Frontend
    if curl -s http://localhost:3000 | grep -q "Meknow"; then
        log_success "✅ Frontend Next.js fonctionnel"
    else
        log_warning "⚠️  Frontend non accessible"
    fi
    
    # Test HTTPS si configuré
    if [ ! -z "$DOMAIN" ]; then
        if curl -s https://$DOMAIN | grep -q "Meknow"; then
            log_success "✅ Site HTTPS accessible"
        else
            log_warning "⚠️  Site HTTPS non accessible"
        fi
    fi
}

# Menu principal
main_menu() {
    echo ""
    log_info "Choisissez une option de déploiement:"
    echo "1) 🐳 Déploiement Docker (Recommandé)"
    echo "2) 🚀 Déploiement PM2 (Léger)"
    echo "3) 🌐 Configuration Nginx + SSL"
    echo "4) 🧪 Tests de validation"
    echo "5) 📊 Déploiement complet (All-in-one)"
    echo "0) Quitter"
    echo ""
    
    read -p "Votre choix [1-5]: " choice
    
    case $choice in
        1)
            check_requirements
            setup_environment
            build_images
            deploy_docker
            ;;
        2)
            check_requirements
            setup_environment
            deploy_pm2
            ;;
        3)
            setup_nginx
            setup_ssl
            ;;
        4)
            run_tests
            ;;
        5)
            log_info "🚀 Déploiement complet de Meknow..."
            check_requirements
            setup_environment
            build_images
            deploy_docker
            setup_nginx
            setup_ssl
            run_tests
            log_success "🎉 Déploiement terminé ! Site accessible sur https://$DOMAIN"
            ;;
        0)
            log_info "Au revoir ! 👋"
            exit 0
            ;;
        *)
            log_error "Option invalide"
            ;;
    esac
}

# Script principal
main() {
    print_banner
    
    # Vérifier si on est dans le bon répertoire
    if [ ! -f "backend-minimal.js" ]; then
        log_error "Exécutez ce script depuis le répertoire racine du projet Meknow"
    fi
    
    main_menu
}

# Exécution
main "$@"