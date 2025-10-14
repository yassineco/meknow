# 🚀 Guide : Continuer le développement en local

Ce document vous guide pour reprendre le développement de **Menow** sur votre machine locale.

---

## 📦 Ce qui a été réalisé

### ✅ Backend MedusaJS v2
- PostgreSQL Neon configuré (56+ tables)
- Seed data : 4 produits premium, collection "Capsule Menow"
- Région France EUR avec TVA 20%
- Payment provider "manual" (COD) activé
- Admin user : `admin@menow.fr`
- Scripts opérationnels : `pnpm seed`, `pnpm user:create`

### ✅ Frontend Next.js 14
- Design premium opérationnel (#0B0B0C noir, #F2C14E or)
- Pages : Homepage, Collection, Produit, Légales (CGV, RGPD, etc.)
- Connexion API MedusaJS v2 Store
- Architecture hybride : Backend pnpm + Frontend npm

### 📁 Structure du projet

```
menow-medusa/
├── medusa-api/          # Backend (pnpm)
│   ├── src/scripts/     # seed-menow.ts, create-publishable-key.ts
│   ├── medusa-config.ts # Config principale
│   └── .env             # Variables environnement
│
├── menow-web/           # Frontend (npm)
│   ├── src/app/         # Pages Next.js
│   ├── src/components/  # Composants React
│   └── .env.local       # Variables environnement
│
├── README.md                  # Documentation principale
├── RAPPORT-AVANCEMENT.md      # État détaillé du projet
└── CONTINUER-EN-LOCAL.md      # Ce fichier
```

---

## ⚠️ Problème en cours

### Backend MedusaJS v2 ne démarre pas

**Symptôme** : Le backend ne démarre pas sur le port 9000

**Erreur** :
```
error: Error in loading config: Cannot read properties of undefined (reading 'service')
```

**Fichier concerné** : `medusa-api/medusa-config.ts`

**Cause** : Configuration des modules MedusaJS v2 incomplète/incorrecte

**Solution recommandée** :
1. Consulter la documentation officielle MedusaJS v2.10.3
2. Générer une configuration de référence : `npx create-medusa-app@latest test-project`
3. Comparer et adapter `medusa-config.ts`

---

## 🔧 Installation locale

### Prérequis

```bash
Node.js >= 18.0.0
pnpm >= 8.0.0
npm >= 8.0.0
PostgreSQL 14+ (ou compte Neon/Supabase)
```

### 1. Cloner le projet

```bash
git clone <votre-repo>
cd menow-medusa
```

### 2. Installer les dépendances

```bash
# Backend (pnpm)
cd medusa-api
pnpm install

# Frontend (npm)
cd ../menow-web
npm install
```

> **Note** : Le frontend utilise npm pour éviter un conflit pnpm/postcss avec Next.js

### 3. Configurer l'environnement

**Backend** (`medusa-api/.env`) :

```env
DATABASE_URL=postgresql://USER:PASSWORD@HOST:PORT/menow
JWT_SECRET=supersecret
COOKIE_SECRET=supersecret
STORE_CORS=http://localhost:5000,https://*.replit.dev
ADMIN_CORS=http://localhost:7001,https://*.replit.dev
AUTH_CORS=http://localhost:7001,https://*.replit.dev
```

**Frontend** (`menow-web/.env.local`) :

```env
NEXT_PUBLIC_MEDUSA_URL=http://localhost:9000
NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY=pk_abef8165515ca287d8a6ec20410f6e8dbc38e9cc781e8ab6edd60332f47fad56
```

### 4. Initialiser la base de données

```bash
cd medusa-api

# Synchroniser les tables
pnpm db:sync-links

# Créer un admin
pnpm user:create
# Email: admin@menow.fr
# Password: <votre-choix>

# Seed les données
pnpm seed

# Générer une publishable key (optionnel si vous gardez celle existante)
pnpm publishable-key:create
```

### 5. Démarrer le projet

**Terminal 1 - Backend** :
```bash
cd medusa-api
pnpm dev
# Devrait démarrer sur http://localhost:9000
```

**Terminal 2 - Frontend** :
```bash
cd menow-web
npm run dev
# Démarre sur http://localhost:5000
```

---

## 🐛 Résolution du problème backend

### Option 1 : Référence configuration MedusaJS v2

```bash
# Générer un projet de référence
npx create-medusa-app@latest medusa-reference
cd medusa-reference

# Comparer medusa-config.ts
cat medusa-config.ts
```

Copier la configuration des `modules` vers `medusa-api/medusa-config.ts`

### Option 2 : Configuration minimale

Si la configuration complète ne fonctionne pas, essayer une config minimale :

```typescript
// medusa-api/medusa-config.ts
import { loadEnv, defineConfig } from '@medusajs/framework/utils'

loadEnv(process.env.NODE_ENV || 'development', process.cwd())

module.exports = defineConfig({
  projectConfig: {
    databaseUrl: process.env.DATABASE_URL,
    http: {
      storeCors: process.env.STORE_CORS!,
      adminCors: process.env.ADMIN_CORS!,
      authCors: process.env.AUTH_CORS!,
      jwtSecret: process.env.JWT_SECRET || "supersecret",
      cookieSecret: process.env.COOKIE_SECRET || "supersecret",
    }
  }
})
```

### Option 3 : Logs de debug

```bash
cd medusa-api
pnpm dev 2>&1 | tee debug.log
cat debug.log
```

---

## 📋 Checklist de vérification

### Backend opérationnel

- [ ] `pnpm dev` démarre sans erreur
- [ ] Port 9000 ouvert
- [ ] API accessible : `curl http://localhost:9000/health`
- [ ] Store API : `curl http://localhost:9000/store/products`
- [ ] Admin accessible : http://localhost:9000/app

### Frontend opérationnel

- [ ] `npm run dev` démarre sans erreur
- [ ] Port 5000 ouvert
- [ ] Homepage affiche le hero + produits
- [ ] Navigation fonctionne
- [ ] Design premium appliqué (#0B0B0C, #F2C14E)

### Intégration Backend ↔ Frontend

- [ ] Frontend appelle l'API backend
- [ ] Produits affichés depuis la base de données
- [ ] Images chargent (ou 404 si Unsplash cassé)
- [ ] Collection "Capsule Menow" accessible

---

## 🎯 Prochaines étapes de développement

### Priorité 1 : Corriger le backend
1. ✅ Résoudre le problème de configuration modules
2. ✅ Démarrer backend sur port 9000
3. ✅ Vérifier API Store accessible

### Priorité 2 : Fonctionnalités e-commerce
1. [ ] Implémenter panier (state React Context/Zustand)
2. [ ] Page panier `/panier`
3. [ ] Formulaire checkout COD
4. [ ] Page confirmation commande

### Priorité 3 : Optimisations
1. [ ] Remplacer images Unsplash par assets locaux
2. [ ] Optimiser images Next.js (prop `sizes`)
3. [ ] SEO metadata
4. [ ] Tests e2e

### Priorité 4 : Déploiement
1. [ ] Backend : Replit VM ou Railway
2. [ ] Frontend : Replit Autoscale ou Vercel
3. [ ] Database : Neon EU (déjà configuré)
4. [ ] Domaine personnalisé

---

## 📚 Documentation utile

### Fichiers du projet
- **README.md** : Documentation principale complète
- **RAPPORT-AVANCEMENT.md** : État détaillé avec métriques
- **QUICK-START.md** : Guide démarrage rapide
- **medusa-api/docs/capture-cod.md** : Guide capture paiements COD

### Ressources externes
- **MedusaJS v2 Docs** : https://docs.medusajs.com/v2
- **Next.js 14 Docs** : https://nextjs.org/docs
- **Tailwind CSS** : https://tailwindcss.com/docs

---

## 🔍 Debug courants

### Backend ne démarre pas

```bash
# 1. Nettoyer cache
cd medusa-api
rm -rf .medusa node_modules
pnpm install

# 2. Vérifier config
cat medusa-config.ts

# 3. Vérifier DB
echo $DATABASE_URL
```

### Frontend : Erreurs API

```bash
# 1. Vérifier backend actif
curl http://localhost:9000/health

# 2. Vérifier CORS
curl -H "Origin: http://localhost:5000" \
     http://localhost:9000/store/products

# 3. Vérifier publishable key
cat menow-web/.env.local
```

### Images ne chargent pas

```bash
# Remplacer URLs Unsplash par images locales
# 1. Placer images dans menow-web/public/products/
# 2. Modifier seed data pour pointer vers /products/image.jpg
```

---

## 💡 Conseils

1. **Travailler par priorité** : Backend d'abord, puis frontend
2. **Tester régulièrement** : Après chaque modification importante
3. **Commiter souvent** : Petits commits atomiques
4. **Consulter les logs** : `pnpm dev 2>&1 | tee debug.log`
5. **Documenter les changements** : Mettre à jour RAPPORT-AVANCEMENT.md

---

## 📞 Support

Si vous êtes bloqué :

1. Consulter **RAPPORT-AVANCEMENT.md** (section "Problèmes en cours")
2. Lire **README.md** (section "Tests & Validation")
3. Consulter docs officielles MedusaJS v2 / Next.js 14
4. Vérifier les issues GitHub de MedusaJS

---

**Bon courage pour la suite du développement ! 🚀**

_Dernière mise à jour : 14 Octobre 2025_
