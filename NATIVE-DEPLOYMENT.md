# 🚀 Guide de Déploiement Natif - Meknow E-commerce

Ce guide explique comment déployer Meknow **sans Docker** directement sur un serveur Linux.

## 📋 Prérequis

- **Node.js** 18+ : `node --version`
- **npm** 8+ : `npm --version`
- **PostgreSQL** 12+ : `psql --version`
- **Nginx** (optionnel, pour reverse proxy)
- **PM2** (optionnel, pour gestion des processus)

## 🔧 Installation des dépendances système

### Sur Ubuntu/Debian

```bash
# Mise à jour du système
sudo apt update && sudo apt upgrade -y

# Installation Node.js et npm
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Installation PostgreSQL
sudo apt install -y postgresql postgresql-contrib

# Installation Nginx (optionnel)
sudo apt install -y nginx

# Installation PM2 globalement (optionnel, pour production)
sudo npm install -g pm2
```

## 📂 Préparation du projet

### 1. Cloner/télécharger le projet

```bash
cd /var/www
git clone https://github.com/yassineco/meknow.git
cd meknow
```

### 2. Installer les dépendances

```bash
# Dépendances du projet racine
npm install

# Dépendances du frontend
npm run build:web

# Ou installer séparément
cd menow-web && npm install && npm run build && cd ..
```

### 3. Configuration des variables d'environnement

#### Fichier `.env` (racine)
```bash
# Backend
NODE_ENV=production
PORT=9000
API_URL=http://localhost:9000
NEXT_PUBLIC_API_URL=http://localhost:9000

# Base de données
DB_HOST=localhost
DB_PORT=5432
DB_NAME=meknow_production
DB_USER=meknow_user
DB_PASSWORD=secure_password_here
JWT_SECRET=your_jwt_secret_here

# Frontend
NEXT_PUBLIC_BASE_URL=https://yourdomain.com
```

#### Fichier `.env.local` (menow-web/)
```bash
NODE_ENV=production
NEXT_PUBLIC_API_URL=http://localhost:9000
```

### 4. Créer la base de données

```bash
# Se connecter à PostgreSQL
sudo -u postgres psql

# Créer l'utilisateur et la base de données
CREATE USER meknow_user WITH PASSWORD 'secure_password_here';
CREATE DATABASE meknow_production OWNER meknow_user;
GRANT ALL PRIVILEGES ON DATABASE meknow_production TO meknow_user;
\q

# Initialiser le schéma (si un fichier schema.sql existe)
psql -h localhost -U meknow_user -d meknow_production -f schema.sql
```

## 🚀 Lancement en production

### Option 1 : Avec PM2 (Recommandé)

```bash
# Installer PM2 globalement
sudo npm install -g pm2

# Créer un fichier ecosystem.config.js (fourni avec le projet)
# Vous pouvez utiliser celui existant ou en créer un nouveau

# Démarrer avec PM2
pm2 start ecosystem.config.js --env production

# Sauvegarder la configuration PM2
pm2 save

# Configurer le démarrage automatique au boot
pm2 startup
sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u $(whoami) --hp $(eval echo ~$(whoami))
```

### Option 2 : Avec systemd (Plus natif)

Voir les sections ci-dessous pour la création de services systemd.

### Option 3 : Lancement manuel

```bash
# Terminal 1 - Backend
cd /var/www/meknow
node backend-minimal.js

# Terminal 2 - Frontend
cd /var/www/meknow/menow-web
npm run start
```

## 🔄 Configuration Nginx (Reverse Proxy)

Créer `/etc/nginx/sites-available/meknow`:

```nginx
upstream api_backend {
    server 127.0.0.1:9000;
}

upstream nextjs_app {
    server 127.0.0.1:3000;
}

server {
    listen 80;
    listen [::]:80;
    server_name yourdomain.com www.yourdomain.com;

    # Redirection HTTP vers HTTPS (optionnel)
    # return 301 https://$server_name$request_uri;

    # API Backend
    location /api/ {
        proxy_pass http://api_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Frontend Next.js
    location / {
        proxy_pass http://nextjs_app;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

Activer la configuration :
```bash
sudo ln -s /etc/nginx/sites-available/meknow /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

## 🛡️ Configuration SSL avec Let's Encrypt

```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

## 📊 Monitoring et Logs

### Avec PM2
```bash
# Voir les logs
pm2 logs

# Voir le statut
pm2 status

# Redémarrer
pm2 restart all
pm2 reload all
```

### Logs système
```bash
# Backend
tail -f /var/log/meknow-api.log

# Frontend
tail -f /var/log/meknow-web.log

# Nginx
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log
```

## 🔄 Mise à jour du projet

```bash
cd /var/www/meknow

# Récupérer les dernières modifications
git pull origin main

# Installer les nouvelles dépendances (si besoin)
npm install
cd menow-web && npm install && cd ..

# Reconstruire le frontend
npm run build:web

# Redémarrer les services
pm2 restart all
# ou
sudo systemctl restart meknow-api meknow-web
```

## 🚨 Dépannage

### Erreur de port déjà utilisé
```bash
# Trouver le processus utilisant le port
sudo lsof -i :9000
sudo lsof -i :3000

# Tuer le processus
kill -9 <PID>
```

### Erreur de base de données
```bash
# Vérifier la connexion PostgreSQL
psql -h localhost -U meknow_user -d meknow_production -c "SELECT NOW();"
```

### Erreur Nginx
```bash
sudo nginx -t
sudo systemctl status nginx
sudo systemctl restart nginx
```

## 📋 Checklist de déploiement

- [ ] Node.js 18+ installé
- [ ] PostgreSQL installé et configuré
- [ ] Variables d'environnement configurées
- [ ] Base de données créée
- [ ] Dépendances installées (`npm install`)
- [ ] Frontend construit (`npm run build:web`)
- [ ] Services configurés (PM2 ou systemd)
- [ ] Nginx configuré et SSL activé
- [ ] Firewall configuré pour ports 80, 443, 9000
- [ ] Sauvegardes automatiques configurées

## 🆘 Support

Pour plus d'aide, consultez :
- [Documentation Node.js](https://nodejs.org/docs/)
- [Documentation Express.js](https://expressjs.com/)
- [Documentation Next.js](https://nextjs.org/docs)
- [Documentation PostgreSQL](https://www.postgresql.org/docs/)
- [Documentation PM2](https://pm2.keymetrics.io/docs/usage/quick-start/)
