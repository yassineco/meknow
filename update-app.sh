#!/bin/bash

# Update script for MeNow E-commerce on VPS
# Run this script to update the application

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

APP_DIR="/opt/meknow"
APP_NAME="meknow-server"

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

# Backup function
backup_database() {
    log_info "Creating database backup..."
    
    BACKUP_DIR="$APP_DIR/backups"
    mkdir -p "$BACKUP_DIR"
    
    BACKUP_FILE="$BACKUP_DIR/backup_$(date +%Y%m%d_%H%M%S).sql"
    
    source "$APP_DIR/.env.production"
    PGPASSWORD="$DB_PASSWORD" pg_dump -h "$DB_HOST" -U "$DB_USER" "$DB_NAME" > "$BACKUP_FILE"
    
    # Keep only last 7 backups
    cd "$BACKUP_DIR"
    ls -t backup_*.sql | tail -n +8 | xargs -r rm
    
    log_success "Database backup created: $BACKUP_FILE"
}

# Update application
update_application() {
    log_info "Updating application..."
    
    cd "$APP_DIR"
    
    # Backup current version
    if [[ -f "package.json" ]]; then
        CURRENT_VERSION=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
        log_info "Current version: $CURRENT_VERSION"
    fi
    
    # Pull latest changes
    git fetch origin
    git pull origin main
    
    # Install/update dependencies
    npm install
    
    # Show new version
    NEW_VERSION=$(git rev-parse --short HEAD)
    log_success "Updated to version: $NEW_VERSION"
}

# Restart services
restart_services() {
    log_info "Restarting services..."
    
    # Restart application
    pm2 restart "$APP_NAME"
    
    # Wait for app to start
    sleep 5
    
    # Check if app is running
    if pm2 list | grep -q "$APP_NAME.*online"; then
        log_success "Application restarted successfully"
    else
        log_error "Application failed to start"
        pm2 logs "$APP_NAME" --lines 20
        exit 1
    fi
    
    # Reload Nginx configuration
    sudo nginx -t && sudo systemctl reload nginx
    log_success "Nginx configuration reloaded"
}

# Health check
health_check() {
    log_info "Performing health check..."
    
    # Wait a moment for the app to fully start
    sleep 3
    
    # Test API endpoint
    if curl -f -s "http://localhost:8080/api/products" > /dev/null; then
        log_success "API is responding correctly"
    else
        log_error "API health check failed"
        pm2 logs "$APP_NAME" --lines 10
        exit 1
    fi
    
    # Test Nginx
    if curl -f -s "http://localhost/" > /dev/null; then
        log_success "Nginx is serving requests correctly"
    else
        log_warning "Nginx health check failed - check configuration"
    fi
}

# Show status
show_status() {
    log_info "Current system status:"
    echo
    
    # PM2 status
    echo "PM2 Processes:"
    pm2 list
    echo
    
    # System resources
    echo "System Resources:"
    free -h
    echo
    df -h /
    echo
    
    # Recent logs
    echo "Recent application logs:"
    pm2 logs "$APP_NAME" --lines 10 --nostream
}

# Main function
main() {
    log_info "Starting application update..."
    
    # Check if we're in the right directory and it's a git repo
    if [[ ! -d "$APP_DIR/.git" ]]; then
        log_error "Application directory not found or not a git repository: $APP_DIR"
        exit 1
    fi
    
    # Check if PM2 process exists
    if ! pm2 list | grep -q "$APP_NAME"; then
        log_error "PM2 process '$APP_NAME' not found"
        log_info "Available processes:"
        pm2 list
        exit 1
    fi
    
    # Backup database
    backup_database
    
    # Update application
    update_application
    
    # Restart services
    restart_services
    
    # Health check
    health_check
    
    # Show status
    show_status
    
    log_success "Update completed successfully!"
    echo
    log_info "Useful commands:"
    log_info "  View logs: pm2 logs $APP_NAME"
    log_info "  Monitor: pm2 monit"
    log_info "  Status: pm2 status"
    log_info "  Restart: pm2 restart $APP_NAME"
}

# Handle script arguments
case "${1:-}" in
    "backup")
        backup_database
        ;;
    "restart")
        restart_services
        health_check
        ;;
    "status")
        show_status
        ;;
    "health")
        health_check
        ;;
    *)
        main
        ;;
esac