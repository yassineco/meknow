#!/bin/bash

# 🚀 SCRIPT GIT DE SYNCHRONISATION ET DÉPLOIEMENT MEKNOW
# Ce script synchronise le VPS avec GitHub et déploie la solution finale

echo "🚀 DÉMARRAGE DE LA SYNCHRONISATION GIT..."

# Étape 1: Sauvegarde et nettoyage
echo "📦 Sauvegarde des modifications locales..."
git stash push -m "Sauvegarde avant sync $(date)"

# Étape 2: Récupération des dernières modifications
echo "📡 Récupération depuis GitHub..."
git fetch origin

# Étape 3: Synchronisation forcée avec main
echo "🔄 Synchronisation avec origin/main..."
git reset --hard origin/main

# Étape 4: Nettoyage des fichiers non suivis
echo "🧹 Nettoyage des fichiers conflictuels..."
git clean -fd

# Étape 5: Vérification des fichiers critiques
echo "✅ Vérification des fichiers téléchargés..."

if [ -f "bypass-tailwind-final.sh" ]; then
    echo "✅ bypass-tailwind-final.sh: PRÉSENT"
    chmod +x bypass-tailwind-final.sh
else
    echo "❌ bypass-tailwind-final.sh: MANQUANT"
    exit 1
fi

if [ -f "docker-compose-fixed.yml" ]; then
    echo "✅ docker-compose-fixed.yml: PRÉSENT"
else
    echo "❌ docker-compose-fixed.yml: MANQUANT"
fi

if [ -f "fix-yaml-error.sh" ]; then
    echo "✅ fix-yaml-error.sh: PRÉSENT"
    chmod +x fix-yaml-error.sh
else
    echo "❌ fix-yaml-error.sh: MANQUANT"
fi

# Étape 6: Affichage du statut Git
echo "📊 Statut Git actuel:"
git status --porcelain
git log --oneline -3

# Étape 7: Exécution de la solution finale
echo ""
echo "🚨 DÉPLOIEMENT DE LA SOLUTION FINALE..."
echo "🔧 Exécution de bypass-tailwind-final.sh..."
echo ""

./bypass-tailwind-final.sh

echo ""
echo "✅ SYNCHRONISATION GIT TERMINÉE"
echo "📱 Vérifiez maintenant http://votre-ip:3001"