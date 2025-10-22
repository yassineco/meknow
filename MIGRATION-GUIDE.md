# 🔄 Guide de Migration : Docker → Déploiement Natif

## 📋 Vue d'ensemble

Ce guide explique comment migrer votre application Meknow de Docker vers un déploiement natif sur votre VPS.

## ⚠️ Avant de commencer

- **Sauvegarde** : Assurez-vous que vos données PostgreSQL sont sauvegardées
- **Downtime** : Prévoir 15-20 minutes d'interruption de service
- **SSH** : Avoir accès root/sudo sur le VPS
- **Espace disque** : Au minimum 2GB libres après suppression de Docker

## 🚀 Étapes de migration

### Option A : Migration automatique (Recommandée)

```bash
# Connexion au VPS
ssh root@your_vps_ip

# Télécharger les scripts
cd /var/www/meknow
git pull origin main

# Exécuter la migration
sudo bash migrate-docker-to-native.sh
```

Ce script effectue automatiquement :
1. ✅ Nettoyage complet de Docker
2. ✅ Mise à jour du projet Git
3. ✅ Installation des dépendances
4. ✅ Configuration systemd
5. ✅ Démarrage des services

### Option B : Migration manuelle (Pas à pas)

#### 1. Arrêter les conteneurs Docker

```bash
cd /var/www/meknow
docker-compose down
docker stop $(docker ps -a -q) || true
```

#### 2. Sauvegarder les données importantes

```bash
# Sauvegarder les fichiers .env
mkdir -p /root/backups
cp .env /root/backups/.env.$(date +%Y%m%d)
cp menow-web/.env.local /root/backups/.env.local.$(date +%Y%m%d)

# Sauvegarder la base de données
pg_dump meknow_production > /root/backups/db.sql.$(date +%Y%m%d)
```

#### 3. Nettoyer Docker

```bash
# Supprimer les images et volumes
docker rmi $(docker images -a -q) -f
docker volume rm $(docker volume ls -q)
docker system prune -a -f

# Supprimer les fichiers Docker
rm -f docker-compose.yml Dockerfile* .dockerignore
```

#### 4. Mettre à jour le projet

```bash
git fetch origin
git pull origin main

# Installer les dépendances
npm install --production
cd menow-web && npm install --production && npm run build && cd ..
```

#### 5. Configurer systemd

```bash
# Copier les services systemd
sudo cp meknow-api.service /etc/systemd/system/
sudo cp meknow-web.service /etc/systemd/system/

# Créer l'utilisateur www-data
sudo useradd -r -s /bin/bash www-data || true

# Créer les répertoires de logs
sudo mkdir -p /var/log/meknow
sudo chown www-data:www-data /var/log/meknow
sudo chown -R www-data:www-data /var/www/meknow

# Activer les services
sudo systemctl daemon-reload
sudo systemctl enable meknow-api meknow-web
sudo systemctl start meknow-api meknow-web
```

#### 6. Vérifier le statut

```bash
# Vérifier que les services fonctionnent
sudo systemctl status meknow-api meknow-web

# Tester l'API
curl http://localhost:9000/api/products | head -20

# Tester le frontend
curl http://localhost:3000
```

## 🔍 Vérification post-migration

### 1. Services actifs

```bash
sudo systemctl status meknow-api
sudo systemctl status meknow-web
sudo systemctl status nginx  # Si vous utilisez Nginx
```

### 2. Ports écoutant

```bash
sudo lsof -i -P -n | grep LISTEN
```

Vous devriez voir :
- `node` sur le port 9000 (API backend)
- `node` sur le port 3000 (Frontend Next.js)
- Optionnel : `nginx` sur les ports 80 et 443

### 3. Logs

```bash
# Backend
sudo journalctl -u meknow-api -n 50

# Frontend
sudo journalctl -u meknow-web -n 50

# Suivi en temps réel
sudo journalctl -u meknow-api -f
```

### 4. Tests fonctionnels

```bash
# API
curl -s http://localhost:9000/api/products | jq '.' | head -20

# Frontend
curl -s http://localhost:3000 | grep -i "meknow" || echo "Frontend OK"

# Admin
curl -s http://localhost:9000/admin
```

## 📊 Comparaison avant/après

### Docker
```
Démarrage: docker-compose up
Gestion: docker ps, docker logs
Monitoring: docker stats
Espace: 500MB-2GB (images + volumes)
```

### Natif
```
Démarrage: systemctl start meknow-api meknow-web
Gestion: systemctl, journalctl
Monitoring: systemctl status, htop, vmstat
Espace: ~200MB (node_modules)
```

## 🔄 Dépannage migration

### Erreur: "Port déjà utilisé"

```bash
# Trouver le processus utilisant le port
sudo lsof -i :9000
sudo lsof -i :3000

# Tuer le processus
sudo kill -9 <PID>
```

### Erreur: "Impossible de se connecter à PostgreSQL"

```bash
# Vérifier que PostgreSQL fonctionne
sudo systemctl status postgresql

# Tester la connexion
psql -h localhost -U meknow_user -d meknow_production -c "SELECT NOW();"
```

### Erreur: "Permission denied"

```bash
# Assurer les permissions correctes
sudo chown -R www-data:www-data /var/www/meknow
sudo chmod -R 755 /var/www/meknow
```

### Erreur: "Service failed to start"

```bash
# Voir les détails de l'erreur
sudo systemctl status meknow-api
sudo journalctl -u meknow-api -n 100

# Vérifier les fichiers .env
cat /var/www/meknow/.env
```

## 🆘 Rollback (Retour à Docker)

Si vous devez revenir à Docker :

```bash
# Arrêter les services natifs
sudo systemctl stop meknow-api meknow-web

# Restaurer les fichiers Docker
cd /var/www/meknow
git checkout docker-compose.yml Dockerfile*

# Redémarrer Docker
docker-compose up -d
```

## 📈 Avantages du déploiement natif

- ✅ **Performance** : Pas de surcharge Docker
- ✅ **Mémoire** : Moins de consommation RAM
- ✅ **Simplicité** : Moins de couches
- ✅ **Monitoring** : Outils Linux natifs
- ✅ **Logs** : Intégration systemd/journalctl
- ✅ **Coûts** : Ressources réduites

## 📞 Support

Pour chaque erreur, consultez :
1. Les logs : `sudo journalctl -u meknow-api -f`
2. Le fichier `.env` : Assurez-vous que les variables sont correctes
3. La documentation : `NATIVE-DEPLOYMENT.md`

---

**🎉 Félicitations pour votre migration!**
