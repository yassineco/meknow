#!/bin/bash

# 🚀 Installation automatique du serveur pour Meknow
# VPS Hostinger Ubuntu 22.04 LTS
# Usage: bash install-server.sh

set -e

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Vérification OS
if [[ ! -f /etc/lsb-release ]]; then
    log_error "Ce script est conçu pour Ubuntu uniquement"
    exit 1
fi

log_info "🚀 Début de l'installation du serveur Meknow"
log_info "Serveur: $(hostname)"
log_info "IP: $(curl -s ifconfig.me)"

# Mise à jour du système
log_info "📦 Mise à jour du système Ubuntu..."
apt update && apt upgrade -y

# Installation des dépendances essentielles
log_info "🔧 Installation des outils essentiels..."
apt install -y curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release

# Installation Node.js 18.x
log_info "🟢 Installation Node.js 18.x..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Vérification Node.js
NODE_VERSION=$(node --version)
NPM_VERSION=$(npm --version)
log_success "Node.js installé: $NODE_VERSION"
log_success "NPM installé: $NPM_VERSION"

# Installation PM2 (gestionnaire de processus)
log_info "⚡ Installation PM2..."
npm install -g pm2

# Installation PostgreSQL
log_info "🐘 Installation PostgreSQL..."
apt install -y postgresql postgresql-contrib

# Démarrage et activation PostgreSQL
systemctl start postgresql
systemctl enable postgresql

# Configuration PostgreSQL
log_info "🔐 Configuration PostgreSQL..."
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'meknow2024!';"
sudo -u postgres createdb meknow_production

# Configuration pg_hba.conf pour permettre les connexions locales
PG_VERSION=$(sudo -u postgres psql -t -c "SELECT version();" | grep -oP '\d+\.\d+' | head -1)
PG_CONFIG_DIR="/etc/postgresql/$PG_VERSION/main"

# Backup de la configuration originale
cp "$PG_CONFIG_DIR/pg_hba.conf" "$PG_CONFIG_DIR/pg_hba.conf.backup"

# Configuration pour permettre les connexions locales
cat > "$PG_CONFIG_DIR/pg_hba.conf" << EOF
# PostgreSQL Client Authentication Configuration File

# TYPE  DATABASE        USER            ADDRESS                 METHOD

# "local" is for Unix domain socket connections only
local   all             all                                     md5
# IPv4 local connections:
host    all             all             127.0.0.1/32            md5
host    all             all             localhost               md5
# IPv6 local connections:
host    all             all             ::1/128                 md5
EOF

# Redémarrage PostgreSQL
systemctl restart postgresql

# Installation Nginx
log_info "🌐 Installation Nginx..."
apt install -y nginx

# Configuration firewall
log_info "🔥 Configuration du firewall..."
ufw allow 22/tcp     # SSH
ufw allow 80/tcp     # HTTP
ufw allow 443/tcp    # HTTPS
ufw --force enable

# Installation Certbot pour SSL
log_info "🔒 Installation Certbot pour SSL..."
apt install -y certbot python3-certbot-nginx

# Création du répertoire pour l'application
log_info "📁 Création des répertoires..."
mkdir -p /var/www/meknow
mkdir -p /var/log/meknow

# Configuration des permissions
chown -R www-data:www-data /var/www/meknow
chmod -R 755 /var/www/meknow

# Installation Docker (optionnel pour futurs déploiements)
log_info "🐳 Installation Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update
apt install -y docker-ce docker-ce-cli containerd.io

# Démarrage Docker
systemctl start docker
systemctl enable docker

# Création de l'utilisateur de déploiement
log_info "👤 Création de l'utilisateur deploy..."
if ! id "deploy" &>/dev/null; then
    useradd -m -s /bin/bash deploy
    usermod -aG sudo deploy
    usermod -aG docker deploy
    
    # Configuration SSH pour l'utilisateur deploy
    mkdir -p /home/deploy/.ssh
    chmod 700 /home/deploy/.ssh
    chown deploy:deploy /home/deploy/.ssh
fi

# Configuration PM2 startup
log_info "🚀 Configuration PM2 startup..."
sudo -u deploy pm2 startup systemd -u deploy --hp /home/deploy
systemctl enable pm2-deploy

# Affichage des informations du serveur
log_success "✅ Installation terminée avec succès!"
echo ""
echo "🎯 Informations du serveur:"
echo "═══════════════════════════════════════"
echo "🌐 IP Publique: $(curl -s ifconfig.me)"
echo "🐘 PostgreSQL: Installé (Port 5432)"
echo "    - Database: meknow_production"
echo "    - User: postgres"
echo "    - Password: meknow2024!"
echo "🟢 Node.js: $NODE_VERSION"
echo "📦 NPM: $NPM_VERSION"
echo "⚡ PM2: Installé"
echo "🌐 Nginx: Installé"
echo "🔒 Certbot: Installé"
echo "🐳 Docker: Installé"
echo ""
echo "🚀 Prochaine étape:"
echo "Exécutez: curl -sSL https://raw.githubusercontent.com/votre-repo/meknow/main/deploy/deploy-meknow.sh | bash"
echo ""

# Test de connectivité base de données
log_info "🧪 Test de connectivité PostgreSQL..."
if sudo -u postgres psql meknow_production -c "SELECT 1;" > /dev/null 2>&1; then
    log_success "PostgreSQL fonctionne correctement"
else
    log_error "Problème avec PostgreSQL"
fi

# Affichage des services actifs
log_info "📊 Services actifs:"
systemctl is-active postgresql && echo "✅ PostgreSQL: Actif" || echo "❌ PostgreSQL: Inactif"
systemctl is-active nginx && echo "✅ Nginx: Actif" || echo "❌ Nginx: Inactif"
systemctl is-active docker && echo "✅ Docker: Actif" || echo "❌ Docker: Inactif"

log_success "🎉 Serveur prêt pour le déploiement de Meknow!"