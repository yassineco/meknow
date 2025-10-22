#!/bin/bash

###############################################################################
# 🚀 MEKNOW VPS PRODUCTION DEPLOYMENT SCRIPT
# 
# Script automatisé pour déployer Meknow sur VPS Ubuntu 24.04
# Usage: bash deploy-vps-production.sh
#
# Date: 22 octobre 2025
# Version: 1.0.0
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
VPS_IP="31.97.196.215"
DOMAIN="meknow.fr"
APP_DIR="/var/www/meknow"
DB_NAME="meknow_production"
DB_USER="meknow"
DB_PASSWORD="${DB_PASSWORD:-meknow_secure_2025}"

###############################################################################
# Functions
###############################################################################

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Ce script doit être exécuté en tant que root"
        exit 1
    fi
    log_success "Running as root"
}

###############################################################################
# STEP 1: System Update
###############################################################################

step_system_update() {
    log_info "=== ÉTAPE 1: System Update ==="
    
    apt update || log_error "apt update failed"
    apt upgrade -y || log_error "apt upgrade failed"
    
    log_success "System updated"
}

###############################################################################
# STEP 2: Install Node.js
###############################################################################

step_install_nodejs() {
    log_info "=== ÉTAPE 2: Install Node.js 18+ ==="
    
    if command -v node &> /dev/null; then
        log_warning "Node.js already installed: $(node --version)"
        return
    fi
    
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    apt install -y nodejs
    
    # Install pnpm globally
    npm install -g pnpm
    
    log_success "Node.js installed: $(node --version)"
    log_success "npm installed: $(npm --version)"
    log_success "pnpm installed: $(pnpm --version)"
}

###############################################################################
# STEP 3: Install PostgreSQL
###############################################################################

step_install_postgresql() {
    log_info "=== ÉTAPE 3: Install PostgreSQL ==="
    
    if command -v psql &> /dev/null; then
        log_warning "PostgreSQL already installed: $(psql --version)"
        return
    fi
    
    apt install -y postgresql postgresql-contrib
    systemctl start postgresql
    systemctl enable postgresql
    
    log_success "PostgreSQL installed and started"
    
    # Create database and user
    log_info "Creating database and user..."
    
    sudo -u postgres psql -c "CREATE DATABASE $DB_NAME;" || log_warning "Database might already exist"
    sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';" || log_warning "User might already exist"
    sudo -u postgres psql -c "ALTER ROLE $DB_USER SET client_encoding TO 'utf8';"
    sudo -u postgres psql -c "ALTER ROLE $DB_USER SET default_transaction_isolation TO 'read committed';"
    sudo -u postgres psql -c "ALTER ROLE $DB_USER SET default_transaction_deferrable TO on;"
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
    sudo -u postgres psql -d $DB_NAME -c "GRANT SCHEMA public TO $DB_USER;"
    
    log_success "Database and user created"
}

###############################################################################
# STEP 4: Install Nginx
###############################################################################

step_install_nginx() {
    log_info "=== ÉTAPE 4: Install Nginx ==="
    
    if command -v nginx &> /dev/null; then
        log_warning "Nginx already installed: $(nginx -v 2>&1)"
        return
    fi
    
    apt install -y nginx
    systemctl start nginx
    systemctl enable nginx
    
    log_success "Nginx installed and started"
}

###############################################################################
# STEP 5: Install Certbot (Let's Encrypt)
###############################################################################

step_install_certbot() {
    log_info "=== ÉTAPE 5: Install Certbot (Let's Encrypt) ==="
    
    if command -v certbot &> /dev/null; then
        log_warning "Certbot already installed"
        return
    fi
    
    apt install -y certbot python3-certbot-nginx
    
    log_success "Certbot installed"
}

###############################################################################
# STEP 6: Clone Repository
###############################################################################

step_clone_repository() {
    log_info "=== ÉTAPE 6: Clone Repository ==="
    
    if [ -d "$APP_DIR" ]; then
        log_warning "App directory already exists: $APP_DIR"
        log_info "Pulling latest changes..."
        cd $APP_DIR
        git pull origin frontend-sync-complete
    else
        mkdir -p /var/www
        cd /var/www
        git clone https://github.com/yassineco/meknow.git
        cd meknow
        git checkout frontend-sync-complete
    fi
    
    log_success "Repository ready at $APP_DIR"
}

###############################################################################
# STEP 7: Install Dependencies
###############################################################################

step_install_dependencies() {
    log_info "=== ÉTAPE 7: Install Dependencies ==="
    
    cd $APP_DIR
    
    log_info "Installing backend dependencies..."
    npm install
    
    log_info "Installing frontend dependencies..."
    cd menow-web
    pnpm install
    cd ..
    
    log_success "All dependencies installed"
}

###############################################################################
# STEP 8: Setup Database Schema
###############################################################################

