# 🚀 Quick Start - Meknow

Guide de démarrage rapide pour lancer Meknow en 5 minutes.

---

## ⚡ Installation Express

### 1️⃣ Installer les dépendances

```bash
# Dépendances racine
npm install

# Frontend Next.js
cd menow-web
npm install
cd ..
```

### 2️⃣ Configurer les environnements

```bash
# Frontend
cp menow-web/.env.local.example menow-web/.env.local
```

**Modifier `menow-web/.env.local`** :
```env
NEXT_PUBLIC_API_URL=http://localhost:9000
NEXT_PUBLIC_BASE_URL=http://localhost:3000
SITE_NAME=Meknow
```

### 3️⃣ Vérifier la base de données

Assurez-vous que PostgreSQL est démarré et que votre backend `backend-minimal.js` peut s'y connecter.

### 4️⃣ Base de données avec produits

La base contient déjà 5 produits de test prêts à utiliser.

### 5️⃣ Démarrer

```bash
# API + Frontend simultanément
pnpm dev
```

### 5️⃣ Démarrer le projet

```bash
# Option 1: Tout en parallèle
npm run dev

# Option 2: Séparément (2 terminaux)
# Terminal 1
node backend-minimal.js

# Terminal 2  
cd menow-web
npm run dev
```

---

## 🌐 URLs

- **API Backend** : http://localhost:9000
- **Frontend** : http://localhost:3000
- **Admin Panel** : http://localhost:8080/admin-direct.html (serveur statique)

---

## ✅ Vérification

Testez ces endpoints :

```bash
# Liste des produits
curl http://localhost:9000/api/products

# Statistiques dashboard
curl http://localhost:9000/api/dashboard/stats

# Rapport de stock
curl http://localhost:9000/api/inventory
```

Visitez http://localhost:3000 → Vous devriez voir :
- ✅ Hero avec animations dorées
- ✅ 5 produits en grille
- ✅ Lookbook grid
- ✅ Badge "Paiement comptant disponible"

---

## 🆘 Problèmes fréquents

### Erreur : "Cannot connect to database"

Vérifiez que :
1. PostgreSQL est démarré
2. Configuration DB dans `backend-minimal.js` est correcte
3. La base de données existe

```bash
# Créer la DB si nécessaire
createdb meknow_prod
```

### Erreur : Port déjà utilisé

```bash
# Changer le port dans backend-minimal.js
const PORT = process.env.PORT || 9001;
```

### Le frontend ne charge pas les produits

1. Vérifiez que l'API répond : `curl http://localhost:9000/api/products`
2. Vérifiez le `NEXT_PUBLIC_API_URL` dans `menow-web/.env.local`
3. Redémarrez le frontend après changement d'env

---

## 🎯 C'est parti !

Votre plateforme Meknow est maintenant prête ! 

**Admin Interface** : http://localhost:8080/admin-direct.html  
**Site Public** : http://localhost:3000

Bon développement ! 🚀

1. Vérifiez que l'API tourne sur le port 9000
2. Vérifiez le `NEXT_PUBLIC_API_URL` dans `menow-web/.env.local`

---

## 📚 Documentation complète

Consultez le [README.md](README.md) pour :
- Architecture détaillée
- Configuration COD/Stripe
- Guide de déploiement Replit
- Documentation RGPD

---

**Bon développement ! 🎉**
