#!/bin/bash

# 🔧 Script d'installation des services systemd pour Meknow

set -e

PROJECT_PATH="/var/www/meknow"
SERVICE_USER="www-data"

echo "🔧 Installation des services systemd pour Meknow"

# Vérifier si on est en root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Ce script doit être exécuté avec sudo"
    exit 1
fi

# Créer l'utilisateur www-data s'il n'existe pas
if ! id "$SERVICE_USER" &>/dev/null; then
    echo "📝 Création de l'utilisateur $SERVICE_USER..."
    useradd -r -s /bin/bash $SERVICE_USER
fi

# Créer le répertoire des logs
mkdir -p /var/log/meknow
chown $SERVICE_USER:$SERVICE_USER /var/log/meknow

# Assurer que le propriétaire du projet est correct
chown -R $SERVICE_USER:$SERVICE_USER $PROJECT_PATH

# Copier les fichiers de service
echo "📋 Installation des fichiers de service..."
cp $PROJECT_PATH/meknow-api.service /etc/systemd/system/
cp $PROJECT_PATH/meknow-web.service /etc/systemd/system/

# Recharger les configurations systemd
echo "🔄 Rechargement de systemd..."
systemctl daemon-reload

# Activer les services au démarrage
echo "✅ Activation des services..."
systemctl enable meknow-api.service
systemctl enable meknow-web.service

echo ""
echo "✅ Installation complète!"
echo ""
echo "Commandes utiles:"
echo "  Démarrer les services:    sudo systemctl start meknow-api meknow-web"
echo "  Arrêter les services:     sudo systemctl stop meknow-api meknow-web"
echo "  Redémarrer les services:  sudo systemctl restart meknow-api meknow-web"
echo "  Voir le statut:           sudo systemctl status meknow-api meknow-web"
echo "  Voir les logs:            sudo journalctl -u meknow-api -f"
echo "                            sudo journalctl -u meknow-web -f"
