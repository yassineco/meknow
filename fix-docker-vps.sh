#!/bin/bash

# 🔧 Script de correction Docker VPS - MEKNOW
# Usage: ./fix-docker-vps.sh

echo "🔧 DIAGNOSTIC ET CORRECTION DOCKER VPS - MEKNOW"
echo "=============================================="

# Variables
PROJECT_DIR="/var/www/meknow"
BACKUP_DIR="/var/backups/meknow"

echo "1. 🔍 Diagnostic de la situation actuelle..."

# Vérifier l'emplacement actuel
echo "📍 Répertoire courant: $(pwd)"
echo "📋 Contenu du répertoire courant:"
ls -la

echo ""
echo "2. 🗂️ Vérification du projet MEKNOW..."

# Vérifier si le projet existe
if [ -d "$PROJECT_DIR" ]; then
    echo "✅ Répertoire projet trouvé: $PROJECT_DIR"
    cd $PROJECT_DIR
    echo "📋 Contenu du projet:"
    ls -la | head -20
    
    # Vérifier docker-compose.yml
    if [ -f "docker-compose.yml" ]; then
        echo "✅ docker-compose.yml trouvé dans $PROJECT_DIR"
    else
        echo "❌ docker-compose.yml MANQUANT dans $PROJECT_DIR"
    fi
else
    echo "❌ Répertoire projet NOT FOUND: $PROJECT_DIR"
    echo "🔄 Le projet doit être réinstallé..."
fi

echo ""
echo "3. 🐳 Vérification Docker..."

# Vérifier Docker
if command -v docker &> /dev/null; then
    echo "✅ Docker installé: $(docker --version)"
else
    echo "❌ Docker NON installé"
fi

# Vérifier Docker Compose
if command -v docker-compose &> /dev/null; then
    echo "✅ Docker Compose installé: $(docker-compose --version)"
else
    echo "❌ Docker Compose NON installé"
fi

# Vérifier les containers en cours
echo "🏃 Containers Docker actifs:"
docker ps 2>/dev/null || echo "Aucun container actif ou erreur Docker"

echo ""
echo "4. 🛠️ CORRECTION AUTOMATIQUE..."

# Créer le répertoire de sauvegarde
sudo mkdir -p $BACKUP_DIR

# Si le projet n'existe pas ou est incomplet, le réinstaller
if [ ! -f "$PROJECT_DIR/docker-compose.yml" ]; then
    echo "🔄 Réinstallation du projet MEKNOW..."
    
    # Créer le répertoire et définir les permissions
    sudo mkdir -p $PROJECT_DIR
    sudo chown $USER:$USER $PROJECT_DIR
    cd $PROJECT_DIR
    
    # Cloner le projet depuis GitHub
    echo "📦 Clonage depuis GitHub..."
    if [ -d ".git" ]; then
        git fetch origin
        git reset --hard origin/main
    else
        git clone https://github.com/yassineco/meknow.git .
    fi
    
    echo "✅ Projet réinstallé"
else
    echo "✅ Projet déjà présent et complet"
    cd $PROJECT_DIR
fi

echo ""
echo "5. ⚙️ Configuration de l'environnement..."

# Créer le fichier .env.production
cat > .env.production << 'EOL'
NODE_ENV=production

# Base de données PostgreSQL
DATABASE_URL=postgresql://postgres:meknow2024!@database:5432/meknow_production
DB_HOST=database
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=meknow2024!
DB_NAME=meknow_production

# API Configuration
API_URL=http://backend:9000
NEXT_PUBLIC_API_URL=https://meknow.fr/api

# Rubriques Management
ENABLE_RUBRIQUES=true
CATALOGUE_ENABLED=true
LOOKBOOK_ENABLED=true

# Sécurité
JWT_SECRET=meknow_prod_jwt_2024_ultra_secure_key_vps_fixed
BCRYPT_ROUNDS=12
COOKIE_SECRET=meknow_prod_cookie_2024_ultra_secure_key_vps

