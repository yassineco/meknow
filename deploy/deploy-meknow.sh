#!/bin/bash

# 🚀 Déploiement automatique de Meknow
# Déploie l'application complète sur le serveur VPS
# Usage: bash deploy-meknow.sh

set -e

# Configuration
REPO_URL="https://github.com/votre-username/meknow.git"  # À modifier avec votre vraie URL
APP_DIR="/var/www/meknow"
DEPLOY_USER="deploy"
DOMAIN="votre-domaine.com"  # À modifier avec votre vrai domaine

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Vérification des prérequis
check_requirements() {
    log_info "🔍 Vérification des prérequis..."
    
    # Vérifier que Node.js est installé
    if ! command -v node &> /dev/null; then
        log_error "Node.js n'est pas installé. Exécutez d'abord install-server.sh"
        exit 1
    fi
    
    # Vérifier que PostgreSQL est installé
    if ! command -v psql &> /dev/null; then
        log_error "PostgreSQL n'est pas installé. Exécutez d'abord install-server.sh"
        exit 1
    fi
    
    # Vérifier que PM2 est installé
    if ! command -v pm2 &> /dev/null; then
        log_error "PM2 n'est pas installé. Exécutez d'abord install-server.sh"
        exit 1
    fi
    
    log_success "Tous les prérequis sont satisfaits"
}

# Clone ou mise à jour du repository
setup_repository() {
    log_info "📥 Configuration du repository..."
    
    if [ -d "$APP_DIR/.git" ]; then
        log_info "Mise à jour du repository existant..."
        cd $APP_DIR
        git fetch --all
        git reset --hard origin/main
        git pull origin main
    else
        log_info "Clone du repository..."
        rm -rf $APP_DIR
        git clone $REPO_URL $APP_DIR
        cd $APP_DIR
    fi
    
    # Changement des permissions
    chown -R $DEPLOY_USER:$DEPLOY_USER $APP_DIR
    
    log_success "Repository configuré"
}

