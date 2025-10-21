# Dockerfile pour le frontend Next.js avec gestion rubriques
FROM node:18-alpine

# Informations du mainteneur
LABEL maintainer="yassineco"
LABEL description="Meknow Frontend Next.js avec gestion rubriques Catalogue/Lookbook"
LABEL version="2.0.0"

# Installer les dépendances système
RUN apk add --no-cache libc6-compat curl

# Définir le répertoire de travail
WORKDIR /app

# Variables d'environnement
ENV NODE_ENV=production
ENV PORT=3000
ENV NEXT_TELEMETRY_DISABLED=1

# Copier les fichiers de dépendances
COPY package*.json ./

# Installer TOUTES les dépendances (dev incluses pour le build)
RUN npm ci

# Copier le code source
COPY . .

# Variables d'environnement pour le build
ARG NEXT_PUBLIC_API_URL=http://localhost:9000
ENV NEXT_PUBLIC_API_URL=${NEXT_PUBLIC_API_URL}

# Build de l'application Next.js
RUN npm run build

# Créer un utilisateur non-root
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001

# Changer les permissions
RUN chown -R nextjs:nodejs /app

# Passer à l'utilisateur nextjs
USER nextjs

# Exposer le port
EXPOSE 3000

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:3000 || exit 1

# Commande de démarrage
CMD ["npm", "start"]