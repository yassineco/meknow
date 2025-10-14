# Menow - Monorepo E-Commerce MedusaJS

> Prêt-à-porter premium fabriqué au Maroc - Stack moderne avec MedusaJS API + Next.js 14

## 📋 Vue d'ensemble

Ce monorepo remplace la stack Shopify par une solution open-source basée sur **MedusaJS** (backend e-commerce) et **Next.js 14** (frontend), tout en conservant l'identité visuelle complète du thème Menow.

### Caractéristiques principales

- ✨ **Design premium noir & or** identique à la version Shopify
- 💰 **Paiement comptant à la livraison (COD)** actif par défaut
- 🇫🇷 **France uniquement** - Configuration EUR, TVA 20%
- 🇪🇺 **RGPD compliant** - Hébergement EU, pages légales FR
- 🎨 **Animations & effets** - Formes dorées, badges pulsants, zoom images
- 📱 **Mobile-first** - Responsive complet
- ♿ **Accessibilité** - Focus visibles, alt images

---

## 🏗️ Architecture

### Structure Monorepo Hybride

**Architecture adoptée** : Backend pnpm + Frontend npm (solution au conflit postcss/Next.js)

```
menow-medusa/
├── medusa-api/          # Backend MedusaJS v2.10.3 (pnpm)
│   ├── src/
│   │   ├── config/      # Configuration (plugins, project)
│   │   ├── loaders/     # Loaders DB, env
│   │   ├── scripts/     # seed-menow.ts, create-publishable-key.ts
│   │   └── api/         # Routes custom
│   ├── docs/            # capture-cod.md
│   └── medusa-config.ts # Config principale
│
├── menow-web/           # Frontend Next.js 14 (npm)
│   ├── src/
│   │   ├── app/         # Pages App Router
│   │   │   ├── page.tsx                    # Homepage
│   │   │   ├── collection/[handle]/        # Collection dynamique
│   │   │   ├── produit/[handle]/           # Produit dynamique  
│   │   │   └── legal/                      # CGV, Mentions, RGPD, Retours
│   │   ├── components/  # Header, Footer, Hero, ProductCard...
│   │   ├── lib/         # medusa.ts (client SDK v2)
│   │   └── styles/      # globals.css, theme.css
│   ├── public/logo.png
│   └── package.json     # npm (converti depuis pnpm)
│
├── pnpm-workspace.yaml  # Backend uniquement
├── RAPPORT-AVANCEMENT.md # 📊 État actuel du projet
└── README.md            # Ce fichier
```

### Stack Technique

**Backend (MedusaJS v2)**
- Framework: MedusaJS 2.10.3
- Database: PostgreSQL (Neon EU)
- Sync: `db:sync-links` (remplace TypeORM migrations)
- Payment: Manual provider (COD)
- Port: 9000 (API), 7001 (Admin)

**Frontend (Next.js 14)**
- Framework: Next.js 14.2.33 (App Router)
- Styling: Tailwind CSS + CSS custom properties
- Package manager: npm (converti depuis pnpm)
- Port: 5000 (Replit webview)

---

## 🎨 Design System

### Palette de couleurs
```css
--bg-primary: #0B0B0C       /* Noir profond */
--bg-secondary: #121214     /* Noir secondaire */
--bg-tertiary: #1E1E22      /* Noir tertiaire */
--text-primary: #F3F3F3     /* Blanc cassé */
--text-secondary: #B5B5B5   /* Gris */
--accent: #F2C14E           /* Or */
--accent-dark: #D4A73B      /* Or foncé */
--border: #1E1E22           /* Bordure */
```

### Typographie
- **Headings** : Playfair Display (700, 900)
- **Body** : Inter (300-700)

### Effets visuels
- Grain animé sur toute la page
- Formes dorées flottantes dans le hero
- Badge "Made in Morocco" pulsant
- Zoom 1.1x sur images au survol
- Overlay sombre progressif sur cards
- Transitions fluides (0.3-0.6s)

---

## 🚀 Installation & Démarrage