# Configuration de la base de données
setup_database() {
    log_info "🐘 Configuration de la base de données..."
    
    # Import des données si elles existent
    if [ -f "$APP_DIR/database/meknow_dump.sql" ]; then
        log_info "Import des données existantes..."
        sudo -u postgres psql -d meknow_production -f "$APP_DIR/database/meknow_dump.sql"
    else
        log_info "Initialisation de la base de données vide..."
        sudo -u postgres psql -d meknow_production -c "
        CREATE TABLE IF NOT EXISTS products (
            id SERIAL PRIMARY KEY,
            name VARCHAR(255) NOT NULL,
            price DECIMAL(10,2) NOT NULL,
            description TEXT,
            stock INTEGER DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        
        CREATE TABLE IF NOT EXISTS orders (
            id SERIAL PRIMARY KEY,
            customer_name VARCHAR(255) NOT NULL,
            customer_email VARCHAR(255) NOT NULL,
            total DECIMAL(10,2) NOT NULL,
            status VARCHAR(50) DEFAULT 'pending',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        
        CREATE TABLE IF NOT EXISTS order_items (
            id SERIAL PRIMARY KEY,
            order_id INTEGER REFERENCES orders(id),
            product_id INTEGER REFERENCES products(id),
            quantity INTEGER NOT NULL,
            price DECIMAL(10,2) NOT NULL
        );
        "
    fi
    
    log_success "Base de données configurée"
}

# Installation des dépendances et build
build_application() {
    log_info "📦 Installation des dépendances et build..."
    
    cd $APP_DIR
    
    # Backend
    if [ -d "medusa-api" ]; then
        log_info "Build du backend MedusaJS..."
        cd medusa-api
        npm install --production
        cd ..
    fi
    
    # Frontend
    if [ -d "menow-web" ]; then
        log_info "Build du frontend Next.js..."
        cd menow-web
        npm install --production
        npm run build
        cd ..
    fi
    
    # Backend minimal (si pas de MedusaJS)
    if [ -f "backend-minimal.js" ]; then
        log_info "Configuration du backend minimal..."
        npm install express cors dotenv pg
    fi
    
    log_success "Application buildée"
}

# Configuration des variables d'environnement
setup_environment() {
    log_info "🔧 Configuration des variables d'environnement..."
    
    # Configuration backend
    cat > $APP_DIR/.env << EOF
# Production Environment
NODE_ENV=production

# Database
DATABASE_URL=postgresql://postgres:meknow2024!@localhost:5432/meknow_production
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASS=meknow2024!
DB_NAME=meknow_production

# Application
PORT=9000
FRONTEND_URL=http://localhost:5000
ADMIN_URL=http://localhost:8082

# Security
JWT_SECRET=$(openssl rand -base64 32)
COOKIE_SECRET=$(openssl rand -base64 32)

# Email (à configurer)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=votre-email@gmail.com
SMTP_PASS=votre-mot-de-passe-app

# Uploads
UPLOAD_DIR=/var/www/meknow/uploads
EOF

    # Configuration frontend
    if [ -d "menow-web" ]; then
        cat > $APP_DIR/menow-web/.env.local << EOF
NEXT_PUBLIC_API_URL=http://localhost:9000
NEXT_PUBLIC_SITE_URL=http://$DOMAIN
EOF
    fi
    
    # Permissions
    chown $DEPLOY_USER:$DEPLOY_USER $APP_DIR/.env
    chmod 600 $APP_DIR/.env
    
    log_success "Variables d'environnement configurées"
}

# Démarrage avec PM2
start_services() {
    log_info "🚀 Démarrage des services avec PM2..."
    
    cd $APP_DIR
    
    # Arrêt des services existants
    sudo -u $DEPLOY_USER pm2 stop all || true
    sudo -u $DEPLOY_USER pm2 delete all || true
    
    # Démarrage du backend
    if [ -f "backend-minimal.js" ]; then
        sudo -u $DEPLOY_USER pm2 start backend-minimal.js --name "meknow-backend" --env production
    elif [ -d "medusa-api" ]; then
        cd medusa-api
        sudo -u $DEPLOY_USER pm2 start npm --name "meknow-medusa" -- start
        cd ..
    fi
    
    # Démarrage du frontend
    if [ -d "menow-web" ]; then
        cd menow-web
        sudo -u $DEPLOY_USER pm2 start npm --name "meknow-frontend" -- start
        cd ..
    fi
    
    # Démarrage de l'admin (si fichier HTML statique)
    if [ -f "admin-complete.html" ]; then
        sudo -u $DEPLOY_USER pm2 start "python3 -m http.server 8082" --name "meknow-admin" --cwd "$APP_DIR"
    fi
    
    # Sauvegarde de la configuration PM2
    sudo -u $DEPLOY_USER pm2 save
    
    log_success "Services démarrés avec PM2"
}

# Configuration Nginx
setup_nginx() {
    log_info "🌐 Configuration Nginx..."
    
    # Utiliser la configuration depuis le fichier deploy/nginx.conf
    if [ -f "$APP_DIR/deploy/nginx.conf" ]; then
        cp "$APP_DIR/deploy/nginx.conf" "/etc/nginx/sites-available/meknow"
        
        # Remplacer le domaine dans la configuration
        sed -i "s/votre-domaine.com/$DOMAIN/g" "/etc/nginx/sites-available/meknow"
        
        # Activer le site
        ln -sf "/etc/nginx/sites-available/meknow" "/etc/nginx/sites-enabled/"
        
        # Supprimer la configuration par défaut
        rm -f "/etc/nginx/sites-enabled/default"
        
        # Test de la configuration
        nginx -t
        
        # Redémarrage Nginx
        systemctl restart nginx
        
        log_success "Nginx configuré"
    else
        log_warning "Fichier nginx.conf non trouvé, configuration basique..."
        
        # Configuration basique
        cat > "/etc/nginx/sites-available/meknow" << EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;

    # Frontend
    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    # API Backend
    location /api/ {
        proxy_pass http://localhost:9000/;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Admin
    location /admin/ {
        proxy_pass http://localhost:8082/;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
        
        ln -sf "/etc/nginx/sites-available/meknow" "/etc/nginx/sites-enabled/"
        rm -f "/etc/nginx/sites-enabled/default"
        nginx -t
        systemctl restart nginx
    fi
}

# Fonction principale
main() {
    log_info "🚀 Début du déploiement de Meknow"
    log_info "Serveur: $(hostname)"
    log_info "IP: $(curl -s ifconfig.me)"
    
    check_requirements
    setup_repository
    setup_database
    build_application
    setup_environment
    start_services
    setup_nginx
    
    echo ""
    log_success "🎉 Déploiement terminé avec succès!"
    echo ""
    echo "🎯 Votre application Meknow est accessible:"
    echo "═══════════════════════════════════════════════"
    echo "🌐 Frontend: http://$(curl -s ifconfig.me)"
    echo "🔧 API: http://$(curl -s ifconfig.me)/api"
    echo "⚙️ Admin: http://$(curl -s ifconfig.me):8082"
    echo ""
    echo "📊 Status des services:"
    sudo -u $DEPLOY_USER pm2 status
    echo ""
    echo "🔧 Commandes utiles:"
    echo "- Voir les logs: pm2 logs"
    echo "- Redémarrer: pm2 restart all"
    echo "- Status: pm2 status"
    echo ""
    
    # Test des services
    log_info "🧪 Test des services..."
    sleep 5
    
    if curl -s "http://localhost:9000/health" > /dev/null; then
        log_success "✅ Backend: Opérationnel"
    else
        log_warning "⚠️ Backend: Vérifiez les logs avec 'pm2 logs'"
    fi
    
    if curl -s "http://localhost:5000" > /dev/null; then
        log_success "✅ Frontend: Opérationnel"
    else
        log_warning "⚠️ Frontend: Vérifiez les logs avec 'pm2 logs'"
    fi
}

# Exécution
main "$@"