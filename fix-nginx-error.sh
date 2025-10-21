#!/bin/bash

# 🔧 Script de correction erreur Nginx VPS
# Usage: ./fix-nginx-error.sh

echo "🔧 CORRECTION ERREUR NGINX VPS"
echo "=============================="

# 1. Démarrer Nginx
echo "1. 🚀 Démarrage de Nginx..."
sudo systemctl start nginx
sudo systemctl enable nginx

# 2. Vérifier l'état
echo "2. 🔍 Vérification de l'état Nginx..."
sudo systemctl status nginx --no-pager

# 3. Tester la configuration
echo "3. ⚙️ Test de la configuration..."
sudo nginx -t

# 4. Continuer le déploiement Docker
echo "4. 🐳 Continuation du déploiement Docker..."
cd /var/www/meknow

# Vérifier si docker-compose.yml existe
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ docker-compose.yml non trouvé, re-clonage nécessaire..."
    cd /var/www/
    sudo rm -rf meknow
    sudo mkdir -p meknow
    sudo chown $USER:$USER meknow
    cd meknow
    git clone https://github.com/yassineco/meknow.git .
fi

# 5. Créer .env.production si manquant
if [ ! -f ".env.production" ]; then
    echo "5. ⚙️ Création .env.production..."
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
CATALOGUE_ENABLED=true
LOOKBOOK_ENABLED=true
JWT_SECRET=meknow_prod_jwt_2024_ultra_secure_key_vps
BCRYPT_ROUNDS=12
EOL
fi

# 6. Modifier les ports pour éviter les conflits
echo "6. 🔧 Configuration des ports..."
sed -i 's/"3000:3000"/"3001:3000"/g' docker-compose.yml
sed -i 's/"9000:9000"/"9001:9000"/g' docker-compose.yml  
sed -i 's/"5432:5432"/"5433:5432"/g' docker-compose.yml

# 7. Déployer avec Docker
echo "7. 🚀 Déploiement Docker..."
docker-compose --env-file .env.production up -d --build

# 8. Attendre le démarrage
echo "8. ⏱️ Attente du démarrage des services..."
sleep 30

# 9. Vérifications
echo "9. ✅ Vérifications finales..."
docker-compose ps
echo ""
echo "Test des services:"
curl -s http://localhost:9001/health && echo " ✅ Backend OK" || echo " ❌ Backend erreur"
curl -s -I http://localhost:3001/ | head -n1 && echo "✅ Frontend répondant" || echo " ❌ Frontend erreur"

echo ""
echo "🎉 CORRECTION TERMINÉE!"
echo "🌐 Testez: https://meknow.fr"