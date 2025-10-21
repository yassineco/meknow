#!/bin/bash

# 🛠️ Script de correction Frontend Next.js - MEKNOW VPS
# Usage: ./fix-nextjs-frontend.sh

echo "🛠️ CORRECTION FRONTEND NEXT.JS - MEKNOW VPS"
echo "=========================================="

PROJECT_DIR="/var/www/meknow"
FRONTEND_DIR="$PROJECT_DIR/menow-web"

echo "1. 🔍 Diagnostic de l'erreur Next.js..."

cd $PROJECT_DIR

echo "📍 Répertoire projet: $(pwd)"
echo "📁 Structure du frontend:"
ls -la menow-web/ 2>/dev/null | head -10 || echo "❌ Répertoire menow-web introuvable"

echo ""
echo "2. 🧹 Arrêt des containers pour reconstruction..."

# Arrêter les containers
docker-compose down

echo ""
echo "3. 🔧 Correction de la structure Next.js..."

cd $FRONTEND_DIR

# Vérifier la structure du projet Next.js
echo "📋 Fichiers présents dans menow-web:"
ls -la

echo ""
echo "🔍 Vérification des fichiers critiques Next.js..."

# Vérifier package.json
if [ ! -f "package.json" ]; then
    echo "❌ package.json manquant!"
    echo "📝 Création d'un package.json basique..."
    
    cat > package.json << 'EOL'
{
  "name": "menow-frontend",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint"
  },
  "dependencies": {
    "next": "14.0.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "@types/node": "^20.0.0",
    "@types/react": "^18.2.0",
    "@types/react-dom": "^18.2.0",
    "typescript": "^5.0.0",
    "tailwindcss": "^3.3.0",
    "autoprefixer": "^10.4.16",
    "postcss": "^8.4.31"
  },
  "devDependencies": {
    "eslint": "^8.0.0",
    "eslint-config-next": "14.0.0"
  }
}
EOL
fi

# Créer la structure de base Next.js si elle n'existe pas
echo "🏗️ Création de la structure Next.js manquante..."

# Créer le dossier src/app si il n'existe pas (App Router)
mkdir -p src/app
mkdir -p src/components
mkdir -p src/styles
mkdir -p public

# Créer layout.tsx manquant
if [ ! -f "src/app/layout.tsx" ]; then
    echo "📄 Création de layout.tsx..."
    cat > src/app/layout.tsx << 'EOL'
import type { Metadata } from 'next'
import '../styles/globals.css'

export const metadata: Metadata = {
  title: 'MEKNOW E-commerce',
  description: 'Site e-commerce MEKNOW - Vêtements et accessoires',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="fr">
      <body className="min-h-screen bg-gray-50">
        <main>{children}</main>
        <footer className="mt-auto py-8 bg-gray-900 text-white text-center">
          <p>&copy; 2024 MEKNOW. Tous droits réservés.</p>
        </footer>
      </body>
    </html>
  )
}
EOL
fi

# Créer page.tsx manquant
if [ ! -f "src/app/page.tsx" ]; then
    echo "📄 Création de page.tsx..."
    cat > src/app/page.tsx << 'EOL'
export default function HomePage() {
  return (
    <div className="container mx-auto px-4 py-8">
      <header className="text-center mb-12">
        <h1 className="text-4xl font-bold text-gray-900 mb-4">
          MEKNOW E-commerce
        </h1>
        <p className="text-lg text-gray-600">
          Votre boutique en ligne de référence
        </p>
      </header>
      
      <div className="grid md:grid-cols-3 gap-8">
        <div className="bg-white p-6 rounded-lg shadow-lg">
          <h2 className="text-xl font-semibold mb-4">Catalogue</h2>
          <p className="text-gray-600">Découvrez notre sélection de produits</p>
        </div>
        
        <div className="bg-white p-6 rounded-lg shadow-lg">
          <h2 className="text-xl font-semibold mb-4">Lookbook</h2>
          <p className="text-gray-600">Les dernières tendances mode</p>
        </div>
        
        <div className="bg-white p-6 rounded-lg shadow-lg">
          <h2 className="text-xl font-semibold mb-4">Rubriques</h2>
          <p className="text-gray-600">Explorez nos différentes catégories</p>
        </div>
      </div>
    </div>
  )
}
EOL
fi

