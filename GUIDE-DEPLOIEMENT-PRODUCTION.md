# 🚀 GUIDE DE DÉPLOIEMENT PRODUCTION - MEKNOW

**Date** : 22 octobre 2025  
**Environnement** : VPS Ubuntu 24.04 (31.97.196.215)  
**Domaine** : meknow.fr

---

## 📋 Prérequis

### VPS Requis
- ✅ Ubuntu 24.04 LTS
- ✅ 2 GB RAM minimum
- ✅ 20 GB storage
- ✅ IP publique fixe
- ✅ Root access

### Domaine
- ✅ meknow.fr (DNS configuré vers VPS)
- ✅ www.meknow.fr (CNAME ou A record)

### Logiciels Requis
- ✅ Node.js 18+
- ✅ npm 9+
- ✅ PostgreSQL 14+
- ✅ Nginx 1.18+
- ✅ Git 2.30+
- ✅ Curl/Wget

---

## 🔧 Installation Complète

### Étape 1 : Connection SSH & Setup Initial

```bash
# Connecter au VPS
ssh root@31.97.196.215

# Update système
apt update && apt upgrade -y

# Installer Node.js (via NodeSource)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
apt install -y nodejs

# Vérifier installation
node --version    # v18.x.x
npm --version     # 9.x.x
```

### Étape 2 : Installation PostgreSQL

```bash
# Installer PostgreSQL
apt install -y postgresql postgresql-contrib

# Démarrer le service
systemctl start postgresql
systemctl enable postgresql

# Vérifier
systemctl status postgresql

# Se connecter comme superuser
sudo -u postgres psql

# Créer database (dans psql)
CREATE DATABASE meknow_production;
CREATE USER meknow WITH PASSWORD 'votre_mot_de_passe_securise';
ALTER ROLE meknow SET client_encoding TO 'utf8';
ALTER ROLE meknow SET default_transaction_isolation TO 'read committed';
ALTER ROLE meknow SET default_transaction_deferrable TO on;
ALTER ROLE meknow SET default_transaction_read_committed TO 'on';
GRANT ALL PRIVILEGES ON DATABASE meknow_production TO meknow;
\c meknow_production
GRANT SCHEMA public TO meknow;
\q
```

### Étape 3 : Installation Nginx

```bash
# Installer Nginx
apt install -y nginx

# Démarrer
systemctl start nginx
systemctl enable nginx

# Vérifier
systemctl status nginx
```

### Étape 4 : Setup SSL Let's Encrypt

```bash
# Installer Certbot
apt install -y certbot python3-certbot-nginx

# Générer certificat
certbot certonly --standalone -d meknow.fr -d www.meknow.fr

# Vérifier certificat
ls -la /etc/letsencrypt/live/meknow.fr/
```

### Étape 5 : Créer Utilisateur Meknow

```bash
# Créer utilisateur
useradd -m -s /bin/bash meknow

# Donner permissions sudo (optionnel)
usermod -aG sudo meknow

# Changer vers cet utilisateur
su - meknow
```

### Étape 6 : Cloner & Installer Code

```bash
# Se positionner (en tant que root d'abord)
su -

# Créer répertoire application
mkdir -p /var/www
cd /var/www

# Cloner repository
git clone https://github.com/yassineco/meknow.git
cd meknow

# Changer propriétaire
chown -R meknow:meknow /var/www/meknow

# Se connecter en tant que meknow
su - meknow

# Installer dépendances backend
cd /var/www/meknow
npm install --production

# Installer dépendances frontend
cd menow-web
npm install --production

# Build frontend
npm run build

# Vérifier build
ls -la .next/
```

### Étape 7 : Configuration Variables d'Environnement

```bash
# Backend .env
cd /var/www/meknow
cat > .env << 'EOF'
# Database
DB_USER=meknow
DB_PASSWORD=votre_mot_de_passe_securise
DB_HOST=localhost
DB_PORT=5432
DB_NAME=meknow_production

# Server
NODE_ENV=production
PORT=9000
EOF

# Frontend .env.local
cat > menow-web/.env.local << 'EOF'
# API URLs
NEXT_PUBLIC_API_URL=https://meknow.fr
NEXT_PUBLIC_BASE_URL=https://meknow.fr

# Site config
SITE_NAME=Meknow
SITE_URL=https://meknow.fr
EOF

# Vérifier fichiers
cat .env
cat menow-web/.env.local
```

