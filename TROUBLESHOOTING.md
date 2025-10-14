# Troubleshooting - Menow

## ⚠️ Erreur connue : MedusaJS link modules

### Symptôme
```
Error initializing link modules. TypeError: Cannot set properties of undefined
GraphQLError: Syntax Error: Unexpected <EOF>.
warn: Could not resolve module: orderOrderSalesChannelSalesChannelLink
```

### Cause
**Bug connu avec MedusaJS 1.20.11** et les modules link-modules. C'est un problème de compatibilité entre @medusajs/modules-sdk@1.12.12 et @medusajs/link-modules@0.2.12.

Ce n'est PAS un problème de SSL (déjà configuré) ni de données manquantes.

### Solution recommandée

#### Option 1 : Downgrade vers MedusaJS 1.19.x (RECOMMANDÉ)

```bash
cd medusa-api
pnpm add @medusajs/medusa@1.19.0
cd ..
```

#### Option 2 : Upgrade vers MedusaJS 2.x (Version majeure)

MedusaJS 2.0 a complètement refondu le système de modules.

```bash
# Nécessite une migration complète du projet
# Voir : https://docs.medusajs.com/v2/upgrade-guides
```

#### Option 3 : Désactiver les link modules (Temporaire)

Cette solution peut affecter certaines fonctionnalités avancées :

```bash
# 1. Créer l'utilisateur admin
cd medusa-api
npx medusa user -e admin@menow.fr -p supersecret

# 2. Seed les données (depuis la racine)
cd ..
pnpm seed

# 3. Ensuite démarrer
pnpm dev
```

---

## Installation complète (étape par étape)

```bash
# 1. Installer les dépendances
pnpm install

# 2. Environnements déjà configurés ✅
# .env et .env.local sont prêts

# 3. Migrations déjà exécutées ✅  
# Base PostgreSQL initialisée

# 4. Créer admin
cd medusa-api
npx medusa user -e admin@menow.fr -p supersecret
cd ..

# 5. Seed des données
pnpm seed

# 6. Démarrer
pnpm dev
```

---

## Alternative : Seed JSON rapide

Si le seed custom timeout :

```bash
cd medusa-api
npx medusa seed -f ./data/seed.json
cd ..
pnpm dev
```

---

## Vérifier que tout fonctionne

```bash
# API doit répondre :
curl http://localhost:9000/health

# Produits doivent être listés :
curl http://localhost:9000/store/products
```

---

## 📊 État actuel du projet

### ✅ Ce qui fonctionne :
- Structure monorepo complète (MedusaJS + Next.js 14)
- 775+ packages installés (backend) + frontend
- PostgreSQL Neon configuré avec SSL
- Migrations exécutées (75 migrations)
- Fichiers .env générés avec secrets sécurisés
- @medusajs/admin@7.1.18 installé
- Babel dependencies installées
- Configuration SSL correcte

### ❌ Problème actuel :
**MedusaJS 1.20.11 ne démarre pas** à cause d'un bug dans les link modules.

### ⏳ Actions requises :
1. **Downgrade vers MedusaJS 1.19.0** (voir Option 1 ci-dessus)
2. Créer utilisateur admin : `npx medusa user -e admin@menow.fr -p supersecret`
3. Seed des données : `pnpm seed` (ou `npx medusa seed -f ./data/seed.json`)
4. Démarrer : `pnpm dev`

---

## Support

Consultez :
- **QUICK-START.md** pour le guide complet
- **README.md** pour la documentation détaillée
- **medusa-api/docs/capture-cod.md** pour le guide COD
