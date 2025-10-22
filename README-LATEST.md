# 🛍️ Meknow - Plateforme E-commerce Premium

**Meknow** est une plateforme e-commerce premium made in Morocco, développée avec une architecture full-stack moderne et native (sans Docker).

> 🚀 **Statut : EN DÉVELOPPEMENT AVANCÉ** - Architecture native complète avec PostgreSQL + Express.js + Next.js 14

---

## 📋 État Actuel du Projet

### 🎉 DÉPLOYÉ EN PRODUCTION - 22 octobre 2025

**Status**: ✅ LIVE on VPS (31.97.196.215)  
**All Services**: ✅ RUNNING  
**Uptime**: Started 13:14 UTC  

### ✅ Fonctionnalités Actives

| Fonctionnalité | Status | Description |
|---|---|---|
| **Backend API** | ✅ Production | Express.js sur port 9000 - LIVE |
| **Frontend** | ✅ Production | Next.js 14 sur port 3000 - LIVE |
| **PostgreSQL** | ✅ Production | Base de données native persistante - LIVE |
| **Interface Admin** | ✅ Fonctionnelle | Gestion complète des produits - LIVE |
| **Gestion Produits** | ✅ CRUD complet | 4 produits, 3 lookbook items - LIVE |
| **Persistance Données** | ✅ PostgreSQL | Versioning JSONB implementé - LIVE |
| **Images** | ✅ Servies | Backend serve les images statiques - LIVE |
| **CSS Styling** | ✅ Appliqué | Tailwind + custom CSS importé - LIVE |
| **Nginx Reverse Proxy** | ✅ Configured | Ports 80/443 - READY |
| **systemd Services** | ✅ Enabled | Auto-restart ON - LIVE |
| **SSL/TLS** | ⏳ Ready | Let's Encrypt configured - Awaiting domain |

---

## 🚀 Production Deployment Status

### Live Endpoints (VPS 31.97.196.215)

```
✅ Backend API        : http://localhost:9000/api (internal)
✅ Frontend          : http://localhost:3000 (internal)
✅ Admin Interface   : http://localhost:9000/admin
✅ Health Check      : http://localhost:9000/health
✅ Products API      : http://localhost:9000/api/products
✅ Lookbook API      : http://localhost:9000/api/products/lookbook

📊 Metrics:
   - Backend Process ID: 277746
   - Frontend Process ID: 276475
   - Memory (Backend): 33.3 MB
   - Memory (Frontend): 89.5 MB
   - Database: 4 products (ready for content)
   - Lookbook: 3 items displayed
```

### Service Status

| Service | Status | Port | PID | Uptime |
|---------|--------|------|-----|--------|
| Backend (Node.js) | ✅ Running | 9000 | 277746 | 13:14 UTC |
| Frontend (Next.js) | ✅ Running | 3000 | 276475 | 13:10 UTC |
| PostgreSQL 16 | ✅ Running | 5432 | - | 12:59 UTC |
| Nginx | ✅ Running | 80/443 | 276641 | 13:11 UTC |
| systemd | ✅ Enabled | - | - | Auto-restart ON |

---

## 🏗️ Architecture Technique

### Stack Productif

```
Frontend (Port 3000)
├── Next.js 14 (App Router) - v14.2.33
├── React 18.3.1 + TypeScript
├── Tailwind CSS 3.4.18
├── Custom CSS (theme.css)
└── SSR + ISR enabled

Backend (Port 9000)
├── Express.js 5.1.0
├── Node.js 18.19.1
├── PostgreSQL connection pooling
├── JSONB versioning
├── Admin HTML interface
└── Static file serving

Database (Port 5432)
├── PostgreSQL 16.10
├── Database: meknow_production
├── User: meknow (limited privileges)
├── Table: products_data (versioned)
└── Max version: Auto-increment

Infrastructure
├── Nginx 1.24.0 (Reverse Proxy)
├── systemd services (Auto-restart)
├── Let's Encrypt ready
└── Ubuntu 24.04 LTS
```

### Architecture Deployment (Native - Pas de Docker)

```
VPS Ubuntu 24.04 (31.97.196.215)
│
├── PostgreSQL 16 (port 5432)
│   └── meknow_production database
│
├── Backend Express.js
│   ├── Node.js process
│   ├── port 9000
│   └── PM2 supervision
│
├── Frontend Next.js
│   ├── Node.js process
│   ├── port 3000
│   └── PM2 supervision
│
└── Nginx (reverse proxy)
    ├── Port 80 (HTTP)
    ├── Port 443 (HTTPS/SSL)
    └── meknow.fr domain
```

---

## 🚀 Déploiement & Installation

### Prérequis

- Node.js 18+
- PostgreSQL 14+
- npm ou pnpm
- VPS Ubuntu 24.04 (pour production)

### Installation Locale

