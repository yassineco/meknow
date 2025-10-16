#!/bin/bash

# Script de nettoyage final pour projet Meknow
# Supprime toutes les traces de MedusaJS et nettoie le projet

echo "🧹 Nettoyage final du projet Meknow..."

# Supprimer les anciens fichiers MedusaJS s'ils existent encore
echo "🗑️  Suppression des fichiers MedusaJS restants..."
rm -rf medusa-api/
rm -f *medusa*
rm -f *.medusa.*

# Nettoyer tous les node_modules
echo "📦 Nettoyage des dépendances..."
rm -rf node_modules/
rm -rf menow-web/node_modules/
rm -f pnpm-lock.yaml
rm -f menow-web/package-lock.json

# Lister les fichiers qui contiennent encore "medusa" ou "Medusa"
echo "🔍 Vérification des références MedusaJS restantes..."
grep -r -i "medusa" --exclude-dir=node_modules --exclude-dir=.git --exclude="*.md" . || echo "✅ Aucune référence MedusaJS trouvée"

echo ""
echo "✅ Nettoyage terminé !"
echo ""
echo "📝 Structure du projet simplifiée :"
echo "├── backend-minimal.js          # API Express.js"
echo "├── admin-direct.html          # Interface admin"
echo "├── menow-web/                 # Frontend Next.js"
echo "├── package.json               # Dépendances simplifiées"
echo "└── docker-compose.yml         # Infrastructure"
echo ""
echo "🚀 Prêt pour le développement !"
echo "   npm install && npm run dev"