# ME NOW - Thème Shopify Premium

Thème Shopify premium pour ME NOW, marque de prêt-à-porter fabriqué au Maroc avec expédition depuis la France. Design sombre et luxueux avec mise en avant du paiement à la livraison (COD) en France.

## 🎨 Caractéristiques du Design

- **Palette sombre premium** : Fond noir (#0B0B0C, #121214) avec accents dorés (#F2C14E)
- **Design responsive** : Optimisé pour mobile, tablette et desktop
- **Performance optimisée** : CSS moderne avec variables CSS et animations fluides
- **Accessibilité** : Focus visibles, alt text, navigation au clavier

## 🚀 Prérequis

- Node.js >= 18
- npm ou yarn
- Shopify CLI installé (`npm install -g @shopify/cli @shopify/theme`)
- Un compte Shopify Partner ou une boutique Shopify

## 📦 Installation

```bash
# Installer les dépendances
npm install

# Se connecter à Shopify
shopify login --store <votre-boutique>.myshopify.com

# Lancer le serveur de développement
npm run dev

# Pousser le thème vers Shopify
npm run push

# Vérifier le thème (validation)
npm run check

# Formater le code
npm run fmt
```

## 📁 Structure du Projet

```
menow-theme/
├── config/
│   └── settings_schema.json      # Configuration du thème (couleurs, logos, badges)
├── layout/
│   └── theme.liquid               # Layout principal avec SEO et structure
├── assets/
│   ├── base.css                   # Styles de base et composants
│   └── sticky-atc.js              # Script Add-to-Cart sticky
├── sections/
│   ├── hero-video.liquid          # Hero avec vidéo et badge Made in Morocco
│   ├── lookbook-grid.liquid       # Grille lookbook 3 colonnes
│   ├── reassurance-bar.liquid     # Barre de réassurance paramétrable
│   ├── featured-collection.liquid # Produits vedettes
│   └── rich-text.liquid           # Section texte enrichi
├── snippets/
│   ├── badges-reassurance.liquid  # Badges réassurance réutilisables
│   └── price-with-cod-note.liquid # Prix avec note COD
└── templates/
    ├── index.json                 # Page d'accueil
    ├── product.json               # Page produit
    ├── collection.json            # Page collection
    ├── page.json                  # Pages statiques
    └── search.json                # Page de recherche
```

## ⚙️ Configuration

### 1. Couleurs du thème

Modifiez les couleurs dans `config/settings_schema.json` ou via l'éditeur de thème Shopify :

- Fond principal : `#0B0B0C`
- Fond secondaire : `#121214`
- Texte principal : `#F3F3F3`
- Texte secondaire : `#B5B5B5`
- Accent (Or) : `#F2C14E`
- Bordures : `#1E1E22`

### 2. Logo et Images

- **Logo** : Uploadez dans Paramètres du thème → Logo
- **Favicon** : Uploadez dans Paramètres du thème → Favicon
- **Image OG** : Image par défaut pour les réseaux sociaux

### 3. Badges de Réassurance

Activez/désactivez dans les paramètres du thème :

- ✅ Paiement à la livraison (France)
- ✅ Retour 14 jours
- ✅ Expédié depuis France
- ✅ Made in Morocco

### 4. Paiement à la livraison (COD)

**Configuration Shopify** :

1. Allez dans Shopify Admin → Paramètres → Paiements
2. Activez "Paiements manuels"
3. Ajoutez "Paiement à la livraison" comme option
4. Configurez pour la France uniquement

**Configuration Thème** :

- Les instructions COD sont paramétrables dans `config/settings_schema.json`
- La note COD s'affiche automatiquement sur les fiches produits
- Personnalisez le texte dans Paramètres du thème → Paiement COD

## 📄 Pages Légales (Obligatoires en France)

Créez ces pages dans Shopify Admin → Pages :

- `/pages/cgv` - Conditions Générales de Vente
- `/pages/mentions-legales` - Mentions Légales
- `/pages/confidentialite` - Politique de Confidentialité / RGPD
- `/pages/retours` - Retours & Remboursements

Les liens apparaîtront automatiquement dans le footer.

## 🎯 SEO & Accessibilité

### SEO Inclus

- Meta title et description dynamiques
- Open Graph tags pour réseaux sociaux
- JSON-LD Schema.org pour l'organisation
- Canonical URLs
- Image alt text

### Accessibilité

- Liens "Skip to content"
- Focus visibles (outline doré)
- Navigation au clavier
- ARIA labels
- Contraste des couleurs respecté

## 🛠️ Développement

### Scripts Disponibles

```bash
npm run dev     # Développement avec live-reload
npm run push    # Déployer vers Shopify
npm run check   # Valider le thème
npm run fmt     # Formater le code
```

### Composants CSS Réutilisables

- `.button` / `.button--ghost` - Boutons
- `.badge` / `.badge--premium` - Badges
- `.card` - Cartes produits
- `.section` / `.section--dark` - Sections

### Personnalisation

Les variables CSS sont dans `assets/base.css` :

```css
:root {
  --color-bg-primary: #0B0B0C;
  --color-accent: #F2C14E;
  --spacing-md: 2rem;
  /* ... */
}
```

## 📱 Responsive

Le thème est entièrement responsive avec breakpoints :

- Mobile : < 768px
- Tablette : 768px - 1024px
- Desktop : > 1024px

## 🚢 Déploiement

1. Testez localement avec `npm run dev`
2. Vérifiez avec `npm run check`
3. Déployez avec `npm run push`
4. Activez le thème dans Shopify Admin

## 🆘 Support

### Problèmes Courants

**Le thème ne charge pas ?**
- Vérifiez que Shopify CLI est installé
- Assurez-vous d'être connecté avec `shopify login`

**Les modifications ne s'affichent pas ?**
- Le live-reload est actif avec `npm run dev`
- Videz le cache du navigateur

**Erreur de syntaxe Liquid ?**
- Lancez `npm run check` pour valider

## 📝 Licence

Propriété de ME NOW. Tous droits réservés.

---

**ME NOW** - L'excellence marocaine dans le prêt-à-porter 🇲🇦
