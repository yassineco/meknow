# 📚 DOCUMENTATION BACKEND MEKNOW v2

## 🎯 Vue d'ensemble

Le backend Meknow v2 est une API REST complète développée avec Express.js pour la gestion d'un e-commerce. Il remplace l'ancienne architecture MedusaJS par une solution sur mesure plus performante et stable.

## 🏗️ Architecture

```
backend-v2.js               # Serveur principal avec toutes les routes
schema.sql                  # Schéma de base de données PostgreSQL
routes/                     # Routes modulaires (pour référence)
├── products.js            # Gestion des produits
├── orders.js              # Gestion des commandes
├── customers.js           # Gestion des clients
└── inventory.js           # Gestion de l'inventaire
utils/
└── order-helpers.js       # Utilitaires pour les commandes
```

## 🔧 Technologies utilisées

- **Express.js 5.1.0** - Framework backend
- **PostgreSQL** - Base de données
- **JWT** - Authentification
- **bcryptjs** - Hashage des mots de passe
- **Multer** - Upload de fichiers
- **CORS** - Gestion des origines croisées

## 📊 Base de données

### Tables principales :
- `admin_users` - Comptes administrateurs
- `admin_sessions` - Sessions JWT actives
- `admin_logs` - Journal d'audit
- `products` - Produits du catalogue
- `product_variants` - Variantes des produits
- `orders` - Commandes clients
- `order_items` - Articles des commandes
- `customers` - Base clients
- `inventory_movements` - Mouvements de stock

## 🚀 Démarrage

### Prérequis
```bash
# Installation des dépendances
npm install

# Configuration PostgreSQL
psql -U postgres -d meknow < schema.sql
```

### Variables d'environnement
```bash
DATABASE_URL=postgresql://user:password@localhost:5432/meknow
JWT_SECRET=your-super-secret-key
PORT=5000
```

### Lancement
```bash
node backend-v2.js
```

Le serveur démarrera sur `http://localhost:5000`

## 🔐 Authentification

### Connexion admin
```http
POST /api/admin/login
Content-Type: application/json

{
  "username": "admin",
  "password": "votre-mot-de-passe"
}
```

### Réponse
```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "admin": {
    "id": 1,
    "username": "admin",
    "email": "admin@meknow.com"
  }
}
```

### Utilisation du token
```http
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
```

## 📚 Endpoints API

### 🏠 Public (Frontend)

#### Produits
```http
GET /api/products                    # Liste des produits
GET /api/products/:identifier        # Détail d'un produit
GET /api/search?q=terme             # Recherche produits
```

#### Commandes
```http
POST /api/orders                     # Créer une commande
```

### 🔒 Admin (Protégé par JWT)

#### 🎯 Dashboard
```http
GET /api/admin/dashboard?period=30d  # KPIs et métriques
GET /api/admin/analytics/sales       # Analytics détaillées
GET /api/admin/reports/sales         # Rapports exportables
```

#### 📦 Produits
```http
GET    /api/admin/products           # Liste admin
POST   /api/admin/products           # Créer produit
GET    /api/admin/products/:id       # Détail produit
PUT    /api/admin/products/:id       # Modifier produit
DELETE /api/admin/products/:id       # Supprimer produit
POST   /api/admin/products/:id/variants  # Ajouter variante
PUT    /api/admin/products/:productId/variants/:variantId  # Modifier variante
```

#### 🛒 Commandes
```http
GET /api/admin/orders                # Liste des commandes
GET /api/admin/orders/:id            # Détail commande
PUT /api/admin/orders/:id/status     # Modifier statut
POST /api/admin/orders/:id/cancel    # Annuler commande
```

#### 👥 Clients
```http
GET    /api/admin/customers          # Liste clients
GET    /api/admin/customers/:id      # Détail client
POST   /api/admin/customers          # Créer client
PUT    /api/admin/customers/:id      # Modifier client
DELETE /api/admin/customers/:id      # Supprimer client
GET    /api/admin/customers/stats    # Statistiques clients
```

#### 📊 Inventaire
```http
GET  /api/admin/inventory/dashboard  # Dashboard stock
POST /api/admin/inventory/adjust     # Ajuster stock
GET  /api/admin/inventory/report     # Rapport inventaire
GET  /api/admin/inventory/movements  # Historique mouvements
```

#### 🔍 Logs et Audit
```http
GET /api/admin/logs                  # Journal d'activité
GET /api/admin/logs/export           # Export logs
GET /api/admin/security/stats        # Statistiques sécurité
```

