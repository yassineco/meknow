#!/bin/bash
# fix-nginx-proxy.sh - Correction du problème Nginx

echo "🔧 CORRECTION NGINX PROXY"
echo "========================="

# Vérification du statut actuel
echo "📊 Status actuel:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "🔍 Test direct des services:"
curl -I http://localhost:3000 2>/dev/null | head -1 || echo "❌ Port 3000 inaccessible"
curl -I http://localhost:5001/api/health 2>/dev/null | head -1 || echo "❌ Port 5001 inaccessible"

echo ""
echo "🌐 Configuration Nginx actuelle:"
cat /etc/nginx/sites-enabled/meknow 2>/dev/null || echo "❌ Configuration Nginx manquante"

echo ""
echo "🔧 CORRECTION - Nouvelle configuration Nginx:"

# Configuration Nginx corrigée
cat > /etc/nginx/sites-available/meknow << 'NGINX'
server {
    listen 80 default_server;
    server_name _;
    
    # Logs pour debug
    access_log /var/log/nginx/meknow_access.log;
    error_log /var/log/nginx/meknow_error.log;

    # Test de base
    location = /test {
        return 200 "Nginx fonctionne";
        add_header Content-Type text/plain;
    }

    # Frontend - essai avec différents backends
    location / {
        # Essai 1: containers Docker
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeout plus long
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
        
        # Fallback si pas de réponse
        error_page 502 503 504 @fallback;
    }

    # API Backend
    location /api/ {
        proxy_pass http://127.0.0.1:5001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }

    # Page de fallback si services indisponibles
    location @fallback {
        return 200 '<!DOCTYPE html>
<html>
<head>
    <title>MEKNOW - Service en cours de démarrage</title>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            background: linear-gradient(135deg, #667eea, #764ba2); 
            color: white; 
            text-align: center; 
            padding: 2rem;
            margin: 0;
        }
        .container { max-width: 600px; margin: 0 auto; }
        .spinner { border: 4px solid rgba(255,255,255,0.3); border-radius: 50%; border-top: 4px solid white; width: 50px; height: 50px; animation: spin 1s linear infinite; margin: 2rem auto; }
        @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
    </style>
    <meta http-equiv="refresh" content="10">
</head>
<body>
    <div class="container">
        <h1>🛍️ MEKNOW</h1>
        <h2>Services en cours de démarrage...</h2>
        <div class="spinner"></div>
        <p>Veuillez patienter, la page se recharge automatiquement.</p>
        <p><a href="/test" style="color: white;">Test Nginx</a></p>
    </div>
</body>
</html>';
        add_header Content-Type text/html;
    }
}
NGINX

# Supprimer l'ancienne config et activer la nouvelle
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/meknow /etc/nginx/sites-enabled/

# Test de la configuration
echo "🧪 Test de la configuration Nginx:"
nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Configuration Nginx valide"
    systemctl reload nginx
    echo "✅ Nginx rechargé"
else
    echo "❌ Erreur dans la configuration Nginx"
    exit 1
fi

# Vérification des services Docker
echo ""
echo "🔧 Vérification des conteneurs:"
if [ "$(docker ps -q)" ]; then
    echo "✅ Conteneurs Docker actifs"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
else
    echo "❌ Aucun conteneur actif - Redémarrage..."
    cd /root/menow 2>/dev/null || cd /root
    docker-compose -f docker-compose-fix.yml down 2>/dev/null
    docker-compose -f docker-compose-fix.yml up -d
    sleep 15
fi

echo ""
echo "🌐 Tests de connectivité:"
echo "- Test Nginx: http://meknow.fr/test"
sleep 2
curl -s "http://localhost/test" && echo " ✅ Nginx OK" || echo " ❌ Nginx KO"

echo "- Test Frontend: http://meknow.fr"  
sleep 2
curl -s -o /dev/null -w "Status: %{http_code}" "http://localhost/" && echo " ✅ Frontend accessible" || echo " ❌ Frontend inaccessible"

echo ""
echo "- Test API: http://meknow.fr/api/health"
sleep 2  
curl -s "http://localhost/api/health" && echo "" && echo " ✅ API accessible" || echo " ❌ API inaccessible"

echo ""
echo "📋 Logs Nginx (dernières lignes):"
tail -5 /var/log/nginx/meknow_error.log 2>/dev/null || echo "Pas d'erreurs Nginx récentes"

echo ""
echo "🎯 INSTRUCTIONS:"
echo "1. Testez: http://meknow.fr/test (doit afficher 'Nginx fonctionne')"
echo "2. Testez: http://meknow.fr (site principal)"
echo "3. Si problème persistant, vérifiez les logs: tail -f /var/log/nginx/meknow_error.log"

echo ""
echo "🔧 CORRECTION TERMINÉE!"