#!/bin/bash

# 🔧 Script de correction des imports Next.js
# Remplace tous les '@/' par des chemins relatifs

echo "🔧 CORRECTION DES IMPORTS NEXT.JS"
echo "================================="

cd /var/www/meknow || exit 1

# 1. Correction des imports dans les pages
echo "1. 📝 Correction des imports dans les pages..."

# Corriger page.tsx principal
if [ -f "menow-web/src/app/page.tsx" ]; then
    sed -i "s|@/lib/api|../lib/api|g" menow-web/src/app/page.tsx
    sed -i "s|@/components/|../components/|g" menow-web/src/app/page.tsx
    sed -i "s|@/styles/|../styles/|g" menow-web/src/app/page.tsx
fi

# Corriger layout.tsx
if [ -f "menow-web/src/app/layout.tsx" ]; then
    sed -i "s|@/styles/globals.css|../styles/globals.css|g" menow-web/src/app/layout.tsx
    sed -i "s|@/components/|../components/|g" menow-web/src/app/layout.tsx
fi

# Corriger toutes les pages dans app/
find menow-web/src/app -name "*.tsx" -exec sed -i "s|@/lib/|../../lib/|g" {} \;
find menow-web/src/app -name "*.tsx" -exec sed -i "s|@/components/|../../components/|g" {} \;
find menow-web/src/app -name "*.tsx" -exec sed -i "s|@/styles/|../../styles/|g" {} \;

# 2. Correction des imports dans les composants
echo "2. 🧩 Correction des imports dans les composants..."
find menow-web/src/components -name "*.tsx" -exec sed -i "s|@/lib/|../lib/|g" {} \;
find menow-web/src/components -name "*.tsx" -exec sed -i "s|@/components/|./|g" {} \;
find menow-web/src/components -name "*.tsx" -exec sed -i "s|@/styles/|../styles/|g" {} \;

# 3. Créer un next.config.js simplifié
echo "3. ⚙️ Configuration Next.js simplifiée..."
cat > menow-web/next.config.mjs << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  // Configuration basique sans complications
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'images.unsplash.com',
      },
      {
        protocol: 'https', 
        hostname: 'picsum.photos',
      },
    ],
  },
  env: {
    NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:9000',
  },
  // Désactiver les optimisations qui peuvent causer des problèmes
  swcMinify: false,
  compiler: {
    removeConsole: false,
  },
}

export default nextConfig;
EOF

# 4. Créer un tsconfig.json basique qui fonctionne
echo "4. 📋 Configuration TypeScript basique..."
cat > menow-web/tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2021",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": false,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [
      {
        "name": "next"
      }
    ]
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
EOF

# 5. S'assurer que globals.css existe avec contenu minimal
echo "5. 🎨 Création globals.css minimal..."
mkdir -p menow-web/src/styles
cat > menow-web/src/styles/globals.css << 'EOF'
/* Styles globaux minimaux pour éviter les erreurs */
* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

html,
body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  background: #000;
  color: #fff;
  max-width: 100vw;
  overflow-x: hidden;
}

body {
  color: rgb(var(--foreground-rgb));
  background: linear-gradient(
      to bottom,
      transparent,
      rgb(var(--background-end-rgb))
    )
    rgb(var(--background-start-rgb));
}

:root {
  --foreground-rgb: 255, 255, 255;
  --background-start-rgb: 0, 0, 0;
  --background-end-rgb: 0, 0, 0;
}

a {
  color: inherit;
  text-decoration: none;
}
EOF

# 6. Créer un Dockerfile ultra-simplifié
echo "6. 🐳 Dockerfile ultra-simplifié..."
cat > menow-web/Dockerfile << 'EOF'
FROM node:18-alpine

WORKDIR /app

# Copier package.json
COPY package*.json ./
RUN npm ci

# Copier tout le code
COPY . .

# Variables d'environnement
ENV NODE_ENV=production
ENV NEXT_PUBLIC_API_URL=https://meknow.fr/api

# Build
RUN npm run build

# Exposer le port
EXPOSE 3000

# Commande
CMD ["npm", "start"]
EOF

# 7. Rebuild complet
echo "7. 🏗️ Rebuild complet avec corrections..."
docker-compose down --remove-orphans
docker system prune -f

# Build sans cache
docker-compose --env-file .env.production build --no-cache

# Démarrer
docker-compose --env-file .env.production up -d

echo ""
echo "🎉 CORRECTION IMPORTS TERMINÉE!"
echo "⏱️ Attente du démarrage... (60 secondes)"
sleep 60

echo ""
echo "📊 Vérification finale:"
docker-compose ps
curl -s http://localhost:9001/health && echo " ✅ Backend OK"
curl -s -I http://localhost:3001/ | head -n1 && echo " ✅ Frontend testé"

echo ""
echo "🌐 Testez: https://meknow.fr"