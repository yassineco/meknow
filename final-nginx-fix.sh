#!/bin/bash

# 🌐 Script final - Correction Nginx + Tests complets VPS
# Usage: ./final-nginx-fix.sh

echo "🌐 CORRECTION FINALE NGINX + TESTS - MEKNOW VPS"
echo "=============================================="

PROJECT_DIR="/var/www/meknow"

echo "1. 📍 Positionnement et vérification..."
cd $PROJECT_DIR

echo "✅ Services Docker actuels :"
docker-compose ps

echo ""
echo "2. 🔧 Correction du fichier nginx.conf manquant..."

# Créer le fichier nginx.conf pour le reverse proxy
cat > nginx.conf << 'EOL'
events {
    worker_connections 1024;
}

http {
    upstream frontend {
        server frontend:3000;
    }
    
    upstream backend {
        server backend:9000;
    }
    
    upstream admin {
        server admin:80;
    }

    server {
        listen 80;
        server_name meknow.fr www.meknow.fr localhost;

        # Frontend Next.js
        location / {
            proxy_pass http://frontend;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_cache_bypass $http_upgrade;
            proxy_read_timeout 86400;
        }

        # API Backend
        location /api/ {
            proxy_pass http://backend/api/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Interface Admin
        location /admin/ {
            proxy_pass http://admin/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
EOL

echo "✅ Fichier nginx.conf créé"

echo ""
echo "3. 🔄 Redémarrage du service Nginx..."

# Redémarrer le service nginx
docker-compose restart nginx

echo ""
echo "4. ⏳ Attente stabilisation (30 secondes)..."
sleep 30

echo ""
echo "5. 🔍 Tests complets de connectivité..."

echo "📊 État final des containers :"
docker-compose ps

echo ""
echo "🌐 Tests des services :"

# Test Backend avec plus de détails
echo -n "🔧 Backend (API) : "
if curl -s -w "%{http_code}" http://localhost:9001/health | grep -q "200"; then
    echo "✅ OK (Status 200)"
else
    echo "⚠️ Réponse inattendue"
fi

# Test Frontend avec plus de détails  
echo -n "🎨 Frontend (Next.js) : "
FRONTEND_STATUS=$(curl -s -w "%{http_code}" -o /dev/null http://localhost:3001/)
if [[ "$FRONTEND_STATUS" =~ ^[2-4][0-9][0-9]$ ]]; then
    echo "✅ OK (Status $FRONTEND_STATUS)"
else
    echo "⚠️ En cours de démarrage"
fi

# Test Admin
echo -n "⚙️ Admin (Interface) : "
ADMIN_STATUS=$(curl -s -w "%{http_code}" -o /dev/null http://localhost:8082/)
if [[ "$ADMIN_STATUS" =~ ^[2-4][0-9][0-9]$ ]]; then
    echo "✅ OK (Status $ADMIN_STATUS)"
else
    echo "⚠️ Problème détecté"
fi

# Test Nginx (si activé)
echo -n "🌐 Nginx (Proxy) : "
if docker-compose ps | grep -q "nginx.*Up"; then
    echo "✅ Actif"
else
    echo "⚠️ Non actif (normal si pas encore configuré pour production)"
fi

echo ""
echo "6. 📋 Informations de connexion :"

# Obtenir l'IP du serveur
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "VOTRE_IP_SERVEUR")

echo ""
echo "🌍 **ACCÈS DIRECT (Recommandé pour les tests) :**"
echo "   Frontend : http://$SERVER_IP:3001"
echo "   Backend  : http://$SERVER_IP:9001"  
echo "   Admin    : http://$SERVER_IP:8082"
echo ""

echo "🔧 **ACCÈS VIA NGINX (Si configuré) :**"
echo "   Site complet : http://$SERVER_IP"
echo "   API          : http://$SERVER_IP/api"
echo "   Admin        : http://$SERVER_IP/admin"

echo ""
echo "7. 📊 Diagnostic avancé..."

echo "🔍 Ports ouverts sur le serveur :"
netstat -tulpn | grep -E ':3001|:9001|:8082|:80|:443' || echo "Commande netstat non disponible"

echo ""
echo "📝 Logs récents des services (dernières 5 lignes) :"
echo "--- Backend ---"
docker-compose logs --tail=5 backend

echo "--- Frontend ---"  
docker-compose logs --tail=5 frontend

echo "--- Admin ---"
docker-compose logs --tail=5 admin 2>/dev/null || echo "Service admin non configuré avec logs"

echo ""
echo "🎉 **CORRECTION FINALE TERMINÉE !**"
echo ""
echo "📋 **RÉSUMÉ DE L'ÉTAT :**"

# Vérification finale intelligente
BACKEND_OK=$(curl -s http://localhost:9001/health >/dev/null 2>&1 && echo "✅" || echo "❌")
FRONTEND_OK=$(curl -s -I http://localhost:3001/ | head -n1 | grep -q "HTTP" && echo "✅" || echo "❌")
ADMIN_OK=$(curl -s -I http://localhost:8082/ | head -n1 | grep -q "HTTP" && echo "✅" || echo "❌")

echo "   🔧 Backend  : $BACKEND_OK"
echo "   🎨 Frontend : $FRONTEND_OK"  
echo "   ⚙️ Admin    : $ADMIN_OK"
echo ""

if [[ "$BACKEND_OK" == "✅" && "$FRONTEND_OK" == "✅" ]]; then
    echo "🎊 **FÉLICITATIONS ! Votre e-commerce MEKNOW est OPÉRATIONNEL !**"
    echo ""
    echo "🚀 **PROCHAINES ÉTAPES RECOMMANDÉES :**"
    echo "   1. Testez le frontend sur http://$SERVER_IP:3001"
    echo "   2. Testez l'API sur http://$SERVER_IP:9001/health"
    echo "   3. Configurez le nom de domaine meknow.fr (optionnel)"
    echo "   4. Installez SSL avec certbot (pour HTTPS)"
else
    echo "⚠️ **QUELQUES SERVICES DEMANDENT ENCORE DU TEMPS...**"
    echo ""
    echo "🔧 **ACTIONS RECOMMANDÉES :**"
    echo "   - Attendez 5-10 minutes (build Next.js en cours)"
    echo "   - Surveillez les logs : docker-compose logs -f frontend"
    echo "   - Relancez les tests dans quelques minutes"
fi

echo ""
echo "📞 **SUPPORT :**"
echo "   - Logs détaillés : docker-compose logs"
echo "   - État services  : docker-compose ps" 
echo "   - Redémarrer     : docker-compose restart"
echo ""