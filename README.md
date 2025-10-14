# 🛍️ Meknow - E-commerce Premium# Menow - Monorepo E-Commerce MedusaJS



**Meknow** est une plateforme e-commerce premium française développée avec MedusaJS et Next.js, spécialisée dans la mode artisanale haut de gamme.> Prêt-à-porter premium fabriqué au Maroc - Stack moderne avec MedusaJS API + Next.js 14



## 🚀 Architecture## 📋 Vue d'ensemble



### **Stack Technique**Ce monorepo remplace la stack Shopify par une solution open-source basée sur **MedusaJS** (backend e-commerce) et **Next.js 14** (frontend), tout en conservant l'identité visuelle complète du thème Menow.

- **Frontend:** Next.js 14 (App Router) + Tailwind CSS

- **Backend:** MedusaJS v2.10.3 + API Express.js### Caractéristiques principales

- **Base de données:** PostgreSQL (Neon Cloud)

- **Paiement:** Cash on Delivery (COD)- ✨ **Design premium noir & or** identique à la version Shopify

- **Hosting:** Ready for deployment- 💰 **Paiement comptant à la livraison (COD)** actif par défaut

- 🇫🇷 **France uniquement** - Configuration EUR, TVA 20%

### **Design**- 🇪🇺 **RGPD compliant** - Hébergement EU, pages légales FR

