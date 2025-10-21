#!/bin/bash

# 🌐 Force IPv4 configuration - MEKNOW VPS
# Usage: ./force-ipv4.sh

echo "🌐 CONFIGURATION FORCÉE IPv4 - MEKNOW VPS"
echo "========================================"

PROJECT_DIR="/var/www/meknow"

echo "1. 📊 Diagnostic de la configuration réseau actuelle..."

echo "🔍 Adresses IP disponibles :"
ip addr show | grep -E "inet |inet6 " | head -10

echo ""
echo "🔍 Configuration Docker réseau :"
docker network ls

echo ""
echo "2. 🔧 Configuration système pour préférer IPv4..."

# Configurer gai.conf pour privilégier IPv4
if ! grep -q "precedence ::ffff:0:0/96 100" /etc/gai.conf 2>/dev/null; then
    echo "📝 Ajout configuration IPv4 priority..."
    echo 'precedence ::ffff:0:0/96 100' | sudo tee -a /etc/gai.conf
    echo "✅ IPv4 priority configurée"
else
    echo "✅ IPv4 priority déjà configurée"
fi

echo ""
echo "3. 🐳 Reconfiguration Docker pour IPv4 uniquement..."

cd $PROJECT_DIR

# Sauvegarder docker-compose.yml
cp docker-compose.yml docker-compose.yml.backup.ipv6

# Créer une nouvelle configuration réseau IPv4 seulement
cat > docker-compose-ipv4.yml << 'EOL'
version: '3.8'

networks:
  meknow-network:
    driver: bridge
    enable_ipv6: false
    ipam:
      driver: default
      config:
        - subnet: 172.20.0.0/16
          ip_range: 172.20.240.0/20

services:
  # Base de données PostgreSQL
  database:
    image: postgres:15-alpine
    container_name: meknow-postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: meknow_production
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: meknow2024!
      PGDATA: /var/lib/postgresql/data/pgdata
    volumes:
      - postgres_data:/var/lib/postgresql/data/pgdata
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    ports:
      - "127.0.0.1:5433:5432"
    networks:
      - meknow-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres -d meknow_production"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Backend Express.js
  backend:
    build:
      context: .
      dockerfile: Dockerfile.backend
    container_name: meknow-backend
    restart: unless-stopped
    environment:
      NODE_ENV: production
      PORT: 9000
      DATABASE_URL: postgresql://postgres:meknow2024!@database:5432/meknow_production
      DB_HOST: database
      DB_PORT: 5432
      DB_USER: postgres
      DB_PASS: meknow2024!
      DB_NAME: meknow_production
      JWT_SECRET: ${JWT_SECRET:-meknow-jwt-secret-2024}
      COOKIE_SECRET: ${COOKIE_SECRET:-meknow-cookie-secret-2024}
      ENABLE_RUBRIQUES: "true"
      ENABLE_LOOKBOOK: "true"
      ENABLE_ADMIN_INTERFACE: "true"
    ports:
      - "127.0.0.1:9001:9000"
    volumes:
      - ./uploads:/app/uploads
      - ./logs:/app/logs
    depends_on:
      database:
        condition: service_healthy
    networks:
      - meknow-network

  # Frontend Next.js
  frontend:
    build:
      context: ./menow-web
      dockerfile: Dockerfile.corrected
      args:
        NEXT_PUBLIC_API_URL: http://backend:9000
    container_name: meknow-frontend
    restart: unless-stopped
    environment:
      NODE_ENV: production
      PORT: 3000
      NEXT_PUBLIC_API_URL: http://31.97.196.215:9001
      API_URL: http://backend:9000
      ENABLE_RUBRIQUES: "true"
      ENABLE_LOOKBOOK: "true"
    ports:
      - "0.0.0.0:3001:3000"
    depends_on:
      - backend
    networks:
      - meknow-network

  # Interface Admin
  admin:
    image: nginx:alpine
    container_name: meknow-admin
    restart: unless-stopped
    volumes:
      - ./admin-complete-ecommerce.html:/usr/share/nginx/html/admin-complete-ecommerce.html:ro
      - ./admin-complete-ecommerce.html:/usr/share/nginx/html/index.html:ro
      - ./assets:/usr/share/nginx/html/assets:ro
    ports:
      - "127.0.0.1:8082:80"
    networks:
      - meknow-network

volumes:
  postgres_data:
    driver: local
EOL

echo "4. 🛑 Arrêt des services actuels..."
docker-compose down

echo "5. 🧹 Nettoyage réseau Docker..."
docker network prune -f

echo "6. 🚀 Redémarrage avec configuration IPv4..."
docker-compose -f docker-compose-ipv4.yml --env-file .env.production up -d

echo ""
echo "7. ⏳ Attente stabilisation (30 secondes)..."
sleep 30

echo ""
echo "8. 🔍 Vérification IPv4..."

echo "📊 État des containers :"
docker-compose -f docker-compose-ipv4.yml ps

echo ""
echo "🌐 Tests IPv4 :"

# Test explicite IPv4
IPV4="31.97.196.215"
echo -n "Frontend IPv4 ($IPV4:3001): "
if curl -4 -s --connect-timeout 5 http://$IPV4:3001 >/dev/null 2>&1; then
    echo "✅ OK"
else
    echo "⚠️ En attente"
fi

echo -n "Backend IPv4 ($IPV4:9001): "
if curl -4 -s --connect-timeout 5 http://$IPV4:9001/health >/dev/null 2>&1; then
    echo "✅ OK"  
else
    echo "⚠️ En attente"
fi

echo ""
echo "🎯 URLS IPv4 FORCÉES :"
echo "   Frontend: http://$IPV4:3001"
echo "   Backend:  http://$IPV4:9001/health"
echo "   Admin:    http://$IPV4:8082"

echo ""
echo "✅ Configuration IPv4 terminée !"
echo ""
echo "📝 Pour revenir à l'ancienne config :"
echo "   docker-compose -f docker-compose.yml.backup.ipv6 up -d"