```bash
# 1. Cloner le repository
git clone https://github.com/yassineco/meknow.git
cd meknow

# 2. Installer les dépendances
npm install
cd menow-web && npm install && cd ..

# 3. Configurer PostgreSQL
sudo -u postgres psql -d meknow_production -f schema.sql

# 4. Variables d'environnement
# Backend
cat > .env << EOF
DB_USER=postgres
DB_PASSWORD=postgres
DB_HOST=localhost
DB_PORT=5432
DB_NAME=meknow_production
EOF

# Frontend
cat > menow-web/.env.local << EOF
NEXT_PUBLIC_API_URL=http://localhost:9000
NEXT_PUBLIC_BASE_URL=http://localhost:3000
EOF

# 5. Démarrer les serveurs
node backend-minimal.js &                 # Backend port 9000
cd menow-web && npm start &              # Frontend port 3000
```

### Déploiement Production (VPS Native)

```bash
# 1. SSH sur le VPS
ssh root@31.97.196.215

# 2. Cloner et installer
git clone https://github.com/yassineco/meknow.git /var/www/meknow
cd /var/www/meknow
npm install --production
cd menow-web && npm install --production && npm run build

# 3. Configurer les services
# Backend
sudo tee /etc/systemd/system/meknow-backend.service > /dev/null << EOF
[Unit]
Description=Meknow Backend
After=network.target

[Service]
Type=simple
User=meknow
WorkingDirectory=/var/www/meknow
ExecStart=/usr/bin/node backend-minimal.js
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Frontend
sudo tee /etc/systemd/system/meknow-frontend.service > /dev/null << EOF
[Unit]
Description=Meknow Frontend
After=network.target

[Service]
Type=simple
User=meknow
WorkingDirectory=/var/www/meknow/menow-web
ExecStart=/usr/bin/npm start
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# 4. Activer et démarrer les services
sudo systemctl daemon-reload
sudo systemctl enable meknow-backend meknow-frontend
sudo systemctl start meknow-backend meknow-frontend

# 5. Configurer Nginx
sudo tee /etc/nginx/sites-available/meknow.fr > /dev/null << EOF
upstream backend {
    server 127.0.0.1:9000;
}

upstream frontend {
    server 127.0.0.1:3000;
}

server {
    listen 80;
    server_name meknow.fr www.meknow.fr;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name meknow.fr www.meknow.fr;
    
    ssl_certificate /etc/letsencrypt/live/meknow.fr/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/meknow.fr/privkey.pem;
    
    location /api {
        proxy_pass http://backend;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
    
    location / {
        proxy_pass http://frontend;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

sudo nginx -t && sudo systemctl reload nginx
```

---

## 📊 Modifications Récentes (v1.2.0)

### 🎨 Corrections Frontend (22 oct 2025)

#### 1. **SVG Header Fix**
- **Problème** : SVG avec viewBox invalide causant erreur client-side
- **Avant** : `viewBox="0 0 20 20"` avec coordonnées jusqu'à `L22`
- **Après** : `viewBox="0 0 24 24"`
- **Fichier** : `menow-web/src/components/Header.tsx`
- **Impact** : ✅ Frontend affiche sans erreur

#### 2. **CSS Theme Import**
- **Problème** : Classes `.card__image-wrapper`, `.card__overlay`, `.grid--3` ne s'appliquaient pas
- **Solution** : Importé `@import './theme.css';` dans `globals.css`
- **Fichier** : `menow-web/src/styles/globals.css`
- **Impact** : ✅ Lookbook section affiche avec style correct

#### 3. **Image URL Fix**
- **Problème** : Images ne s'affichaient pas (404 errors)
- **Cause** : Frontend chargeait depuis `localhost:3000/images` au lieu du backend
- **Solution** : Modifié `getImageUrl()` pour ajouter prefix `NEXT_PUBLIC_API_URL`
- **Fichier** : `menow-web/src/lib/utils.ts`
- **Impact** : ✅ Images servies depuis backend (localhost:9000/images)

#### 4. **Symlinks Images**
- **Créé** : Liens symboliques pour images manquantes
  ```bash
  test.jpg → luxury_fashion_jacke_28fde759.jpg
  test-veste.jpg → luxury_fashion_jacke_45c6de81.jpg
  ```
- **Location** : `/public/images/`
- **Impact** : ✅ Toutes les images accessible

### 📦 Modifications Backend

#### 1. **PostgreSQL Persistence**
- **Implémenté** : Sauvegarde en JSONB avec versioning
- **Table** : `products_data` avec colonne `version`
- **Avantage** : Historique complet + rollback possible

#### 2. **Suppression Seed Data Fallback**
- **Avant** : `products = SEED_PRODUCTS` si base vide
- **Après** : `products = []` (charge uniquement PostgreSQL)
- **Impact** : Pas d'overwrite accidentel au redémarrage

#### 3. **Upload Images**
- **Endpoint** : `POST /api/upload`
- **Chemin** : `/public/images/`
- **Servé par** : Express static middleware

### 🗄️ Modifications Database

#### Historique PostgreSQL
```sql
-- Version 10 : 5 produits (stable)
-- Version 11 : 4 produits (après suppression test)
-- Version 12 : 3 produits (après suppression test 2)
-- Version 13+ : 6 produits (avec lookbook items)
```