#### 🔧 Maintenance
```http
POST /api/admin/maintenance/cleanup-sessions  # Nettoyer sessions
```

## 📋 Exemples d'utilisation

### Créer un produit
```http
POST /api/admin/products
Authorization: Bearer <token>
Content-Type: application/json

{
  "title": "T-shirt Premium",
  "description": "T-shirt en coton bio",
  "price": 29.99,
  "compare_at_price": 39.99,
  "category": "vetements",
  "tags": ["bio", "mode", "confort"],
  "images": ["https://example.com/image.jpg"],
  "variants": [
    {
      "title": "Noir / S",
      "price": 29.99,
      "sku": "TSHIRT-NOIR-S",
      "inventory_quantity": 50,
      "color": "Noir",
      "size": "S"
    }
  ]
}
```

### Passer une commande
```http
POST /api/orders
Content-Type: application/json

{
  "customer_email": "client@example.com",
  "customer_first_name": "Jean",
  "customer_last_name": "Dupont",
  "customer_phone": "0123456789",
  "billing_address": {
    "first_name": "Jean",
    "last_name": "Dupont",
    "address1": "123 rue de la Paix",
    "city": "Paris",
    "zip": "75001",
    "country": "France"
  },
  "shipping_address": {
    "first_name": "Jean",
    "last_name": "Dupont",
    "address1": "123 rue de la Paix",
    "city": "Paris",
    "zip": "75001",
    "country": "France"
  },
  "items": [
    {
      "variant_id": 1,
      "quantity": 2
    }
  ],
  "payment_method": "cod",
  "shipping_method": "standard"
}
```

### Ajuster le stock
```http
POST /api/admin/inventory/adjust
Authorization: Bearer <token>
Content-Type: application/json

{
  "variant_id": 1,
  "quantity_change": 10,
  "reason": "restock",
  "note": "Réapprovisionnement fournisseur"
}
```

## 🔒 Sécurité

### Fonctionnalités de sécurité :
- ✅ Authentification JWT avec expiration
- ✅ Hashage bcrypt des mots de passe
- ✅ Middleware de protection des routes admin
- ✅ Audit trail complet de toutes les actions
- ✅ Gestion des sessions avec nettoyage automatique
- ✅ Protection CORS configurée
- ✅ Validation des données d'entrée
- ✅ Logging des tentatives de connexion
- ✅ Détection des IPs suspectes

### Bonnes pratiques :
- Rotation régulière du JWT_SECRET
- Nettoyage périodique des sessions expirées
- Surveillance des logs d'audit
- Sauvegarde régulière de la base de données

## 📈 Monitoring

### KPIs disponibles :
- **Ventes** : Revenus, nombre de commandes, panier moyen
- **Produits** : Stock, variantes, valeur inventaire
- **Clients** : Nouveaux clients, valeur vie client, rétention
- **Sécurité** : Tentatives de connexion, sessions actives

### Exports disponibles :
- CSV des rapports de ventes
- CSV des logs d'audit
- JSON pour intégrations

## 🚀 Déploiement

### Production
```bash
# Variables d'environnement production
NODE_ENV=production
DATABASE_URL=postgresql://user:pass@host:5432/db
JWT_SECRET=complex-production-secret
PORT=5000

# Lancement avec PM2
pm2 start backend-v2.js --name "meknow-api"
```

### Docker
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 5000
CMD ["node", "backend-v2.js"]
```

## 🐛 Debugging

### Logs disponibles :
- Console serveur avec émojis pour identification
- Logs d'erreurs avec stack traces
- Audit trail dans la base de données
- Monitoring des performances

### Endpoints de diagnostic :
```http
GET /health                          # Santé du serveur
GET /api/admin/security/stats        # État de la sécurité
```

## 📝 TODO Futur

### Améliorations possibles :
- [ ] Rate limiting sur les APIs
- [ ] Cache Redis pour les performances
- [ ] Tests automatisés (Jest)
- [ ] Documentation OpenAPI/Swagger
- [ ] Notifications email/SMS
- [ ] Webhooks pour intégrations externes
- [ ] API GraphQL optionnelle
- [ ] Metrics Prometheus/Grafana

## 📞 Support

Pour toute question ou problème :
1. Consulter les logs : `GET /api/admin/logs`
2. Vérifier les stats sécurité : `GET /api/admin/security/stats`
3. Examiner le dashboard : `GET /api/admin/dashboard`

---

**🎉 Backend Meknow v2 - E-commerce API complète**
*Développé avec ❤️ pour une gestion e-commerce professionnelle*