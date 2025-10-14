# 🚀 Guide de Déploiement Meknow sur VPS Hostinger

## 📋 Informations de votre VPS

**Serveur VPS Hostinger KVM 2**
- 🌐 **IP**: `31.97.196.215`
- 🖥️ **Hostname**: `srv1064655.hstgr.cloud`
- 💾 **RAM**: 8GB
- ⚡ **CPU**: 2 vCPU
- 💽 **Stockage**: 100GB SSD NVMe
- 🌐 **Bande passante**: 8TB
- 🐧 **OS**: Ubuntu 22.04 LTS

## 🔑 Étape 1: Première Connexion SSH

### Connexion avec le mot de passe root temporaire
```bash
# Connexion SSH
ssh root@31.97.196.215

# Vous devrez entrer le mot de passe temporaire fourni par Hostinger
```

### ⚠️ Sécurisation immédiate (IMPORTANT)
```bash
# 1. Changer le mot de passe root
passwd

# 2. Mettre à jour le système
apt update && apt upgrade -y

# 3. Configurer le firewall
ufw allow 22/tcp
ufw allow 80/tcp  
ufw allow 443/tcp
ufw --force enable
```

## 🛠️ Étape 2: Installation du Serveur

### Script automatique d'installation
```bash
# Télécharger et exécuter le script d'installation
curl -sSL https://raw.githubusercontent.com/votre-username/meknow/main/deploy/install-server.sh | bash

# OU si vous préférez examiner le script d'abord:
wget https://raw.githubusercontent.com/votre-username/meknow/main/deploy/install-server.sh
chmod +x install-server.sh
./install-server.sh
```

### ✅ Ce que le script installe:
- ✅ Node.js 18.x + NPM
- ✅ PostgreSQL 14+ avec base `meknow_production`
- ✅ Nginx (serveur web + reverse proxy)
- ✅ PM2 (gestionnaire de processus)
- ✅ Docker (pour futurs besoins)
- ✅ Certbot (certificats SSL gratuits)
- ✅ Utilisateur `deploy` pour la sécurité

## 🚀 Étape 3: Déploiement de Meknow

### AVANT le déploiement - Préparer le repository

**Important**: Vous devez d'abord pousser votre code sur GitHub:

```bash
# Sur votre machine locale (dans le dossier menow)
git remote add origin https://github.com/VOTRE-USERNAME/meknow.git
git push -u origin main
```

### Déploiement automatique
```bash
# Sur le VPS, en tant que root
curl -sSL https://raw.githubusercontent.com/votre-username/meknow/main/deploy/deploy-meknow.sh | bash

# OU manuellement:
wget https://raw.githubusercontent.com/votre-username/meknow/main/deploy/deploy-meknow.sh
chmod +x deploy-meknow.sh
./deploy-meknow.sh
```

## 🌐 Étape 4: Configuration du Domaine (Optionnel)

### Si vous avez acheté un domaine
```bash
# Pointer votre domaine vers l'IP du VPS
# Dans votre panneau de contrôle de domaine, créez:
# A record: @ -> 31.97.196.215
# A record: www -> 31.97.196.215

# Puis modifiez la configuration:
nano /etc/nginx/sites-available/meknow

# Remplacez "votre-domaine.com" par votre vrai domaine
# Puis redémarrez Nginx:
systemctl restart nginx

# Installez SSL gratuit:
certbot --nginx -d votre-domaine.com -d www.votre-domaine.com
```

## 🎯 Étape 5: Vérification et Tests

### Vérifier que tout fonctionne
```bash
# Status des services
pm2 status

# Logs en temps réel
pm2 logs

# Test des endpoints
curl http://localhost:9000/health    # Backend
curl http://localhost:5000           # Frontend
curl http://localhost:8082           # Admin

# Test depuis l'extérieur
curl http://31.97.196.215/api/health
```

### 🌐 URLs d'accès:
- **Frontend**: http://31.97.196.215
- **API**: http://31.97.196.215/api
- **Admin**: http://31.97.196.215:8082
- **Health Check**: http://31.97.196.215/api/health

## 🔧 Commandes de Maintenance

