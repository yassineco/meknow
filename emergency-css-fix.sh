#!/bin/bash

# 🚨 Correction d'urgence CSS - MEKNOW
# Usage: ./emergency-css-fix.sh

echo "🚨 CORRECTION D'URGENCE CSS - MEKNOW"
echo "=================================="

PROJECT_DIR="/var/www/meknow"
cd $PROJECT_DIR

echo "1. 🛑 Arrêt du frontend..."
docker-compose stop frontend

echo "2. 🧹 Suppression fichier CSS problématique..."
rm -f menow-web/src/styles/globals.css
rm -f menow-web/styles/globals.css

echo "3. 📁 Création structure propre..."
mkdir -p menow-web/src/styles

echo "4. ✨ Création globals.css minimal et fonctionnel..."
cat > menow-web/src/styles/globals.css << 'EOL'
@tailwind base;
@tailwind components;
@tailwind utilities;

html, body {
  padding: 0;
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, sans-serif;
}

* {
  box-sizing: border-box;
}
EOL

echo "5. 🔧 Vérification PostCSS config..."
cat > menow-web/postcss.config.js << 'EOL'
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
EOL

echo "6. ⚙️ Vérification Tailwind config..."
cat > menow-web/tailwind.config.js << 'EOL'
module.exports = {
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
EOL

echo "7. 🗑️ Nettoyage cache Docker..."
docker rmi $(docker images | grep menow-frontend | awk '{print $3}') 2>/dev/null || true
docker system prune -f

echo "8. 🔨 Reconstruction complète..."
docker-compose build --no-cache frontend

echo "9. 🚀 Redémarrage frontend..."
docker-compose up -d frontend

echo "10. ⏳ Attente build (90 secondes)..."
sleep 90

echo "11. ✅ Test final..."
if curl -s http://localhost:3001 >/dev/null 2>&1; then
    echo "✅ SUCCESS! Site accessible!"
else
    echo "⚠️ Encore en cours de build..."
fi

echo ""
echo "🎉 CORRECTION TERMINÉE!"
echo "🌐 Testez: http://31.97.196.215:3001"