### Prérequis

```bash
Node.js >= 18.0.0
pnpm >= 8.0.0  # Backend
npm >= 8.0.0   # Frontend
PostgreSQL 14+ (Neon EU recommandé)
```

### 1. Cloner le projet

```bash
git clone <votre-repo>
cd menow-medusa
```

### 2. Installation Backend (pnpm)

```bash
cd medusa-api
pnpm install
```

### 3. Installation Frontend (npm)

```bash
cd ../menow-web
npm install
```

> ⚠️ **Note importante** : Le frontend utilise npm (converti depuis pnpm) pour résoudre un conflit de dépendances postcss/Next.js

### 4. Configuration environnement

**Backend** (`medusa-api/.env`) :
```bash
cd medusa-api
cp .env.example .env
```

Configurer :
```env
DATABASE_URL=postgresql://USER:PASSWORD@HOST:PORT/menow
JWT_SECRET=supersecret
COOKIE_SECRET=supersecret
STORE_CORS=http://localhost:5000,https://*.replit.dev
ADMIN_CORS=http://localhost:7001,https://*.replit.dev
AUTH_CORS=http://localhost:7001,https://*.replit.dev
```

**Frontend** (`menow-web/.env.local`) :
```bash
cd menow-web
cp .env.local.example .env.local
```

Configurer :
```env
NEXT_PUBLIC_MEDUSA_URL=http://localhost:9000
NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY=<sera généré à l'étape 6>
```

### 5. Initialiser la base de données

```bash
cd medusa-api

# Synchroniser les tables (MedusaJS v2)
pnpm db:sync-links

# Vérifier : 56+ tables créées
```

### 6. Seed des données

```bash
cd medusa-api

# 1. Créer admin
pnpm user:create
# Email: admin@menow.fr
# Password: <votre-choix>

# 2. Seed personnalisé (région France, 4 produits, collection Capsule)
pnpm seed

# 3. Générer publishable key (copier le résultat)
pnpm publishable-key:create
```

> 📝 Copier la clé générée dans `menow-web/.env.local` → `NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY`

### 7. Démarrer le projet

**Option A : Workflows Replit (automatique)**
```bash
# Les workflows démarrent automatiquement sur Replit
# Backend: port 9000
# Frontend: port 5000
```

**Option B : Local (2 terminaux)**
```bash
# Terminal 1 - Backend
cd medusa-api
pnpm dev

# Terminal 2 - Frontend  
cd menow-web
npm run dev
```

### 8. Accès

- **Frontend** : http://localhost:5000
- **API Store** : http://localhost:9000/store/*
- **Admin** : http://localhost:9000/app (admin@menow.fr / <votre-password>)

---

## 💰 Paiement Comptant (COD)

### Comment ça marche

Le **paiement comptant à la livraison** est géré via le **manual payment provider** de MedusaJS.

#### Côté client (menow-web)
- Badge "💰 Paiement comptant disponible" sur tous les produits
- Note explicite sur la PDP
- Message de réassurance sur la homepage

#### Côté backend (medusa-api)
1. Le client passe commande sans paiement en ligne
2. `payment_provider_id = "manual"`
3. `payment_status = "requires_action"` (en attente encaissement)
4. Après livraison + encaissement physique → **Admin Medusa** :
   - Aller dans l'ordre
   - Cliquer "Capture Payment"
   - `payment_status = "captured"`

#### Flux complet
```
Commande créée → payment_status: requires_action
     ↓
Livraison + paiement physique (espèces/CB au transporteur)
     ↓
Admin capture payment → payment_status: captured
     ↓
Commande finalisée
```

📖 **Documentation complète** : Voir [`medusa-api/docs/capture-cod.md`](medusa-api/docs/capture-cod.md) pour le guide détaillé de capture des paiements COD

---

## 💳 Paiement en ligne (Stripe - Optionnel)

Le paiement Stripe est **désactivé par défaut** mais prêt à activer.

### Activation

#### 1. Backend (`medusa-api/.env`)
```env
STRIPE_API_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
```

