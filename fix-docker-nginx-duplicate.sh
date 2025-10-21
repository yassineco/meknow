#!/bin/bash

# 🔧 CORRECTION DOCKER-COMPOSE - SUPPRESSION NGINX DUPLIQUÉ
# Corrige l'erreur "mapping key nginx already defined"

echo "🔧 CORRECTION DOCKER-COMPOSE - NGINX DUPLIQUÉ..."

PROJECT_DIR="/var/www/meknow"
cd $PROJECT_DIR

echo "📋 Sauvegarde du docker-compose.yml actuel..."
cp docker-compose.yml docker-compose.yml.backup-$(date +%Y%m%d_%H%M%S)

echo "🧹 Nettoyage des sections nginx dupliquées..."

# Créer un docker-compose.yml propre
cat > docker-compose.yml << 'EOF'
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
      - "5433:5432"
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
      JWT_SECRET: ${JWT_SECRET:-your-super-secret-jwt-key-change-this}
      COOKIE_SECRET: ${COOKIE_SECRET:-your-super-secret-cookie-key-change-this}
      ENABLE_RUBRIQUES: "true"
      ENABLE_LOOKBOOK: "true"
      ENABLE_ADMIN_INTERFACE: "true"
    ports:
      - "9001:9000"
    volumes:
      - ./uploads:/app/uploads
      - ./logs:/app/logs
    depends_on:
      database:
        condition: service_healthy
    networks:
      - meknow-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Frontend Next.js
  frontend:
    build:
      context: ./menow-web
      dockerfile: Dockerfile
    container_name: meknow-frontend
    restart: unless-stopped
    environment:
      NODE_ENV: production
      PORT: 3000
      NEXT_PUBLIC_API_URL: http://backend:9000
      API_URL: http://backend:9000
      ENABLE_RUBRIQUES: "true"
      ENABLE_LOOKBOOK: "true"
    ports:
      - "3001:3000"
    depends_on:
      - backend
    networks:
      - meknow-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Interface Admin
  admin:
    image: nginx:alpine
    container_name: meknow-admin
    restart: unless-stopped
    volumes:
      - ./admin-complete-ecommerce.html:/usr/share/nginx/html/admin-complete-ecommerce.html:ro
      - ./admin-complete-ecommerce.html:/usr/share/nginx/html/index.html:ro
      - ./assets:/usr/share/nginx/html/assets:ro
      - ./nginx-admin.conf:/etc/nginx/conf.d/default.conf:ro
    ports:
      - "8082:80"
    networks:
      - meknow-network

  # Nginx Reverse Proxy pour domaine
  nginx:
    image: nginx:alpine
    container_name: meknow-nginx
    restart: unless-stopped
    ports:
      - "80:80"
    volumes:
      - ./nginx-production.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - frontend
      - backend
      - admin
    networks:
      - meknow-network

volumes:
  postgres_data:
    driver: local

networks:
  meknow-network:
    driver: bridge
EOF

echo "✅ Docker-compose.yml corrigé"

# Créer la configuration Nginx production
cat > nginx-production.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    
    # Serveur principal pour meknow.fr
    server {
        listen 80;
        server_name meknow.fr www.meknow.fr;
        
        # Frontend Next.js
        location / {
            proxy_pass http://frontend:3000;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
        
        # API Backend
        location /api/ {
            proxy_pass http://backend:9000/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
        
        # Interface Admin
        location /admin {
            proxy_pass http://admin:80;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
    }
}
EOF

echo "✅ Configuration Nginx créée"

# Redémarrer les services
echo "🚀 Redémarrage des services..."
docker-compose down
docker-compose up -d --build

echo ""
echo "📊 VÉRIFICATION DES SERVICES:"
docker-compose ps

echo ""
echo "🌐 VOTRE SITE MEKNOW E-COMMERCE:"
echo "┌─────────────────────────────────────────────────────────────┐"
echo "│  🌍 Domaine: http://meknow.fr                              │"
echo "│  🔗 IP directe: http://31.97.196.215                       │"
echo "│  🛠️  Admin: http://meknow.fr/admin                          │"
echo "│  ⚡ API: http://meknow.fr/api                              │"
echo "└─────────────────────────────────────────────────────────────┘"

echo ""
echo "✅ CORRECTION TERMINÉE - ARCHITECTURE COMPLÈTE DÉPLOYÉE !"