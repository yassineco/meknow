#!/bin/bash

# 🚀 Script de correction rapide - ERREURS NEXT.JS VPS
# Usage: ./quick-fix-nextjs.sh

echo "🚀 CORRECTION RAPIDE ERREURS NEXT.JS - MEKNOW VPS"
echo "==============================================="

PROJECT_DIR="/var/www/meknow"

echo "1. 📍 Positionnement dans le projet..."
cd $PROJECT_DIR || exit 1

echo "2. 🛑 Arrêt des services Docker..."
docker-compose down

echo "3. 🔧 Mise à jour du docker-compose pour utiliser Dockerfile corrigé..."

# Sauvegarder l'original
cp docker-compose.yml docker-compose.yml.backup

# Modifier pour utiliser le Dockerfile corrigé
sed -i 's|dockerfile: Dockerfile|dockerfile: Dockerfile.corrected|g' docker-compose.yml

echo "4. 📦 Téléchargement du Dockerfile corrigé depuis GitHub..."

# Télécharger le nouveau Dockerfile
curl -L https://raw.githubusercontent.com/yassineco/meknow/main/menow-web/Dockerfile.corrected -o menow-web/Dockerfile.corrected

echo "5. 🧹 Nettoyage des images Docker corrompues..."

# Nettoyer les images/containers du frontend
docker rmi $(docker images | grep menow | awk '{print $3}') 2>/dev/null || true
docker system prune -f

echo "6. 🚀 Reconstruction du frontend avec le Dockerfile corrigé..."

# Reconstruire uniquement le frontend
docker-compose build --no-cache frontend

echo "7. 🏁 Redémarrage de tous les services..."

# Redémarrer tous les services
docker-compose --env-file .env.production up -d

echo ""
echo "8. ⏳ Attente du démarrage (90 secondes - le build Next.js peut être long)..."
sleep 90

echo ""
echo "9. 📊 Vérification de l'état des services..."

docker-compose ps

echo ""
echo "10. 🔍 Tests de connectivité..."

# Test Backend
echo -n "Backend (port 9001): "
if curl -s http://localhost:9001/health >/dev/null 2>&1; then
    echo "✅ OK"
else
    echo "❌ ERREUR"
fi

# Test Frontend
echo -n "Frontend (port 3001): "
if timeout 15 curl -s -I http://localhost:3001/ | head -n1 | grep -q "200\|404\|301\|500"; then
    echo "✅ OK (Répondant)"
else
    echo "⚠️ En cours de démarrage"
fi

# Test Admin
echo -n "Admin (port 8082): "
if curl -s -I http://localhost:8082/ | head -n1 | grep -q "200\|404\|301"; then
    echo "✅ OK"
else
    echo "❌ ERREUR"
fi

echo ""
echo "🔍 Logs récents du frontend (si erreurs):"
docker-compose logs --tail=10 frontend

echo ""
echo "🎉 CORRECTION RAPIDE TERMINÉE!"
echo ""
echo "📋 RÉSUMÉ:"
echo "   🐳 Dockerfile corrigé utilisé"
echo "   🔄 Images reconstruites proprement"
echo "   ⚡ Services redémarrés"
echo ""
echo "🌐 Testez maintenant:"
echo "   Frontend: http://VOTRE_IP:3001"
echo "   Backend:  http://VOTRE_IP:9001/health"
echo "   Admin:    http://VOTRE_IP:8082"
echo ""
echo "⚠️ Si le frontend ne répond pas immédiatement:"
echo "   - Le build Next.js peut prendre 5-10 minutes"
echo "   - Surveillez les logs: docker-compose logs -f frontend"
echo "   - Retestez dans quelques minutes"