- **Identité:** Premium noir (#0B0B0C) et or (#F2C14E)- 🎨 **Animations & effets** - Formes dorées, badges pulsants, zoom images

- **Logo:** Nouveau logo "me know" doré sur fond noir- 📱 **Mobile-first** - Responsive complet

- **UX:** Interface moderne et épurée, responsive- ♿ **Accessibilité** - Focus visibles, alt images



## 📦 Structure du Projet---



```## 🏗️ Architecture

menow/

├── menow-web/                 # Frontend Next.js### Structure Monorepo Hybride

│   ├── src/app/              # Pages App Router

│   ├── src/components/       # Composants React**Architecture adoptée** : Backend pnpm + Frontend npm (solution au conflit postcss/Next.js)

│   ├── public/              # Assets statiques

│   └── package.json```

├── medusa-api/              # Backend MedusaJS (v2)menow-medusa/

│   ├── src/                 # Code source├── medusa-api/          # Backend MedusaJS v2.10.3 (pnpm)

│   ├── medusa-config.ts     # Configuration│   ├── src/

│   └── package.json│   │   ├── config/      # Configuration (plugins, project)

├── backend-minimal.js       # Backend Express.js (dev)│   │   ├── loaders/     # Loaders DB, env

├── admin-complete.html      # Interface admin complète│   │   ├── scripts/     # seed-menow.ts, create-publishable-key.ts

└── README.md│   │   └── api/         # Routes custom

```│   ├── docs/            # capture-cod.md

│   └── medusa-config.ts # Config principale

## 🛍️ Produits & Catalogue│

├── menow-web/           # Frontend Next.js 14 (npm)

### **Collection Capsule Meknow**│   ├── src/

1. **Blouson Cuir Premium** - 259,00€│   │   ├── app/         # Pages App Router

   - Cuir véritable, confection artisanale française│   │   │   ├── page.tsx                    # Homepage

   - Tailles: S, M, L, XL│   │   │   ├── collection/[handle]/        # Collection dynamique

   - Stock: 63 unités│   │   │   ├── produit/[handle]/           # Produit dynamique  

│   │   │   └── legal/                      # CGV, Mentions, RGPD, Retours

2. **Jean Denim Selvage** - 189,00€ │   │   ├── components/  # Header, Footer, Hero, ProductCard...

   - Denim selvage authentique, coupe moderne│   │   ├── lib/         # medusa.ts (client SDK v2)

   - Tailles: S, M, L, XL│   │   └── styles/      # globals.css, theme.css

   - Stock: 87 unités│   ├── public/logo.png

│   └── package.json     # npm (converti depuis pnpm)

3. **Chemise Lin Naturel** - 149,00€│

   - Lin 100% naturel, légère et respirante├── pnpm-workspace.yaml  # Backend uniquement

   - Tailles: S, M, L, XL├── RAPPORT-AVANCEMENT.md # 📊 État actuel du projet

   - Stock: 118 unités└── README.md            # Ce fichier

```

4. **T-Shirt Coton Bio** - 99,00€

   - Coton biologique certifié### Stack Technique

   - Tailles: S, M, L, XL

   - Stock: 185 unités**Backend (MedusaJS v2)**

- Framework: MedusaJS 2.10.3

## 🔧 Installation & Lancement- Database: PostgreSQL (Neon EU)

- Sync: `db:sync-links` (remplace TypeORM migrations)

### **Prérequis**- Payment: Manual provider (COD)

- Node.js 18+- Port: 9000 (API), 7001 (Admin)

- npm ou pnpm

- PostgreSQL (ou accès Neon)**Frontend (Next.js 14)**

- Framework: Next.js 14.2.33 (App Router)

### **Installation**- Styling: Tailwind CSS + CSS custom properties

```bash- Package manager: npm (converti depuis pnpm)

# Cloner le projet- Port: 5000 (Replit webview)

git clone <repository-url>

cd menow---



# Installer les dépendances## 🎨 Design System

npm install

### Palette de couleurs

# Frontend```css

cd menow-web--bg-primary: #0B0B0C       /* Noir profond */

npm install--bg-secondary: #121214     /* Noir secondaire */

```--bg-tertiary: #1E1E22      /* Noir tertiaire */

--text-primary: #F3F3F3     /* Blanc cassé */

### **Lancement Développement**--text-secondary: #B5B5B5   /* Gris */

--accent: #F2C14E           /* Or */

#### **Option 1: Services séparés (Recommandé)**--accent-dark: #D4A73B      /* Or foncé */

```bash--border: #1E1E22           /* Bordure */

# Terminal 1: Backend Express.js```

cd menow

node backend-minimal.js### Typographie

# → Backend sur http://localhost:9000- **Headings** : Playfair Display (700, 900)

- **Body** : Inter (300-700)

# Terminal 2: Frontend Next.js

cd menow-web### Effets visuels

npm run dev- Grain animé sur toute la page

# → Frontend sur http://localhost:5000- Formes dorées flottantes dans le hero

- Badge "Made in Morocco" pulsant

# Terminal 3: Interface Admin- Zoom 1.1x sur images au survol

python3 -m http.server 8082- Overlay sombre progressif sur cards

# → Admin sur http://localhost:8082/admin-complete.html- Transitions fluides (0.3-0.6s)

```

---

#### **Option 2: MedusaJS complet**

```bash## 🚀 Installation & Démarrage

# Backend MedusaJS

cd medusa-api### Prérequis

npm run dev

# → Backend sur http://localhost:9000```bash

Node.js >= 18.0.0

# Frontendpnpm >= 8.0.0  # Backend

cd menow-webnpm >= 8.0.0   # Frontend

npm run devPostgreSQL 14+ (Neon EU recommandé)

# → Frontend sur http://localhost:5000```

```

### 1. Cloner le projet

## 🌐 URLs d'Accès

```bash

| Service | URL | Description |git clone <votre-repo>

|---------|-----|-------------|cd menow-medusa

| **Frontend** | http://localhost:5000 | Site e-commerce Meknow |```

| **Backend API** | http://localhost:9000 | API REST + Store API |

| **Admin MedusaJS** | http://localhost:9000/app | Interface admin native |### 2. Installation Backend (pnpm)

| **Admin Complet** | http://localhost:8082/admin-complete.html | Interface admin avancée |

| **API Santé** | http://localhost:9000/health | Monitoring backend |```bash

cd medusa-api

## ⚙️ Interface Administrationpnpm install

```

### **Identifiants Admin**

- **Email:** `admin@medusa.com`### 3. Installation Frontend (npm)

- **Password:** `admin123`

```bash

### **Fonctionnalités Admin**cd ../menow-web

- 📊 **Tableau de bord** avec statistiques temps réelnpm install

- 📦 **Gestion produits** (CRUD complet)```

- 📋 **Gestion stock** et inventaire

- 🎯 **Alertes stock faible**> ⚠️ **Note importante** : Le frontend utilise npm (converti depuis pnpm) pour résoudre un conflit de dépendances postcss/Next.js

- ⚙️ **Configuration** et monitoring

### 4. Configuration environnement

### **API Endpoints**

```bash**Backend** (`medusa-api/.env`) :

# Produits (Store)```bash

GET /store/products           # Liste des produitscd medusa-api

GET /store/products/:id       # Détail produitcp .env.example .env

GET /store/collections        # Collections```



# AdminConfigurer :

GET /admin/products           # Gestion produits```env

POST /admin/products          # Créer produitDATABASE_URL=postgresql://USER:PASSWORD@HOST:PORT/menow

POST /admin/products/:id      # Modifier produitJWT_SECRET=supersecret

DELETE /admin/products/:id    # Supprimer produitCOOKIE_SECRET=supersecret

GET /admin/inventory          # Rapport stockSTORE_CORS=http://localhost:5000,https://*.replit.dev

POST /admin/inventory/:id     # Modifier stockADMIN_CORS=http://localhost:7001,https://*.replit.dev

```AUTH_CORS=http://localhost:7001,https://*.replit.dev

```

## 💳 Paiement & Livraison

**Frontend** (`menow-web/.env.local`) :

- **Méthode:** Cash on Delivery (COD)```bash

- **Zone:** France métropolitainecd menow-web

- **Devise:** EURcp .env.local.example .env.local

- **Frais:** Inclus dans le prix```



## 🔒 Variables d'EnvironnementConfigurer :

```env

### **Backend (.env)**NEXT_PUBLIC_MEDUSA_URL=http://localhost:9000

```envNEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY=<sera généré à l'étape 6>

DATABASE_URL=postgresql://...```

JWT_SECRET=<secret-sécurisé>

COOKIE_SECRET=<secret-sécurisé>### 5. Initialiser la base de données

STORE_CORS=http://localhost:5000

ADMIN_CORS=http://localhost:9000```bash

```cd medusa-api



### **Frontend (.env.local)**# Synchroniser les tables (MedusaJS v2)

```envpnpm db:sync-links

NEXT_PUBLIC_MEDUSA_BACKEND_URL=http://localhost:9000

NEXT_PUBLIC_BASE_URL=http://localhost:5000# Vérifier : 56+ tables créées

SITE_NAME=Meknow```

```

### 6. Seed des données

## 📈 État du Projet

```bash

### ✅ **Fonctionnalités Complètes**cd medusa-api

- [x] **Frontend e-commerce** entièrement fonctionnel

- [x] **Backend API** robuste avec MedusaJS# 1. Créer admin

- [x] **Interface admin** professionnellepnpm user:create

- [x] **Gestion produits** complète (CRUD)# Email: admin@menow.fr

- [x] **Gestion stock** avec alertes# Password: <votre-choix>

- [x] **Images optimisées** (URLs locales)

- [x] **Nouveau logo** intégré# 2. Seed personnalisé (région France, 4 produits, collection Capsule)

- [x] **Rebranding** Menow → Meknowpnpm seed

- [x] **Sécurité** (secrets renouvelés)

# 3. Générer publishable key (copier le résultat)

### 🚀 **Prêt pour Production**pnpm publishable-key:create

- [x] **Code stable** et testé```

- [x] **API documentée**

- [x] **Interface utilisateur** premium> 📝 Copier la clé générée dans `menow-web/.env.local` → `NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY`

- [x] **Gestion administrative** complète

- [x] **Monitoring** et santé des services### 7. Démarrer le projet



## 🛠️ Développement**Option A : Workflows Replit (automatique)**

```bash

### **Scripts Disponibles**# Les workflows démarrent automatiquement sur Replit

```bash# Backend: port 9000

# Frontend# Frontend: port 5000

npm run dev          # Développement```

npm run build        # Production

npm run start        # Serveur production**Option B : Local (2 terminaux)**

```bash

# Backend# Terminal 1 - Backend

npm run dev          # Développement MedusaJScd medusa-api

npm run build        # Buildpnpm dev

npm run start        # Production

```# Terminal 2 - Frontend  

cd menow-web

### **Ajout de Produits**npm run dev

Utilisez l'interface admin sur http://localhost:8082/admin-complete.html pour :```

- Créer de nouveaux produits

- Gérer les variants et tailles### 8. Accès

- Modifier les stocks

- Suivre les ventes- **Frontend** : http://localhost:5000

- **API Store** : http://localhost:9000/store/*

## 📞 Support- **Admin** : http://localhost:9000/app (admin@menow.fr / <votre-password>)



### **Identifiants Test**---

- **Admin:** admin@medusa.com / admin123

- **Contact:** contact@meknow.fr## 💰 Paiement Comptant (COD)



### **URLs Importantes**### Comment ça marche

- **Site:** http://localhost:5000

- **Admin:** http://localhost:8082/admin-complete.htmlLe **paiement comptant à la livraison** est géré via le **manual payment provider** de MedusaJS.

- **API:** http://localhost:9000

#### Côté client (menow-web)

---- Badge "💰 Paiement comptant disponible" sur tous les produits

- Note explicite sur la PDP

**Développé avec ❤️ pour Meknow - Excellence Marocaine en mode premium**- Message de réassurance sur la homepage



*Projet créé le 14 octobre 2025*#### Côté backend (medusa-api)
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
