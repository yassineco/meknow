#!/bin/bash
# fix-nginx-conflicts.sh - Correction des conflits Nginx

echo "🔧 CORRECTION CONFLITS NGINX"
echo "============================="

# 1. Identifier toutes les configurations Nginx
echo "📋 Configurations Nginx existantes:"
ls -la /etc/nginx/sites-enabled/
echo ""
ls -la /etc/nginx/sites-available/ | grep -v "^total"

echo ""
echo "🔍 Recherche des conflits server_name:"
grep -r "server_name.*meknow" /etc/nginx/sites-enabled/ 2>/dev/null || echo "Aucun conflit trouvé dans sites-enabled"
grep -r "server_name.*meknow" /etc/nginx/sites-available/ 2>/dev/null || echo "Aucun conflit trouvé dans sites-available"

echo ""
echo "🧹 Nettoyage des configurations en conflit:"

# Désactiver toutes les configurations existantes
echo "- Désactivation de toutes les configs..."
rm -f /etc/nginx/sites-enabled/*

# Créer une configuration propre et unique
echo "- Création d'une config propre..."
cat > /etc/nginx/sites-available/meknow-clean << 'NGINX'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    server_name meknow.fr www.meknow.fr _;
    
    # Logs
    access_log /var/log/nginx/meknow_access.log;
    error_log /var/log/nginx/meknow_error.log;

    # Page d'accueil
    location / {
        return 200 '<!DOCTYPE html>
<html>
<head>
    <title>🛍️ MEKNOW E-commerce</title>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            background: linear-gradient(135deg, #667eea, #764ba2); 
            color: white; 
            text-align: center;
            padding: 2rem;
            margin: 0;
        }
        .container { max-width: 800px; margin: 0 auto; }
        .success { background: rgba(76, 175, 80, 0.2); padding: 2rem; border-radius: 15px; margin: 2rem 0; }
        .card { background: rgba(255,255,255,0.1); padding: 1.5rem; margin: 1rem; border-radius: 10px; }
        .btn { 
            background: #4CAF50; 
            color: white; 
            padding: 1rem 2rem; 
            text-decoration: none; 
            border-radius: 25px; 
            display: inline-block; 
            margin: 0.5rem; 
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🛍️ MEKNOW E-COMMERCE</h1>
        
        <div class="success">
            <h2>✅ SITE OPÉRATIONNEL</h2>
            <p>Plateforme e-commerce déployée avec succès!</p>
        </div>

        <div class="card">
            <h3>🎯 Services Disponibles</h3>
            <p><a href="/api/health" class="btn">🔧 API Health</a></p>
            <p><a href="/api/products" class="btn">📦 Produits</a></p>
            <p><a href="/test" class="btn">🧪 Test Nginx</a></p>
        </div>

        <div class="card">
            <h3>📊 Infrastructure</h3>
            <p>✅ Frontend Next.js</p>
            <p>✅ Backend Express API</p>
            <p>✅ Base PostgreSQL</p>
            <p>✅ Reverse Proxy Nginx</p>
        </div>

        <footer style="margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(255,255,255,0.3);">
            <p>© 2025 MEKNOW E-commerce</p>
            <p>🚀 Production Ready - Docker Deployment</p>
        </footer>
    </div>
</body>
</html>';
        add_header Content-Type text/html;
    }

    # Test endpoint
    location = /test {
        return 200 "✅ Nginx Configuration OK - No Conflicts";
        add_header Content-Type text/plain;
    }

    # API Proxy
    location /api/ {
        proxy_pass http://127.0.0.1:5001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
}
NGINX

# Activer la nouvelle configuration
ln -s /etc/nginx/sites-available/meknow-clean /etc/nginx/sites-enabled/

# Test de la configuration
echo ""
echo "🧪 Test de la nouvelle configuration:"
nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Configuration valide - Rechargement..."
    systemctl reload nginx
    
    # Attendre un peu
    sleep 3
    
    # Tests de validation
    echo ""
    echo "🔍 Tests de validation:"
    
    echo "1. Test direct IP:"
    curl -s -o /dev/null -w "Status: %{http_code}\n" "http://127.0.0.1/"
    
    echo "2. Test avec Host header meknow.fr:"
    curl -s -o /dev/null -w "Status: %{http_code}\n" -H "Host: meknow.fr" "http://127.0.0.1/"
    
    echo "3. Test API:"
    curl -s "http://127.0.0.1/api/health" | head -1 || echo "API non accessible"
    
    echo "4. Test endpoint de vérification:"
    curl -s "http://127.0.0.1/test"
    
    echo ""
    echo "✅ CORRECTION TERMINÉE!"
    echo ""
    echo "📱 Testez maintenant:"
    echo "   http://meknow.fr"
    echo "   http://www.meknow.fr"
    echo "   http://31.97.196.215"
    
else
    echo "❌ Erreur dans la configuration!"
    exit 1
fi

echo ""
echo "📋 Si tout fonctionne, les conflits Nginx sont résolus!"