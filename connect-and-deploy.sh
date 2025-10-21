#!/bin/bash

# 🔗 Script de connexion et déploiement VPS
# Usage: ./connect-and-deploy.sh

echo "🔗 CONNEXION ET DÉPLOIEMENT VPS - MEKNOW"
echo "======================================"

# Instructions de connexion
echo "1. 📡 Connexion SSH au VPS:"
echo "   Utilisez l'une de ces commandes selon votre configuration:"
echo ""
echo "   # Option A - Connexion root:"
echo "   ssh root@IP_DE_VOTRE_VPS"
echo ""  
echo "   # Option B - Connexion avec utilisateur:"
echo "   ssh user@meknow.fr"
echo ""
echo "   # Option C - Connexion avec clé SSH:"
echo "   ssh -i ~/.ssh/votre_cle root@IP_VPS"
echo ""

# Script d'installation
echo "2. 🚀 Une fois connecté, exécutez cette commande:"
echo ""
echo "curl -fsSL https://raw.githubusercontent.com/yassineco/meknow/main/install-vps.sh | bash"
echo ""

# Ce qui va se passer
echo "3. 📋 Ce qui va se passer automatiquement:"
echo "   ✅ Nettoyage de l'ancienne installation PM2"
echo "   ✅ Installation Docker + Docker Compose"
echo "   ✅ Clonage du projet depuis GitHub"
echo "   ✅ Configuration de l'environnement production"
echo "   ✅ Déploiement des containers Docker"
echo "   ✅ Configuration Nginx + SSL automatique"
echo "   ✅ Tests de validation"
echo ""

# Temps d'attente
echo "4. ⏱️  Temps d'installation estimé: 5-10 minutes"
echo ""

# URLs finales
echo "5. 🌐 URLs après installation:"
echo "   Frontend:  https://meknow.fr"
echo "   Admin:     https://meknow.fr/admin"
echo "   API:       https://meknow.fr/api"
echo ""

# Surveillance
echo "6. 👀 Pour surveiller l'installation:"
echo "   # Voir les logs Docker:"
echo "   docker-compose logs -f"
echo ""
echo "   # Voir l'état des services:"
echo "   docker-compose ps"
echo ""

# Dépannage
echo "7. 🔧 En cas de problème:"
echo "   # Redémarrer les services:"
echo "   cd /var/www/meknow && docker-compose restart"
echo ""
echo "   # Voir les logs d'erreur:"
echo "   docker-compose logs backend"
echo "   docker-compose logs frontend"
echo ""

echo "🎯 PRÊT POUR LE DÉPLOIEMENT !"
echo ""
echo "Ouvrez un nouveau terminal et connectez-vous à votre VPS maintenant !"

# Test de connectivité (optionnel)
read -p "🔍 Voulez-vous tester la connectivité SSH maintenant? (y/N): " test_ssh

if [[ $test_ssh =~ ^[Yy]$ ]]; then
    read -p "📝 Entrez l'adresse IP ou le domaine de votre VPS: " vps_address
    echo "🧪 Test de connectivité..."
    if ping -c 2 $vps_address > /dev/null 2>&1; then
        echo "✅ VPS accessible via ping"
        echo "🔗 Vous pouvez maintenant vous connecter:"
        echo "   ssh root@$vps_address"
    else
        echo "⚠️  VPS non accessible via ping, vérifiez l'adresse"
    fi
fi

echo ""
echo "🚀 Bonne installation ! Votre e-commerce sera bientôt en ligne !"