# Uploads et stockage
UPLOAD_PATH=/app/uploads
MAX_FILE_SIZE=10485760
ALLOWED_EXTENSIONS=jpg,jpeg,png,webp,gif

# Logs
LOG_LEVEL=info
LOG_FILE=/var/log/meknow/application.log
EOL

echo "✅ Fichier .env.production créé"

echo ""
echo "6. 🧹 Nettoyage Docker..."

# Arrêter les anciens containers
echo "🛑 Arrêt des containers existants..."
docker-compose down 2>/dev/null || true

# Nettoyer les containers/images orphelins
echo "🧹 Nettoyage des ressources Docker..."
docker system prune -f 2>/dev/null || true

echo ""
echo "7. 🚀 Redémarrage des services Docker..."

# Vérifier que nous sommes dans le bon répertoire
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ ERREUR: docker-compose.yml toujours introuvable!"
    echo "📍 Répertoire actuel: $(pwd)"
    echo "📋 Fichiers présents:"
    ls -la
    exit 1
fi

echo "✅ docker-compose.yml trouvé, démarrage des services..."

# Modifier les ports pour éviter les conflits
echo "🔧 Configuration des ports..."
cp docker-compose.yml docker-compose.yml.backup
sed -i 's/"3000:3000"/"3001:3000"/g' docker-compose.yml
sed -i 's/"9000:9000"/"9001:9000"/g' docker-compose.yml
sed -i 's/"5432:5432"/"5433:5432"/g' docker-compose.yml

# Démarrer les services
echo "🏁 Lancement des containers Docker..."
docker-compose --env-file .env.production up -d --build

echo ""
echo "8. ⏳ Attente du démarrage des services (30 secondes)..."
sleep 30

echo ""
echo "9. ✅ Vérifications finales..."

echo "📊 État des containers:"
docker-compose ps

echo ""
echo "🔍 Tests de connectivité:"

# Test Backend
if curl -s http://localhost:9001/health >/dev/null 2>&1; then
    echo "✅ Backend (port 9001): OK"
else
    echo "❌ Backend (port 9001): ERREUR"
fi

# Test Frontend  
if curl -s -I http://localhost:3001/ | head -n1 | grep -q "200\|404\|301"; then
    echo "✅ Frontend (port 3001): OK"
else
    echo "❌ Frontend (port 3001): ERREUR"
fi

# Test Admin
if curl -s -I http://localhost:8082/ | head -n1 | grep -q "200\|404\|301"; then
    echo "✅ Admin (port 8082): OK"
else
    echo "❌ Admin (port 8082): ERREUR"
fi

echo ""
echo "🔍 Vérification des ports utilisés:"
netstat -tulpn | grep -E ':3001|:9001|:8082|:5433' || echo "Aucun port actif détecté"

echo ""
echo "🎉 CORRECTION TERMINÉE!"
echo ""
echo "📋 RÉSUMÉ:"
echo "   📁 Projet: $PROJECT_DIR"
echo "   🐳 Docker Compose: $([ -f docker-compose.yml ] && echo "✅ OK" || echo "❌ MANQUANT")"
echo "   🏃 Services actifs: $(docker-compose ps --services | wc -l) containers"
echo ""
echo "🌐 URLs d'accès:"
echo "   Frontend: http://VOTRE_IP:3001"
echo "   Backend:  http://VOTRE_IP:9001"  
echo "   Admin:    http://VOTRE_IP:8082"
echo ""
echo "📝 Prochaines étapes si tout fonctionne:"
echo "   1. Configurer Nginx pour le domaine meknow.fr"
echo "   2. Installer SSL avec certbot"
echo "   3. Tester l'accès via https://meknow.fr"
echo ""
echo "🛠️ En cas de problème, consultez les logs:"
echo "   docker-compose logs"
echo "   docker-compose logs backend"  
echo "   docker-compose logs frontend"