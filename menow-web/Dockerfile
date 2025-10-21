# Dockerfile simplifié pour Next.js - Version stable
FROM node:18-alpine

# Informations du mainteneur
LABEL maintainer="yassineco"
LABEL description="Meknow Frontend Next.js - Version simplifiée et stable"
LABEL version="2.1.0"

# Installer les dépendances système
RUN apk add --no-cache libc6-compat curl

# Définir le répertoire de travail
WORKDIR /app

# Variables d'environnement
ENV NODE_ENV=production
ENV PORT=3000
ENV NEXT_TELEMETRY_DISABLED=1

# Copier et installer les dépendances
COPY package*.json ./
RUN npm ci

# Copier tout le code source
COPY . .

# Variables d'environnement pour le build
ARG NEXT_PUBLIC_API_URL=http://localhost:9000
ENV NEXT_PUBLIC_API_URL=${NEXT_PUBLIC_API_URL}

# S'assurer que les dossiers nécessaires existent
RUN mkdir -p public .next src/styles

# Créer globals.css si manquant
RUN if [ ! -f "src/styles/globals.css" ]; then \
    echo "@tailwind base; @tailwind components; @tailwind utilities;" > src/styles/globals.css; \
fi

# Build de l'application Next.js
RUN npm run build

# Créer un utilisateur non-root
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001 -G nodejs && \
    chown -R nextjs:nodejs /app

# Passer à l'utilisateur nextjs
USER nextjs

# Exposer le port
EXPOSE 3000

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:3000 || exit 1

# Commande de démarrage
CMD ["npm", "start"]