# Créer globals.css manquant
if [ ! -f "src/styles/globals.css" ]; then
    echo "📄 Création de globals.css..."
    cat > src/styles/globals.css << 'EOL'
@tailwind base;
@tailwind components;
@tailwind utilities;

* {
  box-sizing: border-box;
  padding: 0;
  margin: 0;
}

html,
body {
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
  --foreground-rgb: 0, 0, 0;
  --background-start-rgb: 214, 219, 220;
  --background-end-rgb: 255, 255, 255;
}

@media (prefers-color-scheme: dark) {
  :root {
    --foreground-rgb: 255, 255, 255;
    --background-start-rgb: 0, 0, 0;
    --background-end-rgb: 0, 0, 0;
  }
}
EOL
fi

# Créer next.config.js manquant
if [ ! -f "next.config.js" ]; then
    echo "📄 Création de next.config.js..."
    cat > next.config.js << 'EOL'
/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  experimental: {
    serverActions: {
      allowedOrigins: ['localhost:3000', 'meknow.fr']
    }
  },
  images: {
    domains: ['localhost', 'meknow.fr'],
  },
  env: {
    NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:9000',
  }
}

module.exports = nextConfig
EOL
fi

# Créer tailwind.config.js si manquant
if [ ! -f "tailwind.config.js" ]; then
    echo "📄 Création de tailwind.config.js..."
    cat > tailwind.config.js << 'EOL'
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      backgroundImage: {
        'gradient-radial': 'radial-gradient(var(--tw-gradient-stops))',
        'gradient-conic':
          'conic-gradient(from 180deg at 50% 50%, var(--tw-gradient-stops))',
      },
    },
  },
  plugins: [],
}
EOL
fi

# Créer postcss.config.js si manquant
if [ ! -f "postcss.config.js" ]; then
    echo "📄 Création de postcss.config.js..."
    cat > postcss.config.js << 'EOL'
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
EOL
fi

# Créer tsconfig.json si manquant
if [ ! -f "tsconfig.json" ]; then
    echo "📄 Création de tsconfig.json..."
    cat > tsconfig.json << 'EOL'
{
  "compilerOptions": {
    "target": "es5",
    "lib": ["dom", "dom.iterable", "es6"],
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
    "plugins": [
      {
        "name": "next"
      }
    ],
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
EOL
fi

echo ""
echo "4. 🔄 Retour au dossier principal et reconstruction..."

cd $PROJECT_DIR

echo ""
echo "5. 🚀 Reconstruction des containers avec corrections..."

# Reconstruire les containers
docker-compose --env-file .env.production up -d --build

echo ""
echo "6. ⏳ Attente de la reconstruction (60 secondes)..."
sleep 60

echo ""
echo "7. ✅ Vérification finale..."

echo "📊 État des containers:"
docker-compose ps

echo ""
echo "🔍 Test des services:"

# Test Backend
if curl -s http://localhost:9001/health >/dev/null 2>&1; then
    echo "✅ Backend (port 9001): OK"
else
    echo "❌ Backend (port 9001): ERREUR"
fi

# Test Frontend avec timeout plus long
if timeout 10 curl -s -I http://localhost:3001/ | head -n1 | grep -q "200\|404\|301\|500"; then
    echo "✅ Frontend (port 3001): Répondant (peut être en cours de build)"
else
    echo "⚠️ Frontend (port 3001): En cours de démarrage ou erreur"
fi

echo ""
echo "📝 Si le frontend montre encore des erreurs:"
echo "   1. Vérifiez les logs: docker-compose logs frontend"
echo "   2. Le build Next.js peut prendre plusieurs minutes"
echo "   3. Attendez et retestez dans 5-10 minutes"

echo ""
echo "🎉 CORRECTION FRONTEND TERMINÉE!"
echo ""
echo "🌐 Testez l'accès après quelques minutes:"
echo "   Frontend: http://VOTRE_IP:3001"
echo "   Backend:  http://VOTRE_IP:9001/health"
echo "   Admin:    http://VOTRE_IP:8082"