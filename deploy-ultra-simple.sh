#!/bin/bash
# deploy-ultra-simple.sh - Solution ULTRA SIMPLE sans GitHub

echo "🚀 DÉPLOIEMENT ULTRA SIMPLE MEKNOW"
echo "=================================="

# Mise à jour système
echo "📦 Mise à jour système..."
apt update && apt upgrade -y

# Installation Docker
if ! command -v docker &> /dev/null; then
    echo "🐳 Installation Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    systemctl enable docker
    systemctl start docker
fi

# Installation Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "🔧 Installation Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi

# Nettoyage total
echo "🧹 Nettoyage complet..."
cd /root
rm -rf menow
docker system prune -af --volumes

# Création du projet minimal
echo "📁 Création projet minimal..."
mkdir -p menow
cd menow

# Docker Compose ultra-simple
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: meknow_db
      POSTGRES_USER: meknow_user
      POSTGRES_PASSWORD: meknow_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  backend:
    image: node:18-alpine
    working_dir: /app
    command: sh -c "
      echo 'const express = require(\"express\"); 
      const cors = require(\"cors\");
      const app = express();
      app.use(cors());
      app.use(express.json());
      app.get(\"/api/health\", (req, res) => res.json({status: \"OK\", service: \"MEKNOW API\"}));
      app.get(\"/api/products\", (req, res) => res.json([{id:1, name:\"Produit Test\", price:99.99}]));
      app.listen(5001, () => console.log(\"🔧 Backend running on port 5001\"));' > server.js &&
      npm init -y &&
      npm install express cors &&
      node server.js"
    ports:
      - "5001:5001"
    depends_on:
      - postgres

  frontend:
    image: node:18-alpine
    working_dir: /app
    command: sh -c "
      npx create-next-app@latest . --typescript --tailwind --app --src-dir --import-alias='@/*' --use-npm --no-git --yes &&
      echo 'export default function Home() {
        return (
          <div className=\"min-h-screen bg-gray-900 text-white p-8\">
            <div className=\"max-w-4xl mx-auto text-center\">
              <h1 className=\"text-6xl font-bold mb-8\">🛍️ MEKNOW</h1>
              <h2 className=\"text-3xl mb-6\">E-COMMERCE PLATFORM</h2>
              <div className=\"grid grid-cols-1 md:grid-cols-3 gap-6\">
                <div className=\"bg-blue-900 p-6 rounded-lg\">
                  <h3 className=\"text-xl font-bold mb-4\">🎨 Frontend</h3>
                  <p>Next.js 14 + Tailwind</p>
                </div>
                <div className=\"bg-green-900 p-6 rounded-lg\">
                  <h3 className=\"text-xl font-bold mb-4\">🔧 Backend</h3>
                  <p>Express.js API</p>
                </div>
                <div className=\"bg-purple-900 p-6 rounded-lg\">
                  <h3 className=\"text-xl font-bold mb-4\">🗄️ Database</h3>
                  <p>PostgreSQL</p>
                </div>
              </div>
              <div className=\"mt-8 space-x-4\">
                <a href=\"/api/health\" className=\"bg-blue-600 px-6 py-3 rounded-lg inline-block\">API Status</a>
                <a href=\"/api/products\" className=\"bg-green-600 px-6 py-3 rounded-lg inline-block\">Products</a>
              </div>
            </div>
          </div>
        )
      }' > src/app/page.tsx &&
      npm run build &&
      npm start"
    ports:
      - "3000:3000"
    depends_on:
      - backend

  admin:
    image: nginx:alpine
    command: sh -c "
      echo '<html><head><title>MEKNOW Admin</title></head>
      <body style=\"background:#1a1a2e;color:white;font-family:Arial;padding:2rem;text-align:center\">
        <h1>👑 MEKNOW ADMIN</h1>
        <h2>Interface d'\''Administration</h2>
        <div style=\"margin:2rem;padding:1rem;background:#16213e;border-radius:8px\">
          <h3>🛍️ Gestion E-commerce</h3>
          <p>Dashboard administrateur opérationnel</p>
        </div>
        <a href=\"/\" style=\"background:#4CAF50;color:white;padding:1rem 2rem;text-decoration:none;border-radius:4px\">
          Retour au site
        </a>
      </body></html>' > /usr/share/nginx/html/index.html &&
      nginx -g 'daemon off;'"
    ports:
      - "8080:80"

volumes:
  postgres_data:
EOF

# Installation Nginx pour reverse proxy
echo "🌐 Configuration Nginx..."
apt install -y nginx

# Configuration Nginx
cat > /etc/nginx/sites-available/meknow << 'EOF'
server {
    listen 80;
    server_name meknow.fr www.meknow.fr;

    # Frontend Next.js
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # API Backend
    location /api/ {
        proxy_pass http://localhost:5001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Admin Interface
    location /admin/ {
        proxy_pass http://localhost:8080/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Activation Nginx
ln -sf /etc/nginx/sites-available/meknow /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

# Démarrage des services
echo "🚀 Démarrage des services..."
docker-compose up -d

# Attente du démarrage
echo "⏳ Attente du démarrage (60s)..."
sleep 60

# Vérification finale
echo "🔍 Vérification des services:"
echo "==============================="

# Test des ports
nc -zv localhost 3000 && echo "✅ Frontend (3000) - OK" || echo "❌ Frontend (3000) - KO"
nc -zv localhost 5001 && echo "✅ Backend (5001) - OK" || echo "❌ Backend (5001) - KO"  
nc -zv localhost 8080 && echo "✅ Admin (8080) - OK" || echo "❌ Admin (8080) - KO"
nc -zv localhost 5432 && echo "✅ Database (5432) - OK" || echo "❌ Database (5432) - KO"

echo ""
echo "📊 Status Docker:"
docker-compose ps

echo ""
echo "🌐 Tests HTTP:"
curl -s -o /dev/null -w "Frontend: %{http_code}\n" http://localhost:3000 || echo "Frontend: ERREUR"
curl -s -o /dev/null -w "Backend: %{http_code}\n" http://localhost:5001/api/health || echo "Backend: ERREUR"
curl -s -o /dev/null -w "Admin: %{http_code}\n" http://localhost:8080 || echo "Admin: ERREUR"

echo ""
echo "🎉 DÉPLOIEMENT TERMINÉ!"
echo "========================"
echo "🌐 Site: http://meknow.fr"
echo "👑 Admin: http://meknow.fr/admin"  
echo "🔧 API: http://meknow.fr/api/health"

echo ""
echo "📋 Logs en cas de problème:"
echo "docker-compose logs frontend"
echo "docker-compose logs backend"
echo "docker-compose logs admin"