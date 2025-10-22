#!/bin/bash

#############################################################################
# 🧪 TEST POST-MIGRATION - Validation complète Meknow
#
# Ce script vérifie que tous les services fonctionnent correctement
# après la migration Docker → Natif
#
# Usage: sudo bash test-post-migration.sh
#############################################################################

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
APP_DIR="/var/www/meknow"
BACKEND_URL="http://localhost:9000"
FRONTEND_URL="http://localhost:3000"
ADMIN_URL="http://localhost:9000/admin"

# Compteurs
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

#############################################################################
# FONCTIONS
#############################################################################

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
    ((PASSED_TESTS++))
}

log_fail() {
    echo -e "${RED}❌ $1${NC}"
    ((FAILED_TESTS++))
}

log_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

test_service() {
    ((TOTAL_TESTS++))
    local service="$1"
    local status=$(sudo systemctl is-active "$service" 2>/dev/null || echo "inactive")
    
    if [ "$status" = "active" ]; then
        log_success "Service $service est actif"
    else
        log_fail "Service $service est INACTIF"
    fi
}

test_port() {
    ((TOTAL_TESTS++))
    local port="$1"
    local service="$2"
    
    if sudo lsof -i ":$port" &>/dev/null; then
        log_success "Port $port est écouté ($service)"
    else
        log_fail "Port $port n'est PAS écouté"
    fi
}

test_api_endpoint() {
    ((TOTAL_TESTS++))
    local endpoint="$1"
    local description="$2"
    
    local response=$(curl -s -w "\n%{http_code}" "$BACKEND_URL$endpoint" 2>/dev/null || echo "000")
    local http_code=$(echo "$response" | tail -1)
    
    if [ "$http_code" = "200" ] || [ "$http_code" = "201" ]; then
        log_success "API $description (HTTP $http_code)"
    else
        log_fail "API $description ÉCHOUÉE (HTTP $http_code)"
    fi
}

test_frontend_page() {
    ((TOTAL_TESTS++))
    local url="$1"
    local description="$2"
    
    local response=$(curl -s -w "\n%{http_code}" "$url" 2>/dev/null || echo "000")
    local http_code=$(echo "$response" | tail -1)
    
    if [ "$http_code" = "200" ]; then
        log_success "Frontend $description (HTTP $http_code)"
    else
        log_fail "Frontend $description ÉCHOUÉE (HTTP $http_code)"
    fi
}

#############################################################################
# TESTS PRINCIPALES
#############################################################################

echo ""
echo "╔════════════════════════════════════════════════════════════════════════════╗"
echo "║              🧪 TEST POST-MIGRATION - $(date +%Y-%m-%d_%H:%M:%S)                          ║"
echo "╚════════════════════════════════════════════════════════════════════════════╝"
echo ""

