# 🚀 Déploiement Natif - Quick Start

## ⚡ Démarrage rapide (5 minutes)

### 1. Prérequis installés
```bash
sudo apt update && sudo apt upgrade -y
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs postgresql postgresql-contrib nginx
sudo npm install -g pm2
```

### 2. Cloner et configurer
```bash
cd /var/www
git clone https://github.com/yassineco/meknow.git
cd meknow

# Copier et éditer les variables d'environnement
cp .env.example .env
nano .env  # Éditer avec vos valeurs

cp menow-web/.env.local.example menow-web/.env.local
nano menow-web/.env.local
```

### 3. Base de données
```bash
# Créer la base de données PostgreSQL
sudo -u postgres psql << EOF
CREATE USER meknow_user WITH PASSWORD 'votre_motdepasse';
CREATE DATABASE meknow_production OWNER meknow_user;
GRANT ALL PRIVILEGES ON DATABASE meknow_production TO meknow_user;
EOF

# Initialiser le schéma (si nécessaire)
psql -h localhost -U meknow_user -d meknow_production -f schema.sql
```

### 4. Installer et déployer
```bash
# Installer les dépendances
npm install --production
cd menow-web && npm install --production && npm run build && cd ..

# Option A: Avec PM2 (Recommandé pour production)
pm2 start ecosystem.config.js --env production
pm2 save
pm2 startup

# Option B: Avec systemd
sudo bash install-systemd.sh
sudo systemctl start meknow-api meknow-web
sudo systemctl enable meknow-api meknow-web

# Option C: Manuellement (développement)
npm run dev  # Lance les deux services
```

### 5. Configurer Nginx (reverse proxy)
```bash
# Copier la configuration Nginx
sudo cp nginx-meknow.conf /etc/nginx/sites-available/meknow
sudo ln -s /etc/nginx/sites-available/meknow /etc/nginx/sites-enabled/

# Tester et redémarrer
sudo nginx -t
sudo systemctl restart nginx

# (Optionnel) Ajouter SSL avec Let's Encrypt
sudo certbot --nginx -d yourdomain.com
```

### 6. Vérifier que tout fonctionne
```bash
# Vérifier les services
pm2 status
# ou
sudo systemctl status meknow-api meknow-web

# Tester l'API
curl http://localhost:9000/api/products

# Tester le frontend
curl http://localhost:3000
```

## 📊 Commandes utiles

### Avec PM2
```bash
pm2 logs              # Afficher les logs
pm2 status            # État des services
pm2 restart all       # Redémarrer
pm2 stop all          # Arrêter
pm2 reload all        # Rechargement gracieux (zéro downtime)
```

### Avec systemd
```bash
sudo ./manage-services.sh start      # Démarrer
sudo ./manage-services.sh stop       # Arrêter
sudo ./manage-services.sh restart    # Redémarrer
sudo ./manage-services.sh status     # Statut
sudo ./manage-services.sh logs-api   # Logs backend
sudo ./manage-services.sh logs-web   # Logs frontend
sudo ./manage-services.sh update     # Mettre à jour
```

## 🌐 Accès

- **Frontend** : http://localhost:3000 ou https://yourdomain.com
- **API** : http://localhost:9000/api/products
- **Admin** : http://localhost:9000/admin
- **Nginx logs** : `/var/log/nginx/`
- **App logs** : `/var/log/meknow/` ou `pm2 logs`

## 🆘 Dépannage rapide

```bash
# Port déjà utilisé
sudo lsof -i :9000
sudo lsof -i :3000

# Redémarrer PostgreSQL
sudo systemctl restart postgresql

# Vérifier Nginx
sudo nginx -t
sudo systemctl restart nginx

# Logs d'erreur
tail -50 /var/log/meknow/api-err.log
tail -50 /var/log/meknow/web-err.log
```

## 📖 Documentation complète

Consultez `NATIVE-DEPLOYMENT.md` pour un guide détaillé.

## 🔄 Mise à jour du projet

```bash
cd /var/www/meknow

# Avec le script
sudo ./manage-services.sh update

# Manuellement
git pull origin main
npm install --production
cd menow-web && npm install --production && npm run build && cd ..
sudo systemctl restart meknow-api meknow-web
# ou
pm2 restart all
```

---

**🎉 Félicitations! Votre application Meknow est maintenant déployée en natif!**
