#!/bin/bash

# 🆘 Script de correction d'urgence Docker
# Usage: ./emergency-fix.sh

echo "🆘 CORRECTION D'URGENCE DOCKER"
echo "=============================="

cd /var/www/meknow || exit 1

# 1. ARRÊT TOTAL
echo "1. 🛑 Arrêt total des services..."
docker-compose down --remove-orphans
docker stop $(docker ps -aq) 2>/dev/null || true
docker rm $(docker ps -aq) 2>/dev/null || true

# 2. NETTOYAGE RADICAL
echo "2. 🧹 Nettoyage radical Docker..."
docker system prune -af --volumes
docker network prune -f

# 3. PULL DERNIÈRE VERSION
echo "3. 📥 Récupération dernière version..."
git fetch origin
git reset --hard origin/main
git pull origin main

# 4. RECRÉER .ENV
echo "4. ⚙️ Configuration environnement..."
cat > .env.production << 'EOF'
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
CATALOGUE_ENABLED=true
LOOKBOOK_ENABLED=true
JWT_SECRET=meknow_prod_jwt_2024_ultra_secure_key_vps
BCRYPT_ROUNDS=12
EOF

# 5. S'ASSURER QUE LES FICHIERS EXISTENT
echo "5. 📁 Vérification fichiers nécessaires..."

# Créer public si manquant
mkdir -p menow-web/public

# Créer globals.css si manquant  
mkdir -p menow-web/src/styles
if [ ! -f "menow-web/src/styles/globals.css" ]; then
    cat > menow-web/src/styles/globals.css << 'EOF'
@tailwind base;
@tailwind components; 
@tailwind utilities;

body {
  font-family: 'Inter', sans-serif;
  background: #0B0B0C;
  color: #ffffff;
  margin: 0;
  padding: 0;
}

* {
  box-sizing: border-box;
}
EOF
fi

# 6. BUILD SIMPLE SANS CACHE
echo "6. 🏗️ Build simple sans cache..."
docker-compose --env-file .env.production build --no-cache --pull

# 7. DÉMARRAGE
echo "7. 🚀 Démarrage des services..."
docker-compose --env-file .env.production up -d

# 8. ATTENDRE
echo "8. ⏱️ Attente du démarrage complet..."
sleep 90

# 9. TESTS
echo "9. ✅ Tests de validation..."
echo "Services Docker:"
docker-compose ps

echo ""
echo "Tests des endpoints:"
curl -s http://localhost:9001/health 2>/dev/null && echo "✅ Backend OK" || echo "❌ Backend erreur"
curl -s -I http://localhost:3001/ 2>/dev/null | head -n1 | grep "200" && echo "✅ Frontend OK" || echo "❌ Frontend erreur"

# 10. NGINX
echo ""
echo "10. 🌐 Configuration Nginx finale..."
sudo systemctl restart nginx

echo ""
echo "🎉 CORRECTION D'URGENCE TERMINÉE!"
echo ""
echo "🌐 Testez maintenant: https://meknow.fr"
echo "👑 Admin: https://meknow.fr/admin"

echo ""
echo "📊 Si problème, voir les logs:"
echo "   docker-compose logs backend"
echo "   docker-compose logs frontend"