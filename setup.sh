#!/bin/bash

echo "🚀 Configuration initiale de Menow"
echo "=================================="
echo ""

# Vérifier si pnpm est installé
if ! command -v pnpm &> /dev/null; then
    echo "❌ pnpm n'est pas installé"
    echo "Installation de pnpm..."
    npm install -g pnpm
fi

echo "✅ pnpm trouvé: $(pnpm --version)"
echo ""

# Installer les dépendances
echo "📦 Installation des dépendances..."
pnpm install

echo ""
echo "✅ Installation terminée!"
echo ""
echo "📋 Prochaines étapes:"
echo "  1. Configurer PostgreSQL (Neon, Supabase, ou local)"
echo "  2. Copier les fichiers .env:"
echo "     cp medusa-api/.env.example medusa-api/.env"
echo "     cp menow-web/.env.local.example menow-web/.env.local"
echo "  3. Éditer medusa-api/.env avec votre DATABASE_URL"
echo "  4. Exécuter les migrations: pnpm --filter medusa-api migrate"
echo "  5. Créer un admin: pnpm user:create"
echo "  6. Seed les données: pnpm seed"
echo "  7. Démarrer: pnpm dev"
echo ""
echo "📚 Consultez QUICK-START.md pour le guide complet"