#### 2. Décommenter dans `medusa-api/medusa-config.js`
```js
plugins: [
  // ... autres plugins
  {
    resolve: `medusa-payment-stripe`,
    options: {
      api_key: process.env.STRIPE_API_KEY,
      webhook_secret: process.env.STRIPE_WEBHOOK_SECRET,
    },
  },
],
```

#### 3. Ajouter Stripe à la région France
Via Admin Medusa :
- Settings → Regions → France
- Ajouter "Stripe" aux payment providers

#### 4. Frontend
Intégrer Stripe Elements dans le checkout (non inclus par défaut).

---

## 📦 Structure des Produits

### Seed initial (4 produits)

1. **Veste en Cuir Premium Noir** - 299€
2. **Blouson Aviateur Cognac** - 279€
3. **Perfecto Classique Noir** - 329€
4. **Veste Saharienne Beige** - 199€

Tous dans la collection **"Capsule"**.

### Format produit
```json
{
  "title": "Veste en Cuir Premium Noir",
  "handle": "veste-cuir-premium-noir",
  "prices": [{ "currency_code": "eur", "amount": 29900 }],
  "options": [{ "title": "Taille", "values": ["S", "M", "L", "XL"] }],
  "tags": ["made-in-morocco", "cuir", "premium"],
  "images": ["https://images.unsplash.com/..."]
}
```

---

## 🌍 Déploiement

### Option 1 : Replit Deployments

#### Backend (medusa-api)
```bash
# Configurer Replit Deployment type: VM
# Ajouter PostgreSQL via Neon (EU)
# Secrets: DATABASE_URL, JWT_SECRET, COOKIE_SECRET
# Run command: pnpm --filter medusa-api start
```

#### Frontend (menow-web)
```bash
# Configurer Replit Deployment type: Autoscale
# Secrets: NEXT_PUBLIC_MEDUSA_URL (URL de l'API déployée)
# Build: pnpm --filter menow-web build
# Run: pnpm --filter menow-web start
```

### Option 2 : Railway / Render / Fly.io

- **API** : Deploy comme app Node.js (port 9000)
- **Web** : Deploy comme app Next.js (port 3000)
- **DB** : PostgreSQL managé (Neon EU recommandé pour RGPD)

---

## 🛡️ RGPD & Légal

### Pages légales incluses
- ✅ `/legal/cgv` - Conditions Générales de Vente
- ✅ `/legal/mentions-legales` - Mentions Légales
- ✅ `/legal/confidentialite` - Politique de Confidentialité (RGPD)
- ✅ `/legal/retours` - Politique de Retours (30 jours)

### Hébergement EU
- Database PostgreSQL : **Neon EU** (Frankfurt) ou Supabase EU
- Frontend/API : Hébergement EU (Railway EU, Render Frankfurt)
- **Aucune donnée hors UE**

### Conservation des données
- Commandes : 3 ans après dernière commande
- Clients : 3 ans après dernière activité
- Logs : 12 mois max

---

## 🧪 Tests & Validation

### Checklist de déploiement

