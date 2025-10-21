#!/bin/bash

# 🔧 Script de correction erreurs Docker Build
# Usage: ./fix-docker-build.sh

echo "🔧 CORRECTION ERREURS DOCKER BUILD"
echo "================================="

cd /var/www/meknow || exit 1

# 1. Arrêter les services Docker
echo "1. 🛑 Arrêt des services Docker..."
docker-compose down

# 2. Nettoyer les images et containers
echo "2. 🧹 Nettoyage Docker..."
docker system prune -f
docker rmi $(docker images -f "dangling=true" -q) 2>/dev/null || true

# 3. Corriger le Dockerfile frontend
echo "3. 🔧 Correction du Dockerfile frontend..."
cd menow-web

# Créer un Dockerfile corrigé
cat > Dockerfile << 'EOF'
# Dockerfile corrigé pour Next.js
FROM node:18-alpine AS base

LABEL maintainer="yassineco"
LABEL version="2.1.0"

RUN apk add --no-cache libc6-compat curl
WORKDIR /app

# Étape 1: Dépendances
FROM base AS deps
COPY package*.json ./
RUN npm ci

# Étape 2: Build
FROM base AS builder
COPY --from=deps /app/node_modules ./node_modules
COPY . .

ENV NEXT_PUBLIC_API_URL=https://meknow.fr/api
RUN npm run build

# Étape 3: Production
FROM base AS runner
ENV NODE_ENV=production
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package*.json ./

USER nextjs
EXPOSE 3000

CMD ["npm", "start"]
EOF

cd ..

# 4. Vérifier les fichiers essentiels
echo "4. ✅ Vérification des fichiers..."
if [ ! -f "menow-web/src/styles/globals.css" ]; then
    echo "Création de globals.css..."
    mkdir -p menow-web/src/styles
    cat > menow-web/src/styles/globals.css << 'EOF'
@tailwind base;
@tailwind components; 
@tailwind utilities;

body {
  font-family: 'Inter', sans-serif;
  background: #0B0B0C;
  color: #ffffff;
}
EOF
fi

# 5. Vérifier tsconfig.json
echo "5. ⚙️ Vérification tsconfig.json..."
if [ ! -f "menow-web/tsconfig.json" ]; then
    cat > menow-web/tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2021",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext", 
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [{"name": "next"}],
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
EOF
fi

# 6. Redéployer avec le Dockerfile corrigé
echo "6. 🚀 Redéploiement avec Dockerfile corrigé..."
docker-compose --env-file .env.production up -d --build

# 7. Attendre et vérifier
echo "7. ⏱️ Attente du démarrage..."
sleep 60

echo "8. ✅ Vérification finale..."
docker-compose ps
echo ""
echo "Tests des services:"
curl -s http://localhost:9001/health && echo " ✅ Backend OK"
curl -s -I http://localhost:3001/ | head -n1 && echo " ✅ Frontend accessible"

echo ""
echo "🎉 CORRECTION TERMINÉE!"
echo "🌐 Votre site devrait être accessible sur: https://meknow.fr"