# Section 1: Services systemd
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📦 1. VÉRIFICATION DES SERVICES SYSTEMD${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
test_service "meknow-api"
test_service "meknow-web"
test_service "postgresql"
test_service "nginx"
echo ""

# Section 2: Ports
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔌 2. VÉRIFICATION DES PORTS${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
test_port "9000" "Backend API"
test_port "3000" "Frontend Next.js"
test_port "5432" "PostgreSQL"
test_port "80" "Nginx HTTP"
test_port "443" "Nginx HTTPS"
echo ""

# Section 3: API Endpoints
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔗 3. VÉRIFICATION DES ENDPOINTS API${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
test_api_endpoint "/api/products" "GET /api/products"
test_api_endpoint "/api/products/lookbook" "GET /api/products/lookbook"
test_api_endpoint "/health" "GET /health (si disponible)"
echo ""

# Section 4: Frontend Pages
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🌐 4. VÉRIFICATION DES PAGES FRONTEND${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
test_frontend_page "$FRONTEND_URL" "Home Page"
test_frontend_page "$FRONTEND_URL/products" "Products Page"
test_frontend_page "$FRONTEND_URL/lookbook" "Lookbook Page"
echo ""

# Section 5: Base de données
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🗄️  5. VÉRIFICATION DE LA BASE DE DONNÉES${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

((TOTAL_TESTS++))
if sudo -u postgres psql -l 2>/dev/null | grep -q "meknow_production"; then
    log_success "Base de données 'meknow_production' existe"
else
    log_warn "Base de données 'meknow_production' introuvable"
fi

((TOTAL_TESTS++))
if psql -h localhost -U meknow_user -d meknow_production -c "SELECT 1" &>/dev/null; then
    log_success "Connexion BD réussie (meknow_user)"
else
    log_fail "Connexion BD ÉCHOUÉE"
fi

echo ""

# Section 6: Fichiers et permissions
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📁 6. VÉRIFICATION DES FICHIERS ET PERMISSIONS${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

((TOTAL_TESTS++))
if [ -d "$APP_DIR" ]; then
    log_success "Répertoire application existe"
else
    log_fail "Répertoire application INTROUVABLE"
fi

((TOTAL_TESTS++))
if [ -f "$APP_DIR/.env" ]; then
    log_success "Fichier .env backend existe"
else
    log_fail "Fichier .env backend MANQUANT"
fi

((TOTAL_TESTS++))
if [ -f "$APP_DIR/menow-web/.env.local" ]; then
    log_success "Fichier .env frontend existe"
else
    log_fail "Fichier .env frontend MANQUANT"
fi

((TOTAL_TESTS++))
if [ -d "$APP_DIR/.next" ]; then
    log_success "Build Next.js (.next) existe"
else
    log_warn "Build Next.js (.next) INTROUVABLE - vous devez exécuter: npm run build"
fi

((TOTAL_TESTS++))
if [ -d "$APP_DIR/node_modules" ]; then
    log_success "node_modules backend existe"
else
    log_fail "node_modules backend MANQUANT"
fi

((TOTAL_TESTS++))
if [ -d "$APP_DIR/menow-web/node_modules" ]; then
    log_success "node_modules frontend existe"
else
    log_fail "node_modules frontend MANQUANT"
fi

echo ""

# Section 7: Logs
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📋 7. VÉRIFICATION DES LOGS RÉCENTS${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo "Dernières lignes du backend:"
sudo journalctl -u meknow-api -n 5 --no-pager 2>/dev/null | grep -v "^--" || echo "  (aucun log disponible)"
echo ""

echo "Dernières lignes du frontend:"
sudo journalctl -u meknow-web -n 5 --no-pager 2>/dev/null | grep -v "^--" || echo "  (aucun log disponible)"
echo ""

# Section 8: Résumé et recommandations
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📊 8. RÉSUMÉ DES TESTS${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo ""
echo "Total des tests: $TOTAL_TESTS"
echo -e "${GREEN}Réussis: $PASSED_TESTS${NC}"
echo -e "${RED}Échoués: $FAILED_TESTS${NC}"

# Calculer le pourcentage de succès
if [ $TOTAL_TESTS -gt 0 ]; then
    PERCENTAGE=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    echo "Taux de succès: $PERCENTAGE%"
fi

echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    ✅ MIGRATION RÉUSSIE - TOUS LES TESTS PASSENT              ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════════════╝${NC}"
    exit 0
else
    echo -e "${RED}╔════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║              ⚠️  ATTENTION - CERTAINS TESTS ONT ÉCHOUÉ                      ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════════════════════╝${NC}"
    
    echo ""
    echo "Dépannage recommandé:"
    echo "  1. Vérifiez les logs: sudo journalctl -u meknow-api -f"
    echo "  2. Redémarrez les services: sudo systemctl restart meknow-api meknow-web"
    echo "  3. Vérifiez les permissions: sudo chown -R www-data:www-data $APP_DIR"
    echo "  4. Vérifiez la BD: psql -h localhost -U meknow_user -d meknow_production"
    echo ""
    
    exit 1
fi
