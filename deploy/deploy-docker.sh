#!/bin/bash

# 🐳 Déploiement automatique Meknow avec Docker
# Usage: bash deploy-docker.sh

set -e

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

# Variables
REPO_URL="https://github.com/yassineco/meknow.git"
APP_DIR="/opt/meknow"
DOMAIN=${1:-"$(curl -s ifconfig.me)"}

log_info "🐳 Début du déploiement Docker de Meknow"
log_info "Serveur: $(hostname)"
log_info "IP: $(curl -s ifconfig.me)"

# Vérifier que Docker est installé
if ! command -v docker &> /dev/null; then
    log_info "📦 Installation de Docker..."
    curl -fsSL https://get.docker.com | sh
    systemctl start docker
    systemctl enable docker
    usermod -aG docker $USER
    log_success "Docker installé"
fi

# Installer Docker Compose si nécessaire
if ! command -v docker-compose &> /dev/null; then
    log_info "📦 Installation de Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    log_success "Docker Compose installé"
fi

# Créer le répertoire de l'application
log_info "📁 Préparation du répertoire..."
mkdir -p $APP_DIR
cd $APP_DIR

# Cloner ou mettre à jour le repository
if [ -d ".git" ]; then
    log_info "📥 Mise à jour du repository..."
    git fetch --all
    git reset --hard origin/main
    git pull origin main
else
    log_info "📥 Clone du repository..."
    git clone $REPO_URL .
fi

# Créer les répertoires nécessaires
mkdir -p uploads logs ssl

# Générer les secrets si .env n'existe pas
if [ ! -f ".env" ]; then
    log_info "🔐 Génération des secrets..."
    cat > .env << EOF
# Environment de production
NODE_ENV=production
DOMAIN=$DOMAIN

# Secrets de sécurité
JWT_SECRET=$(openssl rand -base64 32)
COOKIE_SECRET=$(openssl rand -base64 32)

# Base de données
POSTGRES_DB=meknow_production
POSTGRES_USER=postgres
POSTGRES_PASSWORD=meknow2024!

# URLs publiques
NEXT_PUBLIC_API_URL=http://$DOMAIN:9000
NEXT_PUBLIC_SITE_URL=http://$DOMAIN
EOF
    log_success "Fichier .env créé"
fi

# Configuration Nginx pour l'admin
cat > nginx-admin.conf << 'EOF'
server {
    listen 80;
    server_name localhost;
    
    location / {
        root /usr/share/nginx/html;
        index index.html;
        try_files $uri $uri/ /index.html;
    }
    
    # CORS headers
    add_header Access-Control-Allow-Origin *;
    add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS";
    add_header Access-Control-Allow-Headers "Authorization, Content-Type";
}
EOF

# Configuration Nginx principale
cat > nginx.conf << EOF
events {
    worker_connections 1024;
}

http {
    upstream frontend {
        server frontend:5000;
    }
    
    upstream backend {
        server backend:9000;
    }
    
    upstream admin {
        server admin:80;
    }
    
    server {
        listen 80;
        server_name $DOMAIN localhost;
        
        # Headers de sécurité
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;
        
        # Frontend
        location / {
            proxy_pass http://frontend;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
        
        # API Backend
        location /api/ {
            proxy_pass http://backend/;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
        
        # Health check
        location /health {
            proxy_pass http://backend/health;
            proxy_set_header Host \$host;
            access_log off;
        }
        
        # Admin interface
        location /admin {
            return 302 http://\$host:8082/;
        }
    }
}
EOF

# Arrêter les services existants s'ils existent
log_info "⏹️ Arrêt des services existants..."
docker-compose down --remove-orphans || true

# Construire et démarrer les services
log_info "🏗️ Construction et démarrage des services..."
docker-compose up --build -d

# Attendre que les services soient prêts
log_info "⏳ Attente du démarrage des services..."
sleep 30

# Vérifier la santé des services
log_info "🧪 Vérification des services..."

# Test de la base de données
if docker-compose exec -T database pg_isready -U postgres > /dev/null 2>&1; then
    log_success "✅ PostgreSQL: Opérationnel"
else
    log_error "❌ PostgreSQL: Problème"
fi

# Test du backend
if curl -f http://localhost:9000/health > /dev/null 2>&1; then
    log_success "✅ Backend: Opérationnel"
else
    log_warning "⚠️ Backend: En cours de démarrage..."
fi

# Test du frontend
if curl -f http://localhost:5000 > /dev/null 2>&1; then
    log_success "✅ Frontend: Opérationnel"
else
    log_warning "⚠️ Frontend: En cours de démarrage..."
fi

# Test de l'admin
if curl -f http://localhost:8082 > /dev/null 2>&1; then
    log_success "✅ Admin: Opérationnel"
else
    log_warning "⚠️ Admin: En cours de démarrage..."
fi

# Configuration du firewall
log_info "🔥 Configuration du firewall..."
ufw allow 22/tcp   # SSH
ufw allow 80/tcp   # HTTP
ufw allow 443/tcp  # HTTPS (pour futur SSL)
ufw allow 5000/tcp # Frontend direct
ufw allow 8082/tcp # Admin direct
ufw allow 9000/tcp # API direct
ufw --force enable || true

log_success "🎉 Déploiement Docker terminé avec succès!"

echo ""
echo "🎯 Votre application Meknow est accessible:"
echo "═══════════════════════════════════════════════"
echo "🌐 Site principal: http://$DOMAIN"
echo "🔧 API: http://$DOMAIN:9000"
echo "⚙️ Admin: http://$DOMAIN:8082"
echo "📊 Health: http://$DOMAIN:9000/health"
echo ""
echo "🐳 Gestion Docker:"
echo "- Status: docker-compose ps"
echo "- Logs: docker-compose logs -f"
echo "- Redémarrer: docker-compose restart"
echo "- Arrêter: docker-compose down"
echo "- Mise à jour: git pull && docker-compose up --build -d"
echo ""

# Afficher le status final
echo "📊 Status des conteneurs:"
docker-compose ps

# Créer un script de mise à jour rapide
cat > update-docker.sh << 'EOF'
#!/bin/bash
echo "🔄 Mise à jour de Meknow..."
git pull origin main
docker-compose up --build -d
echo "✅ Mise à jour terminée!"
docker-compose ps
EOF

chmod +x update-docker.sh

log_success "Script de mise à jour créé: ./update-docker.sh"
EOF