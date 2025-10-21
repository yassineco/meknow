#!/bin/bash

# 🚨 Script d'urgence - Correction Docker MEKNOW VPS
# Usage: ./emergency-docker-fix.sh

echo "🚨 CORRECTION D'URGENCE DOCKER - MEKNOW"
echo "====================================="

PROJECT_DIR="/var/www/meknow"

echo "1. 🔍 Localisation du problème..."

# Aller dans le bon répertoire
if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ Répertoire $PROJECT_DIR introuvable!"
    echo "🔄 Création et clonage du projet..."
    
    sudo mkdir -p $PROJECT_DIR
    sudo chown $USER:$USER $PROJECT_DIR
    cd $PROJECT_DIR
    
    git clone https://github.com/yassineco/meknow.git .
    echo "✅ Projet cloné"
else
    cd $PROJECT_DIR
    echo "✅ Dans le répertoire: $(pwd)"
fi

echo ""
echo "2. ⚡ Vérification docker-compose.yml..."

if [ ! -f "docker-compose.yml" ]; then
    echo "❌ docker-compose.yml manquant!"
    echo "📦 Re-téléchargement depuis GitHub..."
    
    # Télécharger directement le fichier
    curl -L https://raw.githubusercontent.com/yassineco/meknow/main/docker-compose.yml -o docker-compose.yml
    
    if [ -f "docker-compose.yml" ]; then
        echo "✅ docker-compose.yml téléchargé"
    else
        echo "❌ Échec du téléchargement"
        exit 1
    fi
else
    echo "✅ docker-compose.yml trouvé"
fi

echo ""
echo "3. 🛑 Arrêt des services existants..."

# Tuer tous les processus sur les ports critiques
for port in 80 443 3000 3001 9000 9001 5432 5433 8080 8082; do
    sudo fuser -k $port/tcp 2>/dev/null || true
done

# Arrêter Docker
docker-compose down 2>/dev/null || true
docker stop $(docker ps -aq) 2>/dev/null || true

echo ""
echo "4. ⚙️ Configuration express..."

# Créer .env minimal
cat > .env.production << 'EOL'
NODE_ENV=production
DATABASE_URL=postgresql://postgres:meknow2024!@database:5432/meknow_production
DB_HOST=database
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=meknow2024!
DB_NAME=meknow_production
API_URL=http://backend:9000
NEXT_PUBLIC_API_URL=https://meknow.fr/api
ENABLE_RUBRIQUES=true
JWT_SECRET=emergency_jwt_secret_2024
COOKIE_SECRET=emergency_cookie_secret_2024
EOL

echo ""
echo "5. 🚀 Démarrage Docker..."

# Modifier les ports
cp docker-compose.yml docker-compose.yml.backup 2>/dev/null || true
sed -i 's/"3000:3000"/"3001:3000"/g' docker-compose.yml
sed -i 's/"9000:9000"/"9001:9000"/g' docker-compose.yml

# Lancer Docker
echo "🐳 Lancement des containers..."
docker-compose --env-file .env.production up -d

echo ""
echo "6. ⏳ Test rapide (attente 20 sec)..."
sleep 20

docker-compose ps

echo ""
echo "🎯 CORRECTION D'URGENCE TERMINÉE!"
echo ""
echo "✅ Si vous voyez des containers 'Up', c'est bon!"
echo "❌ Si des containers sont 'Exited', consulter les logs:"
echo "    docker-compose logs"
echo ""
echo "🌐 Testez l'accès:"
echo "    curl http://localhost:3001"
echo "    curl http://localhost:9001/health"