### Gestion des services PM2
```bash
# Voir le status
pm2 status

# Redémarrer tous les services
pm2 restart all

# Redémarrer un service spécifique
pm2 restart meknow-backend
pm2 restart meknow-frontend
pm2 restart meknow-admin

# Voir les logs
pm2 logs                    # Tous les logs
pm2 logs meknow-backend     # Logs du backend uniquement

# Arrêter/démarrer
pm2 stop all
pm2 start all
```

### Gestion Nginx
```bash
# Tester la configuration
nginx -t

# Redémarrer Nginx
systemctl restart nginx

# Voir les logs
tail -f /var/log/nginx/meknow_access.log
tail -f /var/log/nginx/meknow_error.log
```

### Gestion PostgreSQL
```bash
# Connexion à la base
sudo -u postgres psql meknow_production

# Backup de la base
sudo -u postgres pg_dump meknow_production > backup_$(date +%Y%m%d).sql

# Restaurer une base
sudo -u postgres psql meknow_production < backup_20241014.sql
```

## 🔄 Mise à Jour de l'Application

### Déploiement de nouvelles versions
```bash
# 1. Sur votre machine locale - pousser les changements
git add .
git commit -m "Nouvelle version"
git push origin main

# 2. Sur le VPS - mettre à jour
cd /var/www/meknow
git pull origin main

# 3. Rebuilder si nécessaire
cd menow-web && npm run build && cd ..

# 4. Redémarrer les services
pm2 restart all
```

### Script de mise à jour automatique
```bash
# Créer un script de mise à jour
cat > /root/update-meknow.sh << 'EOF'
#!/bin/bash
cd /var/www/meknow
git pull origin main
cd menow-web && npm run build && cd ..
pm2 restart all
echo "Mise à jour terminée"
EOF

chmod +x /root/update-meknow.sh

# Utilisation:
/root/update-meknow.sh
```

## 🔐 Sécurité et Bonnes Pratiques

### Configuration SSH sécurisée
```bash
# Désactiver l'authentification par mot de passe (après avoir configuré les clés SSH)
nano /etc/ssh/sshd_config
# Changer: PasswordAuthentication no
systemctl restart ssh
```

### Surveillance des logs
```bash
# Installer logwatch pour surveillance
apt install logwatch -y

# Configurer des alertes par email (optionnel)
# nano /etc/logwatch/conf/logwatch.conf
```

### Backup automatique
```bash
# Script de backup quotidien
cat > /root/backup-meknow.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d)
mkdir -p /root/backups
sudo -u postgres pg_dump meknow_production > /root/backups/db_$DATE.sql
tar -czf /root/backups/files_$DATE.tar.gz /var/www/meknow
# Garder seulement les 7 derniers backups
find /root/backups -name "*.sql" -mtime +7 -delete
find /root/backups -name "*.tar.gz" -mtime +7 -delete
EOF

chmod +x /root/backup-meknow.sh

# Ajouter au cron pour exécution quotidienne
crontab -e
# Ajouter: 0 2 * * * /root/backup-meknow.sh
```

## 🆘 Dépannage

### Problèmes courants

**Service ne démarre pas:**
```bash
pm2 logs meknow-backend  # Voir les erreurs
pm2 restart meknow-backend
```

**Base de données inaccessible:**
```bash
systemctl status postgresql
systemctl restart postgresql
```

**Nginx ne démarre pas:**
```bash
nginx -t  # Tester la configuration
systemctl status nginx
```

**Disque plein:**
```bash
df -h  # Vérifier l'espace disque
du -sh /var/log/*  # Vérifier les logs
```

### Contacts de support

- **Hostinger Support**: support.hostinger.com
- **Documentation VPS**: https://support.hostinger.com/en/categories/vps
- **Logs système**: /var/log/

## ✅ Checklist de Déploiement

- [ ] Connexion SSH réussie
- [ ] Système mis à jour
- [ ] Firewall configuré
- [ ] install-server.sh exécuté
- [ ] Repository GitHub créé et poussé
- [ ] deploy-meknow.sh exécuté
- [ ] Services PM2 démarrés
- [ ] Nginx configuré
- [ ] Tests des URLs réussis
- [ ] Domaine configuré (si applicable)
- [ ] SSL installé (si domaine)
- [ ] Backup configuré

**🎉 Votre e-commerce Meknow est en ligne !**