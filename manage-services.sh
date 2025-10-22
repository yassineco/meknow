#!/bin/bash

# 🛠️ Script de gestion des services Meknow

set -e

COMMAND=$1
PROJECT_PATH="/var/www/meknow"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

show_help() {
    cat << EOF
${BLUE}🛠️  Gestionnaire de services Meknow${NC}

Usage: ./manage-services.sh [commande]

Commandes:
    start       Démarrer tous les services
    stop        Arrêter tous les services
    restart     Redémarrer tous les services
    status      Afficher le statut des services
    logs        Afficher les logs en temps réel
    logs-api    Afficher les logs du backend
    logs-web    Afficher les logs du frontend
    update      Mettre à jour et redémarrer
    install     Installer les services systemd
    uninstall   Désinstaller les services systemd

EOF
}

start() {
    echo -e "${YELLOW}🚀 Démarrage des services...${NC}"
    
    if command -v systemctl &> /dev/null; then
        sudo systemctl start meknow-api meknow-web
    else
        echo -e "${RED}systemd non disponible${NC}"
        echo "Démarrage manuel:"
        echo "  Terminal 1: npm run api"
        echo "  Terminal 2: npm run web"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Services démarrés${NC}"
    status
}

stop() {
    echo -e "${YELLOW}⏹️  Arrêt des services...${NC}"
    sudo systemctl stop meknow-api meknow-web
    echo -e "${GREEN}✅ Services arrêtés${NC}"
}

restart() {
    echo -e "${YELLOW}🔄 Redémarrage des services...${NC}"
    sudo systemctl restart meknow-api meknow-web
    echo -e "${GREEN}✅ Services redémarrés${NC}"
    status
}

status() {
    echo -e "\n${BLUE}📊 Statut des services:${NC}"
    echo ""
    sudo systemctl status meknow-api --no-pager || true
    echo ""
    sudo systemctl status meknow-web --no-pager || true
}

logs() {
    echo -e "${BLUE}📜 Logs en temps réel...${NC}"
    echo "API Backend:"
    sudo journalctl -u meknow-api -f --no-pager &
    
    sleep 1
    echo -e "\n${BLUE}Frontend:${NC}"
    sudo journalctl -u meknow-web -f --no-pager
}

logs_api() {
    echo -e "${BLUE}📜 Logs Backend:${NC}"
    sudo journalctl -u meknow-api -f --no-pager
}

logs_web() {
    echo -e "${BLUE}📜 Logs Frontend:${NC}"
    sudo journalctl -u meknow-web -f --no-pager
}

update() {
    echo -e "${YELLOW}📦 Mise à jour du projet...${NC}"
    
    cd $PROJECT_PATH
    
    # Arrêter les services
    stop
    
    # Récupérer les dernières modifications
    git pull origin main
    
    # Installer les dépendances
    npm install --production
    
    # Reconstruire le frontend
    cd menow-web
    npm install --production
    npm run build
    cd ..
    
    # Redémarrer
    start
    
    echo -e "${GREEN}✅ Mise à jour complète${NC}"
}

install() {
    echo -e "${YELLOW}🔧 Installation des services systemd...${NC}"
    
    if [ "$EUID" -ne 0 ]; then
        echo "Les services systemd doivent être installés avec sudo"
        echo "Exécutez: sudo ./manage-services.sh install"
        exit 1
    fi
    
    bash $PROJECT_PATH/install-systemd.sh
    
    echo -e "${GREEN}✅ Services installés${NC}"
}

uninstall() {
    echo -e "${YELLOW}⚠️  Désinstallation des services systemd...${NC}"
    
    if [ "$EUID" -ne 0 ]; then
        echo "La désinstallation doit être faite avec sudo"
        echo "Exécutez: sudo ./manage-services.sh uninstall"
        exit 1
    fi
    
    sudo systemctl stop meknow-api meknow-web 2>/dev/null || true
    sudo systemctl disable meknow-api.service meknow-web.service 2>/dev/null || true
    sudo rm -f /etc/systemd/system/meknow-*.service
    sudo systemctl daemon-reload
    
    echo -e "${GREEN}✅ Services désinstallés${NC}"
}

# Exécuter la commande
case "$COMMAND" in
    start) start ;;
    stop) stop ;;
    restart) restart ;;
    status) status ;;
    logs) logs ;;
    logs-api) logs_api ;;
    logs-web) logs_web ;;
    update) update ;;
    install) install ;;
    uninstall) uninstall ;;
    *) show_help ;;
esac
