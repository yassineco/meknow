# 🚨 GUIDE DE RÉSOLUTION - ERREUR DOCKER VPS

## 📊 Diagnostic du problème

D'après l'erreur que vous montrez, Docker ne trouve pas le fichier `docker-compose.yml` sur votre VPS. Cela peut arriver pour plusieurs raisons :

1. **Le projet n'a pas été cloné correctement** sur le VPS
2. **Vous n'êtes pas dans le bon répertoire** (`/var/www/meknow`)
3. **Le fichier a été supprimé** accidentellement
4. **Problème de permissions** de fichiers

## 🛠️ SOLUTION RAPIDE (Méthode 1 - Urgence)

### Sur votre VPS, exécutez ces commandes :

```bash
# 1. Télécharger le script d'urgence
curl -L https://raw.githubusercontent.com/yassineco/meknow/main/emergency-docker-fix.sh -o emergency-docker-fix.sh

# 2. Le rendre exécutable
chmod +x emergency-docker-fix.sh

# 3. L'exécuter
./emergency-docker-fix.sh
```

## 🔧 SOLUTION COMPLÈTE (Méthode 2 - Recommandée)

### Sur votre VPS, exécutez ces commandes :

```bash
# 1. Télécharger le script complet de correction
curl -L https://raw.githubusercontent.com/yassineco/meknow/main/fix-docker-vps.sh -o fix-docker-vps.sh

# 2. Le rendre exécutable  
chmod +x fix-docker-vps.sh

# 3. L'exécuter
./fix-docker-vps.sh
```

## 🔍 SOLUTION MANUELLE (Méthode 3)

Si les scripts automatiques ne marchent pas, voici la procédure manuelle :

### Étape 1 : Vérifier l'état actuel
```bash
# Vérifier où vous êtes
pwd
ls -la

# Aller dans le bon répertoire
cd /var/www/meknow
```

### Étape 2 : Réinstaller le projet si nécessaire
```bash
# Si le répertoire n'existe pas ou est vide
sudo mkdir -p /var/www/meknow
sudo chown $USER:$USER /var/www/meknow
cd /var/www/meknow

# Cloner le projet
git clone https://github.com/yassineco/meknow.git .
```

### Étape 3 : Vérifier docker-compose.yml
```bash
# Vérifier que le fichier existe
ls -la docker-compose.yml

# Si absent, le télécharger directement
curl -L https://raw.githubusercontent.com/yassineco/meknow/main/docker-compose.yml -o docker-compose.yml
```

### Étape 4 : Créer l'environnement
```bash
# Créer le fichier .env.production
cat > .env.production << 'EOL'
NODE_ENV=production
DATABASE_URL=postgresql://postgres:meknow2024!@database:5432/meknow_production
DB_HOST=database
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=meknow2024!
DB_NAME=meknow_production
API_URL=http://backend:9000
NEXT_PUBLIC_API_URL=https://meknow.fr/api
ENABLE_RUBRIQUES=true
JWT_SECRET=meknow_prod_jwt_key_2024
COOKIE_SECRET=meknow_prod_cookie_key_2024
EOL
```

### Étape 5 : Nettoyer et redémarrer Docker
```bash
# Arrêter les anciens services
docker-compose down 2>/dev/null || true
docker stop $(docker ps -aq) 2>/dev/null || true

# Nettoyer
docker system prune -f

# Modifier les ports pour éviter les conflits
sed -i 's/"3000:3000"/"3001:3000"/g' docker-compose.yml
sed -i 's/"9000:9000"/"9001:9000"/g' docker-compose.yml

# Démarrer les services
docker-compose --env-file .env.production up -d --build
```

## ✅ VÉRIFICATION

Après avoir appliqué une des solutions, vérifiez que tout fonctionne :

```bash
# 1. Vérifier les containers
docker-compose ps

# 2. Vérifier les logs s'il y a des erreurs
docker-compose logs

# 3. Tester l'accès aux services
curl http://localhost:3001   # Frontend
curl http://localhost:9001/health   # Backend API
curl http://localhost:8082   # Interface Admin
```

## 🚨 EN CAS DE PROBLÈME PERSISTANT

Si aucune solution ne fonctionne, voici quelques commandes de diagnostic :

```bash
# Vérifier Docker
docker --version
docker-compose --version

# Vérifier l'espace disque
df -h

# Vérifier les ports utilisés
netstat -tulpn | grep -E ':80|:443|:3000|:3001|:9000|:9001'

# Vérifier les logs système
sudo journalctl -u docker --since "1 hour ago"
```

## 📞 CONTACT

Si le problème persiste malgré toutes ces solutions, merci de fournir :

1. **La sortie de** `pwd` et `ls -la`
2. **La sortie de** `docker-compose ps`
3. **La sortie de** `docker-compose logs`
4. **Votre configuration VPS** (OS, RAM, espace disque)

## 🎯 RÉSUMÉ DES ACTIONS

1. ✅ **Scripts automatiques créés** pour résoudre le problème
2. ✅ **Guide manuel détaillé** en cas de besoin  
3. ✅ **Diagnostics intégrés** pour identifier la cause
4. ✅ **Solutions multiples** selon le niveau de gravité

**Recommandation :** Commencez par la **Méthode 1 (Urgence)** pour une résolution rapide, puis passez à la **Méthode 2 (Complète)** pour une solution robuste.
# 🚨 GUIDE DE RÉSOLUTION - ERREUR DOCKER VPS

