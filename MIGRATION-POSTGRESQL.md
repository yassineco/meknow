# 🚀 MIGRATION JSON → PostgreSQL - GUIDE COMPLET

## 📋 Vue d'ensemble

Ce guide explique comment migrer vos produits du système de stockage JSON vers PostgreSQL pour la **persistance complète** des données.

### Problème résolu
❌ **Avant** : Les produits étaient perdus à chaque redémarrage du backend
✅ **Après** : Les produits sont persistés dans PostgreSQL et survivent aux redémarrages

---

## 🔧 Installation & Configuration

### Étape 1: Vérifier les variables d'environnement

Créez un fichier `.env` à la racine du projet :

```bash
cp .env.example .env
```

Editez `.env` avec vos paramètres PostgreSQL :

```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=meknow_production
DB_USER=postgres
DB_PASSWORD=postgres
NODE_ENV=production
PORT=9000
```

### Étape 2: Créer la base de données PostgreSQL

```bash
# Créer la base de données
createdb meknow_production

# Ou avec psql
psql -U postgres -c "CREATE DATABASE meknow_production;"
```

### Étape 3: Initialiser la base de données

```bash
# Initialiser le schéma
npm run db:init

# Ou manuellement
psql -h localhost -U postgres -d meknow_production -f schema.sql
```

---

## ✨ Migration Automatique

### Option 1: Migration Manuelle (Recommandée pour la première fois)

```bash
# Exécuter le script de migration
npm run migrate
```

**Output attendu:**
```
🚀 Starting migration process...

Step 1: Testing PostgreSQL connection
✅ PostgreSQL connected: 2025-10-22 14:35:21...

Step 2: Creating products_data table
✅ Table products_data created or already exists

Step 3: Checking for existing data in PostgreSQL
ℹ️ No existing data found in products_data table

Step 4: Reading products from JSON file
📂 Read 5 products from ./products-data.json

Step 5: Inserting products into PostgreSQL
✅ Products inserted into PostgreSQL
✅ Migration complete: 5 products migrated

🎉 Migration process finished successfully!
```

### Option 2: Migration Automatique au Démarrage

Le backend exécute **automatiquement** la migration à chaque démarrage :

```bash
# Démarrer le backend
npm run api

# Output:
# 🔄 Initializing server...
# 📋 Ensuring products_data table exists...
# ✅ Table products_data is ready
# ✅ Loaded 5 existing products from database
# 🚀 Server ready for requests
```

---

## 🧪 Tester la Persistance

### Test 1: Vérifier les produits en local

```bash
# Démarrer le backend
npm run api

# Dans un autre terminal, tester l'API
curl http://localhost:9000/api/products | jq

# Créer un nouveau produit via l'interface admin
# http://localhost:9000/admin

# Arrêter le backend (Ctrl+C)

# Redémarrer le backend
npm run api

# Les produits doivent toujours être présents !
curl http://localhost:9000/api/products | jq
```

### Test 2: Vérifier directement dans PostgreSQL

```bash
# Se connecter à la base de données
psql -h localhost -U postgres -d meknow_production

# Vérifier les produits
SELECT COUNT(*) as total_products FROM products_data;

# Voir les détails
SELECT jsonb_array_length(products) as product_count, 
       last_modified_at,
       version
FROM products_data 
ORDER BY version DESC 
LIMIT 1;

# Voir les produits (format lisible)
SELECT jsonb_pretty(products) FROM products_data 
ORDER BY version DESC LIMIT 1;
```

---

## 📊 Architecture de Persistance

### Table PostgreSQL: `products_data`

```sql
CREATE TABLE products_data (
  id SERIAL PRIMARY KEY,
  products JSONB NOT NULL,           -- Tous les produits en JSON
  collections JSONB DEFAULT '[]',    -- Collections
  version INTEGER DEFAULT 1,         -- Numéro de version
  last_modified_at TIMESTAMP,        -- Dernière modification
  created_at TIMESTAMP,              -- Création
  UNIQUE(version)                    -- Une version unique
);
```

### Avantages
- ✅ **Flexibilité JSON** : Pas besoin de migrer le schéma
- ✅ **Versioning** : Historique des modifications
- ✅ **Performance** : Index sur version et date
- ✅ **Intégrité** : Contrainte d'unicité sur la version
- ✅ **Backup facile** : Tout est dans PostgreSQL