### Étape 8 : Initialiser PostgreSQL

```bash
# En tant que root
sudo -u postgres psql -d meknow_production -f schema.sql

# Vérifier table
sudo -u postgres psql -d meknow_production -c "
  SELECT table_name FROM information_schema.tables 
  WHERE table_schema = 'public';"
```

---

## 🔄 Configuration Systemd Services

### Backend Service

```bash
# Créer service backend (en tant que root)
sudo tee /etc/systemd/system/meknow-backend.service > /dev/null << 'EOF'
[Unit]
Description=Meknow Backend API
After=network.target postgresql.service
Wants=postgresql.service

[Service]
Type=simple
User=meknow
WorkingDirectory=/var/www/meknow
Environment="NODE_ENV=production"
Environment="PATH=/home/meknow/.npm-global/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ExecStart=/usr/bin/node backend-minimal.js
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Vérifier
systemctl cat meknow-backend.service
```

### Frontend Service

```bash
# Créer service frontend
sudo tee /etc/systemd/system/meknow-frontend.service > /dev/null << 'EOF'
[Unit]
Description=Meknow Frontend (Next.js)
After=network.target

[Service]
Type=simple
User=meknow
WorkingDirectory=/var/www/meknow/menow-web
Environment="NODE_ENV=production"
Environment="PATH=/home/meknow/.npm-global/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ExecStart=/usr/bin/npm start
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Vérifier
systemctl cat meknow-frontend.service
```

### Activer Services

```bash
# Recharger systemd
sudo systemctl daemon-reload

# Activer au démarrage
sudo systemctl enable meknow-backend meknow-frontend postgresql

# Vérifier statut
sudo systemctl status meknow-backend
sudo systemctl status meknow-frontend
```

---

## 🌐 Configuration Nginx

### Configurer VirtualHost

```bash
# Créer configuration (en tant que root)
sudo tee /etc/nginx/sites-available/meknow.fr > /dev/null << 'EOF'
# Redirect HTTP → HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name meknow.fr www.meknow.fr;
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    location / {
        return 301 https://$server_name$request_uri;
    }
}

# HTTPS - Frontend + Backend
upstream frontend {
    server 127.0.0.1:3000;
    keepalive 32;
}

upstream backend {
    server 127.0.0.1:9000;
    keepalive 32;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name meknow.fr www.meknow.fr;
    
    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/meknow.fr/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/meknow.fr/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Gzip compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_min_length 1000;
    
    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' https:; script-src 'self' 'unsafe-inline' 'unsafe-eval' https:;" always;
    
    # Logs
    access_log /var/log/nginx/meknow_access.log combined;
    error_log /var/log/nginx/meknow_error.log warn;
    
    # Root location
    root /var/www/meknow/menow-web/.next;
    
    # API Routes → Backend
    location /api {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
    
    # Images statiques
    location /images {
        alias /var/www/meknow/public/images;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
    
    # Admin interface
    location /admin {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Frontend routes
    location / {
        try_files $uri $uri/ /index.html;
        
        # Cache busting
        if ($request_filename ~ "\.(js|css)$") {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
        
        proxy_pass http://frontend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

# Vérifier syntaxe
sudo nginx -t

# Activer le site
sudo ln -sf /etc/nginx/sites-available/meknow.fr /etc/nginx/sites-enabled/

# Désactiver default
sudo rm -f /etc/nginx/sites-enabled/default

# Recharger Nginx
sudo systemctl reload nginx
```

---

## 🚀 Démarrage des Services

```bash
# Démarrer tous les services
sudo systemctl start meknow-backend
sudo systemctl start meknow-frontend
sudo systemctl start postgresql
sudo systemctl start nginx

# Vérifier statut
sudo systemctl status meknow-backend
sudo systemctl status meknow-frontend
sudo systemctl status postgresql
sudo systemctl status nginx

# Vérifier logs
sudo journalctl -u meknow-backend -f
sudo journalctl -u meknow-frontend -f
```

---

## ✅ Tests de Déploiement

### Test Connectivité