## 📊 Diagnostic du problème

D'après l'erreur que vous montrez, Docker ne trouve pas le fichier `docker-compose.yml` sur votre VPS. Cela peut arriver pour plusieurs raisons :

1. **Le projet n'a pas été cloné correctement** sur le VPS
2. **Vous n'êtes pas dans le bon répertoire** (`/var/www/meknow`)
3. **Le fichier a été supprimé** accidentellement
4. **Problème de permissions** de fichiers

## 🛠️ SOLUTION RAPIDE (Méthode 1 - Urgence)

### Sur votre VPS, exécutez ces commandes :

```bash
# 1. Télécharger le script d'urgence
curl -L https://raw.githubusercontent.com/yassineco/meknow/main/emergency-docker-fix.sh -o emergency-docker-fix.sh

# 2. Le rendre exécutable
chmod +x emergency-docker-fix.sh

# 3. L'exécuter
./emergency-docker-fix.sh
```

## 🔧 SOLUTION COMPLÈTE (Méthode 2 - Recommandée)

### Sur votre VPS, exécutez ces commandes :

```bash
# 1. Télécharger le script complet de correction
curl -L https://raw.githubusercontent.com/yassineco/meknow/main/fix-docker-vps.sh -o fix-docker-vps.sh

# 2. Le rendre exécutable  
chmod +x fix-docker-vps.sh

# 3. L'exécuter
./fix-docker-vps.sh
```

## 🔍 SOLUTION MANUELLE (Méthode 3)

Si les scripts automatiques ne marchent pas, voici la procédure manuelle :

### Étape 1 : Vérifier l'état actuel
```bash
# Vérifier où vous êtes
pwd
ls -la

# Aller dans le bon répertoire
cd /var/www/meknow
```

### Étape 2 : Réinstaller le projet si nécessaire
```bash
# Si le répertoire n'existe pas ou est vide
sudo mkdir -p /var/www/meknow
sudo chown $USER:$USER /var/www/meknow
cd /var/www/meknow

# Cloner le projet
git clone https://github.com/yassineco/meknow.git .
```

### Étape 3 : Vérifier docker-compose.yml
```bash
# Vérifier que le fichier existe
ls -la docker-compose.yml

# Si absent, le télécharger directement
curl -L https://raw.githubusercontent.com/yassineco/meknow/main/docker-compose.yml -o docker-compose.yml
```

### Étape 4 : Créer l'environnement
```bash
# Créer le fichier .env.production
cat > .env.production << 'EOL'
NODE_ENV=production
DATABASE_URL=postgresql://postgres:meknow2024!@database:5432/meknow_production
DB_HOST=database
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=meknow2024!
DB_NAME=meknow_production
API_URL=http://backend:9000
NEXT_PUBLIC_API_URL=https://meknow.fr/api
ENABLE_RUBRIQUES=true
JWT_SECRET=meknow_prod_jwt_key_2024
COOKIE_SECRET=meknow_prod_cookie_key_2024
EOL
```

### Étape 5 : Nettoyer et redémarrer Docker
```bash
# Arrêter les anciens services
docker-compose down 2>/dev/null || true
docker stop $(docker ps -aq) 2>/dev/null || true

# Nettoyer
docker system prune -f

# Modifier les ports pour éviter les conflits
sed -i 's/"3000:3000"/"3001:3000"/g' docker-compose.yml
sed -i 's/"9000:9000"/"9001:9000"/g' docker-compose.yml

# Démarrer les services
docker-compose --env-file .env.production up -d --build
```

## ✅ VÉRIFICATION

Après avoir appliqué une des solutions, vérifiez que tout fonctionne :

```bash
# 1. Vérifier les containers
docker-compose ps

# 2. Vérifier les logs s'il y a des erreurs
docker-compose logs

# 3. Tester l'accès aux services
curl http://localhost:3001   # Frontend
curl http://localhost:9001/health   # Backend API
curl http://localhost:8082   # Interface Admin
```

## 🚨 EN CAS DE PROBLÈME PERSISTANT

Si aucune solution ne fonctionne, voici quelques commandes de diagnostic :

```bash
# Vérifier Docker
docker --version
docker-compose --version

# Vérifier l'espace disque
df -h

# Vérifier les ports utilisés
netstat -tulpn | grep -E ':80|:443|:3000|:3001|:9000|:9001'

# Vérifier les logs système
sudo journalctl -u docker --since "1 hour ago"
```

## 📞 CONTACT

Si le problème persiste malgré toutes ces solutions, merci de fournir :

1. **La sortie de** `pwd` et `ls -la`
2. **La sortie de** `docker-compose ps`
3. **La sortie de** `docker-compose logs`
4. **Votre configuration VPS** (OS, RAM, espace disque)

## 🎯 RÉSUMÉ DES ACTIONS

1. ✅ **Scripts automatiques créés** pour résoudre le problème
2. ✅ **Guide manuel détaillé** en cas de besoin  
3. ✅ **Diagnostics intégrés** pour identifier la cause
4. ✅ **Solutions multiples** selon le niveau de gravité

**Recommandation :** Commencez par la **Méthode 1 (Urgence)** pour une résolution rapide, puis passez à la **Méthode 2 (Complète)** pour une solution robuste.