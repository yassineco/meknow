#!/bin/bash

# 🌐 Configuration domaine meknow.fr - VPS Production
# Usage: ./configure-domain.sh

echo "🌐 CONFIGURATION DOMAINE MEKNOW.FR - PRODUCTION"
echo "=============================================="

PROJECT_DIR="/var/www/meknow"

echo "1. 🔍 Vérification de la configuration actuelle..."

# Obtenir l'IP du serveur
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "IMPOSSIBLE_DETECTER_IP")
echo "📡 IP du serveur: $SERVER_IP"

# Vérifier si Nginx est installé sur le système
if command -v nginx &> /dev/null; then
    echo "✅ Nginx système détecté"
    NGINX_SYSTEM=true
else
    echo "ℹ️ Nginx système non installé (utilisation Docker uniquement)"
    NGINX_SYSTEM=false
fi

echo ""
echo "2. 🛠️ Configuration Nginx pour meknow.fr..."

cd $PROJECT_DIR

# Méthode A: Configuration Nginx système (si disponible)
if [ "$NGINX_SYSTEM" = true ]; then
    echo "🔧 Configuration Nginx système..."
    
    # Créer la configuration pour meknow.fr
    sudo tee /etc/nginx/sites-available/meknow.fr > /dev/null << EOL
server {
    listen 80;
    server_name meknow.fr www.meknow.fr;

    # Frontend Next.js (port 3001)
    location / {
        proxy_pass http://127.0.0.1:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 86400;
    }

    # API Backend (port 9001)
    location /api/ {
        proxy_pass http://127.0.0.1:9001/api/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 30s;
    }

    # Interface Admin (port 8082)
    location /admin/ {
        proxy_pass http://127.0.0.1:8082/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Logs
    access_log /var/log/nginx/meknow.access.log;
    error_log /var/log/nginx/meknow.error.log;
}
EOL

    # Activer le site
    sudo ln -sf /etc/nginx/sites-available/meknow.fr /etc/nginx/sites-enabled/
    
    # Désactiver le site par défaut
    sudo rm -f /etc/nginx/sites-enabled/default
    
    # Tester la configuration
    sudo nginx -t
    
    if [ $? -eq 0 ]; then
        echo "✅ Configuration Nginx valide"
        sudo systemctl reload nginx
        echo "✅ Nginx rechargé"
    else
        echo "❌ Erreur dans la configuration Nginx"
    fi
fi

# Méthode B: Mise à jour du docker-compose pour gérer le domaine
echo ""
echo "🐳 Mise à jour de la configuration Docker..."

# Créer un nginx.conf pour le container nginx
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

    # Redirection vers HTTPS (si SSL configuré)
    server {
        listen 80;
        server_name meknow.fr www.meknow.fr;
        
        # Redirection temporaire vers les ports de dev
        return 301 http://\$server_name:3001\$request_uri;
    }

    # Configuration principale
    server {
        listen 8080;
        server_name meknow.fr www.meknow.fr localhost;

        # Frontend Next.js
        location / {
            proxy_pass http://frontend;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            proxy_cache_bypass \$http_upgrade;
        }

        # API Backend
        location /api/ {
            proxy_pass http://backend/api/;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }

        # Interface Admin
        location /admin/ {
            proxy_pass http://admin/;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }
}
EOL

# Redémarrer le service nginx docker
docker-compose restart nginx 2>/dev/null || echo "ℹ️ Service nginx Docker non présent"

echo ""
echo "3. 🌍 Vérification DNS et connectivité..."

echo "🔍 Résolution DNS de meknow.fr :"
nslookup meknow.fr 2>/dev/null || dig meknow.fr 2>/dev/null || echo "❌ Commandes DNS non disponibles"

echo ""
echo "🔍 Test de connectivité locale :"
curl -s -I http://localhost:3001/ | head -n1 || echo "❌ Frontend local non accessible"
curl -s -I http://localhost:9001/health || echo "❌ Backend local non accessible"

echo ""
echo "4. 📋 RÉSUMÉ ET PROCHAINES ÉTAPES..."

echo ""
echo "🎯 **ACCÈS ACTUELLEMENT FONCTIONNEL :**"
echo "   Frontend: http://$SERVER_IP:3001"
echo "   Backend:  http://$SERVER_IP:9001/health"
echo "   Admin:    http://$SERVER_IP:8082"

echo ""
echo "🌐 **POUR FAIRE FONCTIONNER meknow.fr :**"
echo ""
echo "1. 📡 **Configuration DNS** (À faire chez votre registrar de domaine) :"
echo "   - Créer un enregistrement A : meknow.fr → $SERVER_IP"
echo "   - Créer un enregistrement A : www.meknow.fr → $SERVER_IP"
echo ""

echo "2. 🔒 **Installation SSL** (Après DNS configuré) :"
echo "   sudo apt install certbot python3-certbot-nginx"
echo "   sudo certbot --nginx -d meknow.fr -d www.meknow.fr"
echo ""

echo "3. ⚡ **Test immédiat** :"
echo "   - Utilisez http://$SERVER_IP:3001 pour tester maintenant"
echo "   - Attendez la propagation DNS (1-24h) pour meknow.fr"

echo ""
echo "🚨 **IMPORTANT :**"
echo "   Le domaine meknow.fr doit pointer vers $SERVER_IP"
echo "   Vérifiez chez votre provider de domaine (OVH, Gandi, etc.)"

echo ""
echo "✅ Configuration terminée !"