---

## 🔄 Workflow de Production

### Déploiement avec PM2

Le backend fonctionne automatiquement avec PM2 :

```bash
# Démarrer avec PM2
pm2 start ecosystem.config.js

# Vérifier le statut
pm2 status

# Logs
pm2 logs meknow-api

# À chaque redémarrage:
# 1. PM2 redémarre le backend
# 2. Backend initialise la connexion PostgreSQL
# 3. Backend crée la table si nécessaire
# 4. Backend charge les produits depuis PostgreSQL
# 5. ✅ AUCUNE PERTE DE DONNÉES
```

### Reboot du serveur

```bash
# Le serveur redémarre
sudo reboot

# PM2 redémarre automatiquement
# Backend recharge les produits de PostgreSQL
# ✅ Tout fonctionne !
```

---

## 🆘 Dépannage

### Problème: "Erreur de connexion PostgreSQL"

```bash
# 1. Vérifier que PostgreSQL est en cours d'exécution
sudo systemctl status postgresql

# 2. Vérifier les variables d'environnement
cat .env | grep DB_

# 3. Tester la connexion
psql -h localhost -U postgres -d meknow_production
```

### Problème: "Table does not exist"

```bash
# La table est créée automatiquement, mais vous pouvez aussi la créer manuellement:
npm run db:init
```

### Problème: "Pas de produits après migration"

```bash
# Vérifier le fichier JSON
cat products-data.json

# Vérifier la base de données
psql -h localhost -U postgres -d meknow_production
SELECT jsonb_array_length(products) FROM products_data LIMIT 1;

# Réexécuter la migration
npm run migrate
```

### Problème: "Mémoire pleine / Erreurs de performance"

```bash
# Vérifier la taille de la table
SELECT pg_size_pretty(pg_total_relation_size('products_data'));

# Nettoyer les anciennes versions (garder les 10 dernières)
DELETE FROM products_data 
WHERE version <= (SELECT MAX(version) - 10 FROM products_data);
```

---

## 📈 Monitoring

### Requêtes PostgreSQL utiles

```sql
-- Nombre total de produits
SELECT jsonb_array_length(products) as total_products 
FROM products_data ORDER BY version DESC LIMIT 1;

-- Historique des modifications
SELECT version, last_modified_at, 
       jsonb_array_length(products) as count
FROM products_data 
ORDER BY version DESC 
LIMIT 10;

-- Produits modifiés dans les dernières 24h
SELECT last_modified_at 
FROM products_data 
WHERE last_modified_at > NOW() - INTERVAL '24 hours'
ORDER BY last_modified_at DESC;

-- Taille de la table
SELECT pg_size_pretty(pg_total_relation_size('products_data'));
```

---

## 🔐 Backup & Restore

### Backup complet

```bash
# Backup de la base de données
pg_dump -h localhost -U postgres meknow_production > backup_meknow.sql

# Backup compressé
pg_dump -h localhost -U postgres meknow_production | gzip > backup_meknow.sql.gz
```

### Restore

```bash
# Restore depuis un backup
psql -h localhost -U postgres meknow_production < backup_meknow.sql

# Ou depuis un backup compressé
gunzip -c backup_meknow.sql.gz | psql -h localhost -U postgres meknow_production
```

---

## ✅ Checklist de Production

- [ ] PostgreSQL installé et en cours d'exécution
- [ ] Base de données `meknow_production` créée
- [ ] Variables d'environnement dans `.env` configurées
- [ ] Migration exécutée: `npm run migrate`
- [ ] Produits vérifiés dans PostgreSQL
- [ ] Backend redémarré et teste OK
- [ ] PM2 configuré avec ecosystem.config.js
- [ ] PM2 resurrection activée
- [ ] Backup PostgreSQL configuré
- [ ] Monitoring mis en place

---

## 📞 Support

Pour des questions sur la migration, consultez :
- `backend-minimal.js` - Logique de chargement/sauvegarde
- `migrate-to-postgres.js` - Script de migration
- `.env.example` - Variables d'environnement requises
- `RAPPORT-AVANCEMENT.md` - Historique du projet