- [ ] API démarre sans erreur (`pnpm --filter medusa-api dev`)
- [ ] Endpoints `/store/products`, `/store/collections`, `/store/carts` répondent
- [ ] Manual payment provider actif (vérifier Admin → Settings → Payment)
- [ ] Frontend démarre (`pnpm --filter menow-web dev`)
- [ ] Homepage affiche : Hero + Reassurance + 4 produits + Lookbook
- [ ] PDP affiche badge COD + prix + bouton ATC
- [ ] Pages légales accessibles
- [ ] Logo Menow (150px) affiché dans header
- [ ] Palette couleurs respectée (#0B0B0C, #F2C14E, etc.)
- [ ] Animations : grain, formes dorées, badge pulse, zoom images

### Commandes de test

```bash
# Build complet
pnpm build

# Seed des données de test
pnpm seed

# Créer un utilisateur admin
pnpm user:create

# Clean (reset)
pnpm clean
```

### Vérifications après installation

- [ ] `GET http://localhost:9000/store/products` retourne 4 produits
- [ ] Admin Medusa accessible à http://localhost:7001
- [ ] Region "France" existe avec provider "manual"
- [ ] Collection "Capsule Menow" visible
- [ ] Frontend affiche Hero + 4 produits + Lookbook
- [ ] Badge COD visible sur les produits

---

## 📚 Documentation technique

### API Endpoints (MedusaJS Storefront)

| Endpoint | Méthode | Description |
|----------|---------|-------------|
| `/store/products` | GET | Liste produits |
| `/store/products/:id` | GET | Détail produit |
| `/store/collections` | GET | Liste collections |
| `/store/carts` | POST | Créer panier |
| `/store/carts/:id` | GET | Récupérer panier |
| `/store/carts/:id/line-items` | POST | Ajouter produit |
| `/store/orders` | POST | Créer commande |

### Components principaux (Next.js)

| Component | Description |
|-----------|-------------|
| `Header` | Navigation fixe + logo + panier |
| `Hero` | Section d'accueil + formes dorées animées |
| `ReassuranceBar` | 4 badges (Maroc, Livraison, Retours, COD) |
| `FeaturedCollection` | Grille 4 produits vedettes |
| `Lookbook` | Grille 3 images avec overlay |
| `ProductCard` | Card produit avec zoom hover |
| `Footer` | Liens légaux + contact |

---

## 🤝 Support & Contact

- **Email** : contact@menow.fr
- **Documentation MedusaJS** : https://docs.medusajs.com
- **Documentation Next.js** : https://nextjs.org/docs

---

## 📝 Licence

Propriétaire - Menow © 2025

---

## 📊 État Actuel & Prochaines Étapes

### ✅ Fonctionnel

- Frontend Next.js opérationnel sur port 5000
- Design premium (#0B0B0C, #F2C14E) avec animations
- Pages : Homepage, Collection, Produit, Légales
- Seed data : 4 produits, collection Capsule, région France
- Architecture hybride pnpm/npm fonctionnelle

### ⚠️ En cours

**Backend MedusaJS v2** : Problème de configuration modules

**Symptôme** : Le backend ne démarre pas sur le port 9000  
**Erreur** : Configuration `medusa-config.ts` incomplète  
**Impact** : API Store inaccessible, admin non disponible  

**Solution recommandée** :
1. Consulter documentation officielle MedusaJS v2.10.3
2. Comparer avec configuration de référence (`npx create-medusa-app`)
3. Configurer correctement tous les modules requis

### 🎯 Prochaines Étapes

#### Priorité 1 (Bloquant)
- [ ] Corriger configuration backend MedusaJS v2
- [ ] Démarrer backend sur port 9000
- [ ] Vérifier API Store accessible

#### Priorité 2 (Important)
- [ ] Remplacer images Unsplash (404) par images locales
- [ ] Implémenter panier (state management)
- [ ] Implémenter checkout COD

#### Priorité 3 (Améliorations)
- [ ] Tests e2e du flow complet
- [ ] Optimisations images Next.js
- [ ] SEO & metadata

### 📖 Documentation Complémentaire

- **RAPPORT-AVANCEMENT.md** : État détaillé du projet avec métriques
- **QUICK-START.md** : Guide de démarrage rapide 5 minutes
- **medusa-api/docs/capture-cod.md** : Guide capture paiements COD

---

## ✅ Différences avec Shopify

| Fonctionnalité | Shopify | MedusaJS |
|----------------|---------|----------|
| **Coût** | $29-299/mois | Gratuit (API open-source) |
| **Contrôle code** | Limité (Liquid) | Total (Node.js + React) |
| **Hébergement DB** | US/Canada | EU (RGPD) |
| **Paiement COD** | Plugins tiers | Natif (manual provider) |
| **Customisation** | Thèmes Liquid | Code 100% custom |
| **Admin** | Shopify Admin | Medusa Admin (open-source) |

---

**Bon développement ! 🚀**
