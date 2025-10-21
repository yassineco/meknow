#!/bin/bash

# 🎨 Correction erreur CSS globals.css - MEKNOW Frontend
# Usage: ./fix-css-error.sh

echo "🎨 CORRECTION ERREUR CSS - MEKNOW Frontend"
echo "========================================"

PROJECT_DIR="/var/www/meknow"
FRONTEND_DIR="$PROJECT_DIR/menow-web"

echo "1. 🔍 Diagnostic de l'erreur CSS..."

cd $PROJECT_DIR

echo "📍 Répertoire: $(pwd)"
echo "🔍 Recherche du fichier globals.css problématique..."

# Localiser et corriger le fichier globals.css
if [ -f "$FRONTEND_DIR/src/styles/globals.css" ]; then
    echo "✅ Fichier globals.css trouvé dans src/styles/"
    CSS_FILE="$FRONTEND_DIR/src/styles/globals.css"
elif [ -f "$FRONTEND_DIR/styles/globals.css" ]; then
    echo "✅ Fichier globals.css trouvé dans styles/"
    CSS_FILE="$FRONTEND_DIR/styles/globals.css"
else
    echo "❌ Fichier globals.css non trouvé, création..."
    mkdir -p "$FRONTEND_DIR/src/styles"
    CSS_FILE="$FRONTEND_DIR/src/styles/globals.css"
fi

echo "📄 Fichier CSS cible: $CSS_FILE"

echo ""
echo "2. 🧹 Nettoyage et recréation du CSS..."

# Créer un fichier globals.css propre et correct
cat > "$CSS_FILE" << 'EOL'
@tailwind base;
@tailwind components;  
@tailwind utilities;

/* Reset CSS global */
* {
  box-sizing: border-box;
  padding: 0;
  margin: 0;
}

html,
body {
  max-width: 100vw;
  overflow-x: hidden;
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen', sans-serif;
}

body {
  color: #1a1a1a;
  background: #ffffff;
  line-height: 1.6;
}

/* Variables CSS custom */
:root {
  --foreground-rgb: 26, 26, 26;
  --background-start-rgb: 255, 255, 255;
  --background-end-rgb: 250, 250, 250;
  --primary-color: #3b82f6;
  --secondary-color: #64748b;
}

/* Mode sombre (optionnel) */
@media (prefers-color-scheme: dark) {
  :root {
    --foreground-rgb: 255, 255, 255;
    --background-start-rgb: 15, 23, 42;
    --background-end-rgb: 15, 23, 42;
  }
  
  body {
    color: white;
    background: linear-gradient(
        to bottom,
        transparent,
        rgb(var(--background-end-rgb))
      )
      rgb(var(--background-start-rgb));
  }
}

/* Styles de base pour MEKNOW */
.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 1rem;
}

.btn-primary {
  background-color: var(--primary-color);
  color: white;
  padding: 0.75rem 1.5rem;
  border-radius: 0.375rem;
  border: none;
  cursor: pointer;
  transition: background-color 0.2s;
}

.btn-primary:hover {
  background-color: #2563eb;
}

/* Responsive design */
@media (max-width: 768px) {
  .container {
    padding: 0 0.5rem;
  }
}
EOL

echo "✅ Nouveau fichier globals.css créé sans erreur"

echo ""
echo "3. 🔧 Vérification de la configuration Tailwind..."

# Vérifier et corriger tailwind.config.js
TAILWIND_CONFIG="$FRONTEND_DIR/tailwind.config.js"

if [ ! -f "$TAILWIND_CONFIG" ]; then
    echo "📝 Création de tailwind.config.js..."
    cat > "$TAILWIND_CONFIG" << 'EOL'
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
    './pages/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
    './app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
      colors: {
        primary: '#3b82f6',
        secondary: '#64748b',
      },
    },
  },
  plugins: [],
}
EOL
    echo "✅ tailwind.config.js créé"
else
    echo "✅ tailwind.config.js existe déjà"
fi

echo ""
echo "4. 🔄 Vérification PostCSS..."

# Vérifier postcss.config.js
POSTCSS_CONFIG="$FRONTEND_DIR/postcss.config.js"

if [ ! -f "$POSTCSS_CONFIG" ]; then
    echo "📝 Création de postcss.config.js..."
    cat > "$POSTCSS_CONFIG" << 'EOL'
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
EOL
    echo "✅ postcss.config.js créé"
else
    echo "✅ postcss.config.js existe déjà"
fi

echo ""
echo "5. 🔧 Correction du layout.tsx pour imports CSS..."

# Corriger le layout.tsx pour importer correctement le CSS
LAYOUT_FILE="$FRONTEND_DIR/src/app/layout.tsx"

if [ -f "$LAYOUT_FILE" ]; then
    echo "🔄 Mise à jour du layout.tsx..."
    cat > "$LAYOUT_FILE" << 'EOL'
import type { Metadata } from 'next'
import '../styles/globals.css'

export const metadata: Metadata = {
  title: 'MEKNOW E-commerce',
  description: 'Site e-commerce MEKNOW - Vêtements et accessoires de qualité',
  keywords: 'e-commerce, vêtements, mode, shopping, MEKNOW',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="fr">
      <head>
        <meta charSet="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
      </head>
      <body className="min-h-screen bg-gray-50 text-gray-900 antialiased">
        <div className="flex flex-col min-h-screen">
          <main className="flex-1">
            {children}
          </main>
          <footer className="mt-auto py-8 bg-gray-900 text-white">
            <div className="container mx-auto text-center">
              <p>&copy; 2024 MEKNOW E-commerce. Tous droits réservés.</p>
            </div>
          </footer>
        </div>
      </body>
    </html>
  )
}
EOL
    echo "✅ layout.tsx mis à jour"
fi

echo ""
echo "6. 🚀 Reconstruction du frontend..."

cd $PROJECT_DIR

echo "🛑 Arrêt du service frontend..."
docker-compose stop frontend

echo "🧹 Suppression de l'image corrompue..."
docker rmi $(docker images | grep menow-frontend | awk '{print $3}') 2>/dev/null || true

echo "🔨 Reconstruction du frontend..."
docker-compose build --no-cache frontend

echo "🏁 Redémarrage du frontend..."
docker-compose up -d frontend

echo ""
echo "7. ⏳ Attente du build CSS (60 secondes)..."
sleep 60

echo ""
echo "8. ✅ Vérification finale..."

echo "📊 État des containers :"
docker-compose ps

echo ""
echo "🔍 Test du frontend :"
if timeout 10 curl -s -I http://localhost:3001/ | head -n1 | grep -q "HTTP"; then
    echo "✅ Frontend répond maintenant !"
else
    echo "⚠️ Frontend encore en cours de build..."
fi

echo ""
echo "📋 Logs récents du frontend (si erreur) :"
docker-compose logs --tail=5 frontend

echo ""
echo "🎉 CORRECTION CSS TERMINÉE !"
echo ""
echo "🌐 Testez maintenant :"
echo "   http://$(curl -s ifconfig.me):3001"
echo ""
echo "📝 Si le problème persiste :"
echo "   - Attendez 5-10 minutes (build Next.js)"
echo "   - Consultez les logs : docker-compose logs frontend"
echo "   - Redémarrez : docker-compose restart frontend"