# 🚀 Quick Start - Menow

Guide de démarrage rapide pour lancer Menow en 5 minutes.

---

## ⚡ Installation Express

### 1️⃣ Installer les dépendances

```bash
pnpm install
```

### 2️⃣ Configurer les environnements

```bash
# Backend
cp medusa-api/.env.example medusa-api/.env

# Frontend
cp menow-web/.env.local.example menow-web/.env.local
```

**Modifier `medusa-api/.env`** avec votre URL PostgreSQL :
```env
DATABASE_URL=postgresql://user:password@localhost:5432/menow_dev
```

### 3️⃣ Initialiser la base de données

```bash
# Migrations
pnpm --filter medusa-api migrate

# Créer admin
pnpm user:create
```

Credentials admin :
- Email: `admin@menow.fr`
- Password: `supersecret`

### 4️⃣ Seed des données

```bash
# Seed personnalisé (région France + 4 produits + collection Capsule)
pnpm seed
```

### 5️⃣ Démarrer

```bash
# API + Frontend simultanément
pnpm dev
```

---

## 🌐 URLs

- **API Backend** : http://localhost:9000
- **Frontend** : http://localhost:3000
- **Admin Panel** : http://localhost:7001

---

## ✅ Vérification

Testez ces endpoints :

```bash
# Liste des produits
curl http://localhost:9000/store/products

# Collection Capsule
curl http://localhost:9000/store/collections

# Regions (France avec COD)
curl http://localhost:9000/store/regions
```

Visitez http://localhost:3000 → Vous devriez voir :
- ✅ Hero avec animations dorées
- ✅ 4 produits de la collection Capsule
- ✅ Lookbook grid
- ✅ Badge "Paiement comptant disponible"

---

## 🆘 Problèmes fréquents

### Erreur : "Cannot connect to database"

Vérifiez que :
1. PostgreSQL est démarré
2. `DATABASE_URL` dans `.env` est correct
3. La base de données `menow_dev` existe

```bash
# Créer la DB si nécessaire
createdb menow_dev
```

### Erreur : "Admin authentication failed"

1. Créez d'abord l'admin : `pnpm user:create`
2. Vérifiez que l'API est démarrée avant de lancer le seed

### Le frontend ne charge pas les produits

1. Vérifiez que l'API tourne sur le port 9000
2. Vérifiez `NEXT_PUBLIC_MEDUSA_URL` dans `menow-web/.env.local`

---

## 📚 Documentation complète

Consultez le [README.md](README.md) pour :
- Architecture détaillée
- Configuration COD/Stripe
- Guide de déploiement Replit
- Documentation RGPD

---

**Bon développement ! 🎉**
