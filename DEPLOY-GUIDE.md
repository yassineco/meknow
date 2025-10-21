# 🚀 Guide de Déploiement Meknow E-commerce

## 📋 Options de Déploiement

### **Option 1 : Déploiement Rapide avec Script Automatisé** ⭐

```bash
# 1. Cloner le projet
git clone https://github.com/yassineco/meknow.git
cd meknow

# 2. Lancer le déploiement automatisé
./deploy-production.sh

# 3. Choisir "5" pour déploiement complet
```

### **Option 2 : Déploiement Docker** 🐳

```bash
# 1. Préparer l'environnement
cp .env.production .env

# 2. Construire et démarrer
docker-compose up -d

# 3. Vérifier les services
docker-compose ps
```

### **Option 3 : Déploiement PM2** 🚀

```bash
# 1. Installer les dépendances
npm install
cd menow-web && npm install && cd ..

# 2. Construire le frontend
cd menow-web && npm run build && cd ..

# 3. Démarrer avec PM2
pm2 start ecosystem.config.js --env production
pm2 save
```

## 🛠️ Configuration Serveur

### **Prérequis Système**
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y nodejs npm nginx certbot postgresql

# Install PM2
sudo npm install -g pm2

# Install Docker (optionnel)
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
```

### **Base de Données PostgreSQL**
```bash
# 1. Créer la base
sudo -u postgres createdb meknow_production

# 2. Créer l'utilisateur
sudo -u postgres psql -c "CREATE USER meknow_user WITH PASSWORD 'meknow2024!';"

# 3. Donner les permissions
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE meknow_production TO meknow_user;"
```

## 🌐 Configuration Nginx + SSL

### **Configuration Nginx**
```nginx
# /etc/nginx/sites-available/meknow
server {
    listen 80;
    server_name meknow.fr www.meknow.fr;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name meknow.fr www.meknow.fr;

    # SSL
    ssl_certificate /etc/letsencrypt/live/meknow.fr/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/meknow.fr/privkey.pem;
    
    # Frontend Next.js
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
    
    # API + Admin
    location /api/ {
        proxy_pass http://localhost:9000;
    }
    
    location /admin {
        proxy_pass http://localhost:9000;
    }
}
```

### **SSL Let's Encrypt**
```bash
# Obtenir certificat
sudo certbot --nginx -d meknow.fr -d www.meknow.fr

# Auto-renouvellement
echo "0 12 * * * /usr/bin/certbot renew --quiet" | sudo crontab -
```

## 📊 Validation du Déploiement

### **Tests de Santé**
```bash
# Backend API
curl http://localhost:9000/api/products

# Nouvelles routes rubriques
curl http://localhost:9000/api/products/catalog
curl http://localhost:9000/api/products/lookbook

# Frontend
curl http://localhost:3000

# Interface Admin
curl http://localhost:9000/admin
```

### **Monitoring PM2**
```bash
# Statut des processus
pm2 status

# Logs en temps réel
pm2 logs

# Monitoring ressources
pm2 monit

# Redémarrer un service
pm2 restart meknow-backend
```

## 🔧 Configuration DNS

### **Enregistrements DNS requis**
```
Type    Nom              Valeur
A       meknow.fr        YOUR_SERVER_IP
A       www.meknow.fr    YOUR_SERVER_IP
CNAME   api.meknow.fr    meknow.fr
CNAME   admin.meknow.fr  meknow.fr
```

## 🚨 Dépannage

### **Problèmes Courants**

#### **Backend ne démarre pas**
```bash
# Vérifier les logs
pm2 logs meknow-backend

# Vérifier la base de données
pg_isready -h localhost -p 5432

# Redémarrer le service
pm2 restart meknow-backend
```

#### **Frontend erreurs 500**
```bash
# Vérifier la configuration
cd menow-web && cat .env.local

# Rebuilder
npm run build

# Redémarrer
pm2 restart meknow-frontend
```

#### **SSL/Nginx erreurs**
```bash
# Tester la configuration
sudo nginx -t

# Recharger Nginx
sudo systemctl reload nginx

# Vérifier SSL
sudo certbot certificates
```

## 📈 Optimisations Production

### **Performance**
- ✅ Compression Gzip activée
- ✅ Cache statique (7 jours)
- ✅ Headers de sécurité
- ✅ Monitoring PM2
- ✅ Auto-restart processus

### **Sécurité**
- ✅ HTTPS forcé
- ✅ Headers sécurisés
- ✅ CORS configuré
- ✅ Variables sensibles protégées

### **Monitoring**
- ✅ Logs centralisés PM2
- ✅ Healthchecks automatiques
- ✅ Métriques ressources
- ✅ Alertes erreurs

## 🎯 URLs de Production

Une fois déployé, votre plateforme sera accessible sur :

- **Site public** : https://meknow.fr
- **Interface admin** : https://meknow.fr/admin  
- **API Catalogue** : https://meknow.fr/api/products/catalog
- **API Lookbook** : https://meknow.fr/api/products/lookbook

## 💡 Support

En cas de problème :
1. Consulter les logs : `pm2 logs`
2. Vérifier la documentation API
3. Tester les endpoints individuellement
4. Redémarrer les services si nécessaire

---

**🎉 Félicitations ! Votre plateforme e-commerce Meknow avec gestion rubriques est déployée !**