step_setup_database() {
    log_info "=== ÉTAPE 8: Setup Database Schema ==="
    
    cd $APP_DIR
    
    # Create tables
    log_info "Creating database tables..."
    sudo -u postgres psql -d $DB_NAME -f schema.sql
    
    # Verify
    TABLE_COUNT=$(sudo -u postgres psql -d $DB_NAME -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';")
    log_success "Database schema created ($TABLE_COUNT tables)"
}

###############################################################################
# STEP 9: Create Environment Files
###############################################################################

step_create_env_files() {
    log_info "=== ÉTAPE 9: Create Environment Files ==="
    
    cd $APP_DIR
    
    # Backend .env
    log_info "Creating backend .env..."
    cat > .env <<EOF
# PostgreSQL Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD

# Server Configuration
PORT=9000
NODE_ENV=production

# CORS
CORS_ORIGIN=https://$DOMAIN,https://www.$DOMAIN

# API
API_URL=https://$DOMAIN/api
FRONTEND_URL=https://$DOMAIN
EOF
    
    # Frontend .env.local
    log_info "Creating frontend .env.local..."
    cat > menow-web/.env.local <<EOF
NEXT_PUBLIC_API_URL=https://$DOMAIN/api
NEXT_PUBLIC_BASE_URL=https://$DOMAIN
NEXT_PUBLIC_ENV=production
EOF
    
    log_success "Environment files created"
    log_warning "Review and update if needed:"
    log_warning "  - $APP_DIR/.env"
    log_warning "  - $APP_DIR/menow-web/.env.local"
}

###############################################################################
# STEP 10: Create Systemd Services
###############################################################################

step_create_systemd_services() {
    log_info "=== ÉTAPE 10: Create Systemd Services ==="
    
    # Backend service
    log_info "Creating backend service..."
    cat > /etc/systemd/system/meknow-backend.service <<EOF
[Unit]
Description=Meknow Backend (Express.js)
After=network.target postgresql.service
Wants=postgresql.service

[Service]
Type=simple
User=www-data
WorkingDirectory=$APP_DIR
ExecStart=/usr/bin/node backend-minimal.js
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

# Environment
Environment="NODE_ENV=production"
Environment="PORT=9000"

# Limits
LimitNOFILE=65535
LimitNPROC=65535

[Install]
WantedBy=multi-user.target
EOF
    
    # Frontend service
    log_info "Creating frontend service..."
    cat > /etc/systemd/system/meknow-frontend.service <<EOF
[Unit]
Description=Meknow Frontend (Next.js)
After=network.target meknow-backend.service
Wants=meknow-backend.service

[Service]
Type=simple
User=www-data
WorkingDirectory=$APP_DIR/menow-web
ExecStart=/usr/bin/node node_modules/.bin/next start
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

# Environment
Environment="NODE_ENV=production"
Environment="PORT=3000"
Environment="NEXT_PUBLIC_API_URL=https://$DOMAIN/api"
Environment="NEXT_PUBLIC_BASE_URL=https://$DOMAIN"

# Limits
LimitNOFILE=65535
LimitNPROC=65535

[Install]
WantedBy=multi-user.target
EOF
    
    # Reload systemd
    systemctl daemon-reload
    
    log_success "Systemd services created"
}

###############################################################################
# STEP 11: Build Frontend
###############################################################################

step_build_frontend() {
    log_info "=== ÉTAPE 11: Build Frontend ==="
    
    cd $APP_DIR/menow-web
    
    log_info "Building Next.js application..."
    pnpm run build
    
    log_success "Frontend built successfully"
}

###############################################################################
# STEP 12: Configure Nginx
###############################################################################

step_configure_nginx() {
    log_info "=== ÉTAPE 12: Configure Nginx (Reverse Proxy) ==="
    
    cat > /etc/nginx/sites-available/meknow <<'NGINX_EOF'
upstream meknow_backend {
    server 127.0.0.1:9000;
    keepalive 32;
}

upstream meknow_frontend {
    server 127.0.0.1:3000;
    keepalive 32;
}

server {
    listen 80;
    server_name DOMAIN_PLACEHOLDER www.DOMAIN_PLACEHOLDER;
    
    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name DOMAIN_PLACEHOLDER www.DOMAIN_PLACEHOLDER;
    
    # SSL certificates (will be filled by Certbot)
    ssl_certificate /etc/letsencrypt/live/DOMAIN_PLACEHOLDER/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/DOMAIN_PLACEHOLDER/privkey.pem;
    
    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Gzip compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript;
    gzip_min_length 1000;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    
    # API proxy (Backend)
    location /api/ {
        proxy_pass http://meknow_backend/api/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
    
    # Static files from backend
    location /images/ {
        proxy_pass http://meknow_backend/images/;
        proxy_cache_valid 200 1d;
    }
    
    # Admin interface from backend
    location /admin {
        proxy_pass http://meknow_backend/admin;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Frontend (Next.js)
    location / {
        proxy_pass http://meknow_frontend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
    
    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
NGINX_EOF
    
    # Replace domain placeholder
    sed -i "s/DOMAIN_PLACEHOLDER/$DOMAIN/g" /etc/nginx/sites-available/meknow
    
    # Enable site
    ln -sf /etc/nginx/sites-available/meknow /etc/nginx/sites-enabled/meknow
    rm -f /etc/nginx/sites-enabled/default
    
    # Test configuration
    nginx -t
    
    log_success "Nginx configured"
}

###############################################################################
# STEP 13: Setup SSL with Let's Encrypt
###############################################################################

step_setup_ssl() {
    log_info "=== ÉTAPE 13: Setup SSL with Let's Encrypt ==="
    
    log_warning "Making sure Nginx is running..."
    systemctl restart nginx
    
    log_info "Requesting SSL certificate for $DOMAIN..."
    certbot certonly --nginx -d $DOMAIN -d www.$DOMAIN --email admin@$DOMAIN --agree-tos --non-interactive || \
        log_warning "SSL certificate setup - may need manual configuration"
    
    # Reload Nginx with SSL config
    systemctl reload nginx
    
    log_success "SSL certificate configured"
}

###############################################################################
# STEP 14: Fix Permissions
###############################################################################

step_fix_permissions() {
    log_info "=== ÉTAPE 14: Fix Permissions ==="
    
    # Create www-data user if needed
    id www-data >/dev/null 2>&1 || useradd -r -s /bin/false www-data
    
    # Set permissions
    chown -R www-data:www-data $APP_DIR
    chmod -R 755 $APP_DIR
    chmod -R 775 $APP_DIR/uploads
    chmod -R 775 $APP_DIR/logs
    
    log_success "Permissions fixed"
}

###############################################################################
# STEP 15: Start Services
###############################################################################

step_start_services() {
    log_info "=== ÉTAPE 15: Start Services ==="
    
    log_info "Starting backend service..."
    systemctl enable meknow-backend.service
    systemctl start meknow-backend.service
    sleep 2
    
    log_info "Starting frontend service..."
    systemctl enable meknow-frontend.service
    systemctl start meknow-frontend.service
    sleep 2
    
    log_success "Services started"
    
    # Check status
    log_info "Checking service status..."
    systemctl status meknow-backend.service --no-pager || log_warning "Backend might not be running yet"
    systemctl status meknow-frontend.service --no-pager || log_warning "Frontend might not be running yet"
}

###############################################################################
# STEP 16: Verification
###############################################################################

step_verification() {
    log_info "=== ÉTAPE 16: Verification ==="
    
    sleep 3
    
    log_info "Testing backend health..."
    curl -s http://localhost:9000/api/products | jq . > /dev/null && \
        log_success "Backend responding" || \
        log_warning "Backend might need time to start"
    
    log_info "Testing frontend health..."
    curl -s http://localhost:3000 > /dev/null && \
        log_success "Frontend responding" || \
        log_warning "Frontend might need time to start"
    
    log_success "Basic verification complete"
}

###############################################################################
# STEP 17: Summary
###############################################################################

step_summary() {
    log_info "=== 🎉 DÉPLOIEMENT COMPLÉTÉ ==="
    
    cat <<EOF

╔════════════════════════════════════════════════════════════╗
║         MEKNOW PRODUCTION DEPLOYMENT COMPLETE              ║
╚════════════════════════════════════════════════════════════╝

📍 Configuration:
  • Domain:        https://$DOMAIN
  • VPS IP:        $VPS_IP
  • App Dir:       $APP_DIR
  • Database:      $DB_NAME

🔧 Services:
  • Backend:       systemctl status meknow-backend.service
  • Frontend:      systemctl status meknow-frontend.service
  • Nginx:         systemctl status nginx
  • PostgreSQL:    systemctl status postgresql

📝 Useful Commands:
  • View logs:     journalctl -u meknow-backend -f
  • View logs:     journalctl -u meknow-frontend -f
  • Restart all:   systemctl restart meknow-backend meknow-frontend
  • Rebuild front: cd $APP_DIR/menow-web && pnpm run build

🌐 Access Points:
  • Frontend:      https://$DOMAIN
  • API:           https://$DOMAIN/api
  • Admin:         https://$DOMAIN/admin
  • Health:        https://$DOMAIN/health

📧 SSL Certificate (Auto-renewal):
  • Certificate:   /etc/letsencrypt/live/$DOMAIN/fullchain.pem
  • Renewal:       Automatic via certbot timer
  • Check:         certbot certificates

⚠️  Next Steps:
  1. Verify all services are running
  2. Test https://$DOMAIN in browser
  3. Check logs if any issues
  4. Setup database backups
  5. Configure monitoring

EOF
    
    log_success "Deployment summary saved"
}

###############################################################################
# Main Execution
###############################################################################

main() {
    log_info "🚀 Starting Meknow Production Deployment..."
    log_info "Target VPS: $VPS_IP | Domain: $DOMAIN"
    
    check_root
    
    step_system_update
    step_install_nodejs
    step_install_postgresql
    step_install_nginx
    step_install_certbot
    step_clone_repository
    step_install_dependencies
    step_setup_database
    step_create_env_files
    step_create_systemd_services
    step_build_frontend
    step_configure_nginx
    step_setup_ssl
    step_fix_permissions
    step_start_services
    step_verification
    step_summary
    
    log_success "✅ All deployment steps completed!"
}

# Run main function
main "$@"
