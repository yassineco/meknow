#!/bin/bash

# 🔧 CORRECTION ERREUR YAML DOCKER-COMPOSE
# Ce script corrige l'erreur "mapping key networks already defined"

echo "🔧 CORRECTION DE L'ERREUR YAML DOCKER-COMPOSE..."

# Sauvegarder l'ancien fichier
if [ -f "docker-compose.yml" ]; then
    cp docker-compose.yml docker-compose.yml.backup
    echo "✅ Sauvegarde créée: docker-compose.yml.backup"
fi

# Remplacer par la version corrigée
cp docker-compose-fixed.yml docker-compose.yml
echo "✅ Fichier docker-compose.yml corrigé"

# Validation YAML
echo "🔍 Validation du fichier YAML..."
if docker-compose config >/dev/null 2>&1; then
    echo "✅ YAML valide !"
else
    echo "❌ Erreur YAML détectée, restauration de la sauvegarde..."
    cp docker-compose.yml.backup docker-compose.yml
    exit 1
fi

# Redémarrage des services
echo "🚀 Redémarrage des services Docker..."
docker-compose down
docker-compose up -d --build

echo "✅ CORRECTION YAML TERMINÉE"
echo "📊 Vérification des services:"
docker-compose ps

echo ""
echo "🌐 Accès aux services:"
echo "Frontend: http://localhost:3001"
echo "Backend API: http://localhost:9001"
echo "Admin: http://localhost:8082"