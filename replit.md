# Menow - Monorepo E-Commerce

## Overview

Menow est une plateforme e-commerce premium pour une marque de prêt-à-porter fabriquée au Maroc avec distribution en France. Le projet utilise un stack moderne MedusaJS (backend) + Next.js 14 (frontend) avec un design sombre et luxueux (#0B0B0C, #F2C14E), optimisé pour le paiement comptant à la livraison (COD).

**Current Status**: Frontend Next.js opérationnel (port 5000). Backend MedusaJS v2 a un problème de configuration modules (voir RAPPORT-AVANCEMENT.md). Architecture hybride pnpm/npm fonctionnelle.

## Recent Changes

**October 5, 2025 - Migration MedusaJS v2 + Résolution Frontend**
- ✅ Migration MedusaJS v1.20 → v2.10.3 (nouvelle API Store)
- ✅ PostgreSQL Neon configuré avec 56+ tables via db:sync-links
- ✅ Seed data créé : 4 produits premium, 16 variantes, collection Capsule, région France EUR
- ✅ Prix corrigés en centimes (18900 = €189) selon feedback architecte
- ✅ Admin user créé : admin@menow.fr
- ✅ Publishable key générée et associée au sales channel
- ✅ Frontend converti de pnpm → npm pour résoudre conflit postcss/Next.js
- ✅ Site opérationnel sur port 5000 avec design premium fonctionnel
- ✅ Backend MedusaJS sur port 9000 avec manual payment provider (COD)

## User Preferences

Preferred communication style: Français, langage simple et quotidien.

## System Architecture

### Monorepo Structure

```
menow-medusa/
├── medusa-api/          # Backend MedusaJS
│   ├── src/
│   │   ├── config/      # Plugins, project config
│   │   ├── loaders/     # DB, env loaders
│   │   ├── scripts/     # seed-menow.ts
│   │   └── api/         # Custom routes
│   ├── docs/            # capture-cod.md
│   └── data/            # seed.json
│
├── menow-web/           # Frontend Next.js 14
│   ├── src/
│   │   ├── app/         # Pages (App Router)
│   │   ├── components/  # UI components
│   │   ├── lib/         # Medusa client, utils
│   │   └── styles/      # globals.css, theme.css
│   └── public/          # logo.png
│
└── pnpm-workspace.yaml
```

### Backend (MedusaJS v2)

**Tech Stack**
- Framework: MedusaJS 2.10.3 (pnpm-managed)
- Database: PostgreSQL Neon (56+ tables)
- Sync: db:sync-links (remplace TypeORM migrations)
- Payment: Manual provider (COD)
- Fulfillment: Manual provider

**Configuration**
- Port: 9000 (API), 7001 (Admin)
- CORS: http://localhost:3000, https://*.replit.dev
- Region: France (EUR, TVA 20%)
- Payment provider: manual (COD activé par défaut)

**Seed Data**
- 1 région France avec provider manual
- 1 collection "Capsule Menow"
- 4 produits premium (cuir, denim, lin, coton bio)
- Variantes de tailles pour chaque produit
- Images depuis Unsplash

### Frontend (Next.js 14)

**Tech Stack**
- Framework: Next.js 14 (App Router) - npm-managed
- Styling: Tailwind CSS + CSS custom properties
- Note: Converti de pnpm → npm pour résoudre conflits de résolution postcss
- Fonts: Playfair Display + Inter (Google Fonts)
- API Client: @medusajs/medusa-js

**Design System**
- **Palette**: #0B0B0C (noir), #F2C14E (or), #F3F3F3 (texte)
- **Effets**: Grain animé, formes dorées flottantes, zoom 1.1x hover
- **Logo**: 150px height
- **Mobile-first**: Responsive complet

**Pages**
- Homepage: Hero + Reassurance + 4 produits + Lookbook
- PDP (Produit): Images, prix, tailles, badge COD, add-to-cart
- PLP (Collection): Grille produits
- Légales: CGV, Mentions, Confidentialité (RGPD), Retours

**Components**
- Header: Navigation fixe + logo + panier
- Hero: Section hero avec animations dorées
- ReassuranceBar: 4 badges (Maroc, Livraison, Retours, COD)
- FeaturedCollection: Grille 4 produits
- Lookbook: Grille 3 images avec overlay
- ProductCard: Card produit avec zoom hover
- Footer: Liens légaux + contact

### Payment Integration

**COD (Paiement comptant)**
- Provider: manual (MedusaJS)
- Flow: Commande → Livraison → Encaissement physique → Capture admin
- Documentation: medusa-api/docs/capture-cod.md

**Stripe (optionnel)**
- Provider: medusa-payment-stripe
- Désactivé par défaut
- Prêt à activer (voir README.md)

### Development Workflow

**Scripts disponibles**
```bash
# Backend (pnpm)
cd medusa-api && pnpm install
pnpm dev              # Backend sur port 9000
pnpm seed             # Seed personnalisé
pnpm user:create      # Créer admin

# Frontend (npm)
cd menow-web && npm install
npm run dev           # Frontend sur port 5000

# Workflows configurés (démarrage auto)
- Medusa Backend v2: cd medusa-api && npm run dev
- Menow Frontend: cd menow-web && npm run dev
```

**Configuration**
- Backend .env: DATABASE_URL, JWT_SECRET, COOKIE_SECRET, CORS
- Frontend .env.local: NEXT_PUBLIC_MEDUSA_URL

### Deployment Strategy

**Option 1: Replit**
- Backend: VM deployment (port 9000)
- Frontend: Autoscale deployment (port 3000)
- Database: PostgreSQL via Neon EU (RGPD)

**Option 2: Autres plateformes**
- Railway, Render, Fly.io compatibles
- Hébergement EU recommandé (RGPD)

### RGPD Compliance

**Pages légales**
- CGV: Conditions générales de vente
- Mentions légales: Informations société
- Confidentialité: Politique RGPD complète
- Retours: 30 jours

**Hébergement**
- Database: EU uniquement (Neon Frankfurt)
- API/Frontend: Hébergement EU
- Conservation: 3 ans max

## External Dependencies

### Backend
- @medusajs/medusa: Framework e-commerce
- @medusajs/medusa-js: Client SDK
- medusa-payment-manual: COD provider
- medusa-payment-stripe: Stripe provider (optionnel)
- pg: PostgreSQL driver
- typeorm: ORM

### Frontend
- next: Framework React
- @medusajs/medusa-js: API client
- tailwindcss: Styling framework
- react: UI library

### Infrastructure
- PostgreSQL: Database (Neon, Supabase, ou local)
- Node.js: Runtime (>=18.0.0)
- pnpm: Package manager (>=8.0.0)

## Documentation

- **README.md**: Documentation complète (installation, COD, déploiement)
- **QUICK-START.md**: Guide de démarrage rapide (5 minutes)
- **medusa-api/docs/capture-cod.md**: Guide capture paiements COD

## Migration from Shopify

Différences clés :
- Coût: 0€/mois vs $29-299/mois Shopify
- Contrôle: Code complet vs Liquid limité
- Hébergement: EU (RGPD) vs US/Canada Shopify
- COD: Natif vs plugins tiers Shopify
- Admin: Open-source vs propriétaire Shopify
