# 🚀 COMMANDES VPS - Copier-Coller

## Étape 1 : Connexion au VPS

```bash
ssh root@your_vps_ip
# Tapez votre mot de passe root
```

## Étape 2 : Vérifier que vous êtes sur le VPS

```bash
pwd
# Vous devriez voir: /root
```

## Étape 3 : Cloner ou mettre à jour le projet

```bash
# Si c'est la première fois:
cd /var/www
git clone https://github.com/yassineco/meknow.git
cd meknow

# Si le projet existe déjà:
cd /var/www/meknow
git fetch origin
git checkout frontend-sync-complete
git pull origin frontend-sync-complete
```

## Étape 4 : Lancer le déploiement automatique

```bash
cd /var/www/meknow
sudo bash deploy-vps-native.sh
```

Cela vous présentera un menu interactif :
- Appuyez sur `1` pour le déploiement rapide complet
- Ou choisissez les étapes individuelles

## Étape 5 : Vérifier le statut après déploiement

```bash
# Vérifier les services
sudo systemctl status meknow-api meknow-web

# Voir les logs en temps réel
sudo journalctl -u meknow-api -f
```

## Étape 6 : Configurer Nginx (optionnel)

```bash
# Si vous n'avez pas de proxy Nginx configuré
sudo nano /etc/nginx/sites-available/meknow

# Ajouter cette configuration:
server {
    listen 80;
    server_name your_domain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /api {
        proxy_pass http://localhost:9000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}

# Activer la configuration
sudo ln -s /etc/nginx/sites-available/meknow /etc/nginx/sites-enabled/
sudo systemctl reload nginx
```

---

## 📋 COMMANDES DE DÉPANNAGE

### Si les services ne démarrent pas

```bash
# Voir les erreurs détaillées
sudo journalctl -u meknow-api -n 50
sudo journalctl -u meknow-web -n 50

# Redémarrer
sudo systemctl restart meknow-api meknow-web

# Vérifier les permissions
sudo chown -R www-data:www-data /var/www/meknow
sudo chmod -R 755 /var/www/meknow
```

### Si un port est déjà utilisé

```bash
# Voir quel processus utilise le port
sudo lsof -i :9000
sudo lsof -i :3000

# Tuer le processus
sudo kill -9 <PID>
```

### Si la base de données ne se connecte pas

```bash
# Vérifier PostgreSQL
sudo systemctl status postgresql

# Tester la connexion
psql -h localhost -U meknow_user -d meknow_production -c "SELECT NOW();"
```

### Pour voir les logs en temps réel

```bash
# Logs backend
sudo journalctl -u meknow-api -f

# Logs frontend
sudo journalctl -u meknow-web -f

# Tous les logs Meknow
sudo journalctl -u meknow-api -u meknow-web -f
```

---

## 🆘 ROLLBACK - Revenir à Docker

Si quelque chose se passe mal, vous pouvez revenir à Docker :

```bash
# Arrêter les services natifs
sudo systemctl stop meknow-api meknow-web

# Vérifier que le projet a la config Docker
cd /var/www/meknow
git status

# Redémarrer Docker
docker-compose up -d

# Vérifier
docker ps
curl http://localhost:9000/api/products
```

---

## ✅ TEST COMPLET

Une fois le déploiement terminé, testez tout :

```bash
# 1. Vérifier l'API
curl http://localhost:9000/api/products | head -20

# 2. Vérifier le frontend
curl http://localhost:3000 | grep "<title>" | head -5

# 3. Vérifier l'admin
curl -I http://localhost:9000/admin

# 4. Vérifier la base de données
psql -h localhost -U meknow_user -d meknow_production -c "SELECT COUNT(*) FROM products;"
```

---

**Tout est automatisé ! Il suffit de copier-coller les commandes et de taper votre mot de passe root quand c'est demandé. 🎉**