```bash
# Test backend API
curl https://meknow.fr/api/products

# Test frontend
curl https://meknow.fr

# Test admin
curl https://meknow.fr/admin

# Vérifier HTTPS
curl -v https://meknow.fr | head -20
```

### Test Produits

```bash
# Lister produits
curl -s https://meknow.fr/api/products | jq '.products | length'

# Afficher premier produit
curl -s https://meknow.fr/api/products | jq '.products[0].title'

# Tester lookbook
curl -s https://meknow.fr/api/products/lookbook | jq '.products | length'
```

### Test Images

```bash
# Vérifier image accessible
curl -I https://meknow.fr/images/test.jpg

# Télécharger image
curl -O https://meknow.fr/images/test.jpg
file test.jpg
```

---

## 📊 Monitoring & Maintenance

### Vérifier Services

```bash
# Tous les services
sudo systemctl list-units --type=service | grep meknow

# Ports en écoute
sudo netstat -tlnp | grep node
sudo netstat -tlnp | grep nginx
sudo netstat -tlnp | grep 5432

# Logs temps réel
sudo journalctl -f

# Logs spécifiques
sudo journalctl -u meknow-backend -n 100
sudo journalctl -u meknow-frontend -n 100
```

### Performance

```bash
# Utilisation disque
df -h

# Utilisation mémoire
free -h

# Processus Node.js
ps aux | grep node

# Connexions PostgreSQL
sudo -u postgres psql -c "SELECT datname, count(*) FROM pg_stat_activity GROUP BY datname;"
```

### Backups PostgreSQL

```bash
# Backup manuel
sudo -u postgres pg_dump meknow_production > /tmp/meknow_backup.sql

# Backup automatisé (via cron)
0 2 * * * sudo -u postgres pg_dump meknow_production > /home/meknow/backups/meknow_$(date +\%Y\%m\%d).sql
```

---

## 🔄 Mises à Jour

### Update Code

```bash
# Pull latest version
cd /var/www/meknow
git pull origin frontend-sync-complete

# Install dependencies
npm install --production
cd menow-web
npm install --production
npm run build

# Restart services
sudo systemctl restart meknow-backend meknow-frontend
```

### SSL Renewal

```bash
# Renouveler certificat
sudo certbot renew

# Ou manuel
sudo certbot renew --force-renewal -d meknow.fr -d www.meknow.fr

# Reload Nginx
sudo systemctl reload nginx
```

---

## 🐛 Troubleshooting

### Backend ne démarre pas

```bash
# Vérifier logs
sudo journalctl -u meknow-backend -n 50

# Vérifier port
sudo netstat -tlnp | grep 9000

# Test PostgreSQL connection
PGPASSWORD=votre_mot_de_passe psql -h localhost -U meknow -d meknow_production -c "SELECT COUNT(*) FROM products_data;"
```

### Frontend ne démarre pas

```bash
# Vérifier logs
sudo journalctl -u meknow-frontend -n 50

# Vérifier port
sudo netstat -tlnp | grep 3000

# Vérifier build
ls -la /var/www/meknow/menow-web/.next/
```

### Images ne s'affichent pas

```bash
# Vérifier permissions
ls -la /var/www/meknow/public/images/

# Vérifier symlinks
file /var/www/meknow/public/images/test.jpg

# Test direct
curl -I https://meknow.fr/images/test.jpg
```

### SSL Certificate Error

```bash
# Vérifier certificat
sudo ls -la /etc/letsencrypt/live/meknow.fr/

# Renouveler
sudo certbot renew --force-renewal

# Check DNS
nslookup meknow.fr
```

---

## 📞 Support

### Ressources
- **Documentation Next.js** : https://nextjs.org/docs
- **Documentation Express** : https://expressjs.com
- **Documentation PostgreSQL** : https://postgresql.org/docs
- **Documentation Nginx** : https://nginx.org/en/docs

### Logs Importants
```bash
# Backend
/var/log/syslog (systemd logs)
journalctl -u meknow-backend

# Frontend
journalctl -u meknow-frontend

# Nginx
/var/log/nginx/meknow_access.log
/var/log/nginx/meknow_error.log

# PostgreSQL
/var/log/postgresql/
```

---

**Guide créé le 22 octobre 2025**  
**Meknow Production Deployment v1.0**