#### Produits Lookbook Créés
1. Chemise Lookbook (8900€)
2. Veste Élégante (12500€)
3. Pantalon Luxury (9900€)
4. Robe Cocktail (14900€)

---

## 🔧 Configuration Système

### Fichiers Clés

```
meknow/
├── backend-minimal.js              # Backend Express.js
├── package.json                    # Dépendances racine
├── .env                            # Variables backend
│
├── menow-web/                      # Frontend Next.js
│   ├── package.json
│   ├── .env.local                  # Variables frontend
│   ├── src/
│   │   ├── app/
│   │   │   ├── layout.tsx          # Layout racine
│   │   │   └── page.tsx            # Page d'accueil
│   │   ├── components/
│   │   │   ├── Header.tsx          # ✅ Fixé SVG
│   │   │   ├── Lookbook.tsx        # Section produits
│   │   │   ├── ProductCard.tsx     # Carte produit
│   │   │   └── FeaturedCollection.tsx
│   │   ├── styles/
│   │   │   ├── globals.css         # ✅ Importé theme.css
│   │   │   └── theme.css           # ✅ Classes custom
│   │   └── lib/
│   │       ├── utils.ts            # ✅ Fixé getImageUrl()
│   │       └── api.ts
│   └── public/
│       ├── images/                 # ✅ Symlinks créés
│       └── logo.png
│
└── public/images/                  # Images statiques
```

### Variables d'Environnement

**Backend (.env)**
```env
DB_USER=postgres
DB_PASSWORD=postgres
DB_HOST=localhost
DB_PORT=5432
DB_NAME=meknow_production
```

**Frontend (.env.local)**
```env
NEXT_PUBLIC_API_URL=http://localhost:9000
NEXT_PUBLIC_BASE_URL=http://localhost:3000
```

---

## 📈 Plan de Déploiement Production

### Phase 1 : Préparation (Jour 1)
- [ ] Vérifier VPS Ubuntu 24.04
- [ ] Installer Node.js, PostgreSQL, Nginx
- [ ] Configurer domaine meknow.fr
- [ ] Générer certificat SSL Let's Encrypt

### Phase 2 : Déploiement (Jour 2)
- [ ] Cloner repository
- [ ] Configurer variables d'environnement
- [ ] Exécuter migrations PostgreSQL
- [ ] Démarrer services systemd
- [ ] Configurer Nginx reverse proxy

### Phase 3 : Validation (Jour 3)
- [ ] Tester backend API (https://meknow.fr/api/products)
- [ ] Tester frontend (https://meknow.fr)
- [ ] Tester admin (https://meknow.fr/admin)
- [ ] Vérifier HTTPS/SSL
- [ ] Tester gestion produits admin

### Phase 4 : Monitoring (En continu)
- [ ] PM2 monitoring
- [ ] PostgreSQL backups
- [ ] Log rotation
- [ ] Performance monitoring

---

## 🔧 Administration & Monitoring

### Quick Administration Commands

```bash
# Check service status
systemctl status meknow-backend.service meknow-frontend.service nginx

# Restart services
systemctl restart meknow-backend.service meknow-frontend.service

# View backend logs
journalctl -u meknow-backend.service -f

# View frontend logs
journalctl -u meknow-frontend.service -f

# Test API
curl http://localhost:9000/health
curl http://localhost:9000/api/products | jq .

# Connect to database
sudo -u postgres psql -d meknow_production
```

### Full Command Reference

**See `ADMINISTRATION-COMMANDS.md` for comprehensive list of:**
- Service management commands
- Monitoring & logging
- Database operations
- API testing
- Backup & restore
- Emergency procedures
- Common workflows

---

## 🐛 Troubleshooting

### Les images ne s'affichent pas
```bash
# Vérifier les symlinks
ls -la /media/yassine/IA/Projects/menow/public/images/test*

# Vérifier le backend sert les images
curl -I http://localhost:9000/images/test.jpg

# Vérifier la variable d'environnement
echo $NEXT_PUBLIC_API_URL
```

### Frontend ne se connecte pas au backend
```bash
# Vérifier .env.local
cat menow-web/.env.local

# Vérifier backend tourne
ps aux | grep "node backend"

# Tester API backend
curl http://localhost:9000/api/products
```

### PostgreSQL ne répond pas
```bash
# Vérifier le service
sudo systemctl status postgresql

# Vérifier la connexion
psql -U postgres -d meknow_production -c "SELECT COUNT(*) FROM products_data;"
```

---

## 📞 Support & Contacts

- **Documentation** : Ce README
- **Rapport** : `RAPPORT-AVANCEMENT.md`
- **Issues GitHub** : github.com/yassineco/meknow/issues
- **VPS** : 31.97.196.215
- **Domaine** : meknow.fr

---

## 📜 Licence & Credits

Développé pour Meknow - Made in Morocco ✨

**Stack Open Source :**
- Node.js / npm
- Express.js
- Next.js 14
- PostgreSQL
- Tailwind CSS
- Nginx

---

**Dernière mise à jour** : 22 octobre 2025  
**Version** : 1.2.0  
**Branche Git** : frontend-sync-complete
