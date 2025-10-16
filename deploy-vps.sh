#!/bin/bash

# VPS Deployment Script for MeNow E-commerce
# Run this script on your VPS to deploy the application

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="meknow"
APP_DIR="/opt/meknow"
DOMAIN="yourdomain.com"  # Change this to your domain
DB_NAME="meknow_production"
DB_USER="meknow_user"
DB_PASSWORD=""  # Will be prompted

# Functions
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

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root. Please run as a regular user with sudo privileges."
        exit 1
    fi
}

# Check if user has sudo privileges
check_sudo() {
    if ! sudo -n true 2>/dev/null; then
        log_error "This script requires sudo privileges. Please ensure your user is in the sudo group."
        exit 1
    fi
}

# Update system packages
update_system() {
    log_info "Updating system packages..."
    sudo apt update && sudo apt upgrade -y
    log_success "System updated successfully"
}

# Install required packages
install_packages() {
    log_info "Installing required packages..."
    sudo apt install -y postgresql postgresql-contrib nodejs npm nginx git curl wget ufw
    
    # Install PM2 globally
    sudo npm install -g pm2
    
    log_success "All packages installed successfully"
}

# Configure PostgreSQL
setup_database() {
    log_info "Setting up PostgreSQL database..."
    
    # Prompt for database password
    while [[ -z "$DB_PASSWORD" ]]; do
        read -s -p "Enter a secure password for database user '$DB_USER': " DB_PASSWORD
        echo
        if [[ ${#DB_PASSWORD} -lt 8 ]]; then
            log_warning "Password should be at least 8 characters long"
            DB_PASSWORD=""
        fi
    done
    
    # Create database and user
    sudo -u postgres psql << EOF
CREATE DATABASE $DB_NAME;
CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
\q
EOF
    
    # Configure authentication
    PG_VERSION=$(sudo -u postgres psql -t -c "SELECT version();" | grep -oP '\d+\.\d+' | head -1)
    PG_CONFIG="/etc/postgresql/$PG_VERSION/main/pg_hba.conf"
    
    if [[ -f "$PG_CONFIG" ]]; then
        sudo sed -i "/^local.*all.*all.*peer$/a local   $DB_NAME   $DB_USER                     md5" "$PG_CONFIG"
        sudo systemctl restart postgresql
    fi
    
    sudo systemctl enable postgresql
    log_success "PostgreSQL configured successfully"
}

# Clone and setup application
setup_application() {
    log_info "Setting up application..."
    
    # Remove existing directory if it exists
    if [[ -d "$APP_DIR" ]]; then
        log_warning "Directory $APP_DIR already exists. Backing up..."
        sudo mv "$APP_DIR" "${APP_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Clone repository
    sudo git clone https://github.com/yassineco/meknow.git "$APP_DIR"
    sudo chown -R $USER:$USER "$APP_DIR"
    
    cd "$APP_DIR"
    
    # Install dependencies
    npm install
    
    # Create environment file
    cat > .env.production << EOF
NODE_ENV=production
PORT=8080
DB_HOST=localhost
DB_PORT=5432
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
JWT_SECRET=$(openssl rand -base64 32)
EOF
    
    chmod 600 .env.production
    
    # Import database schema
    PGPASSWORD="$DB_PASSWORD" psql -h localhost -U "$DB_USER" -d "$DB_NAME" -f schema.sql
    
    log_success "Application setup completed"
}

# Configure PM2
setup_pm2() {
    log_info "Configuring PM2..."
    
    cd "$APP_DIR"
    
    # Update ecosystem config with actual database password
    sed -i "s/your_secure_password_here/$DB_PASSWORD/g" ecosystem.config.js
    sed -i "s/your_super_secure_jwt_secret_for_production/$(openssl rand -base64 32)/g" ecosystem.config.js
    
    # Create log directory
    sudo mkdir -p /var/log/pm2
    sudo chown $USER:$USER /var/log/pm2
    
    # Start application
    pm2 start ecosystem.config.js --env production
    pm2 save
    
    # Setup PM2 startup
    pm2 startup | grep "sudo" | bash
    
    log_success "PM2 configured successfully"
}

# Configure Nginx
setup_nginx() {
    log_info "Configuring Nginx..."
    
    # Copy nginx configuration
    sudo cp "$APP_DIR/nginx-meknow.conf" "/etc/nginx/sites-available/$APP_NAME"
    
    # Update domain in configuration
    sudo sed -i "s/yourdomain.com/$DOMAIN/g" "/etc/nginx/sites-available/$APP_NAME"
    
    # Enable site
    sudo ln -sf "/etc/nginx/sites-available/$APP_NAME" "/etc/nginx/sites-enabled/"
    
    # Remove default site
    sudo rm -f /etc/nginx/sites-enabled/default
    
    # Test configuration
    sudo nginx -t
    
    # Enable and start Nginx
    sudo systemctl enable nginx
    sudo systemctl restart nginx
    
    log_success "Nginx configured successfully"
}

# Configure firewall
setup_firewall() {
    log_info "Configuring firewall..."
    
    sudo ufw --force reset
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow ssh
    sudo ufw allow 'Nginx Full'
    sudo ufw --force enable
    
    log_success "Firewall configured successfully"
}

# Setup SSL certificate
setup_ssl() {
    log_info "Setting up SSL certificate..."
    
    # Install certbot
    sudo apt install -y certbot python3-certbot-nginx
    
    # Get certificate
    sudo certbot --nginx -d "$DOMAIN" -d "www.$DOMAIN" --non-interactive --agree-tos --email "admin@$DOMAIN"
    
    log_success "SSL certificate configured successfully"
}

# Main deployment function
main() {
    log_info "Starting MeNow deployment..."
    
    check_root
    check_sudo
    
    # Prompt for domain
    read -p "Enter your domain name (e.g., meknow.com): " input_domain
    if [[ -n "$input_domain" ]]; then
        DOMAIN="$input_domain"
    fi
    
    update_system
    install_packages
    setup_database
    setup_application
    setup_pm2
    setup_nginx
    setup_firewall
    
    # Ask about SSL
    read -p "Do you want to setup SSL certificate with Let's Encrypt? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        setup_ssl
    fi
    
    log_success "Deployment completed successfully!"
    echo
    log_info "Your application is now running at:"
    log_info "HTTP: http://$DOMAIN"
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "HTTPS: https://$DOMAIN"
    fi
    echo
    log_info "Admin interface: /admin-complete-ecommerce.html"
    log_info "PM2 status: pm2 status"
    log_info "PM2 logs: pm2 logs $APP_NAME-server"
    log_info "Nginx logs: sudo tail -f /var/log/nginx/meknow_error.log"
    echo
    log_warning "Don't forget to:"
    log_warning "1. Update your DNS records to point to this server"
    log_warning "2. Change default admin credentials"
    log_warning "3. Setup regular backups"
    log_warning "4. Monitor application logs"
}

# Run main function
main "$@"