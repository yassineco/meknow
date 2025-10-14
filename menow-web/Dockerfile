# Dockerfile pour le frontend Next.js
FROM node:18-alpine AS base

# Installer les dépendances seulement quand nécessaire
FROM base AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Installer les dépendances basées sur le gestionnaire de packages préféré
COPY package.json package-lock.json* ./
RUN npm ci

# Rebuild le code source seulement quand nécessaire
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Variables d'environnement pour le build
ARG NEXT_PUBLIC_API_URL
ENV NEXT_PUBLIC_API_URL=${NEXT_PUBLIC_API_URL}

# Build de l'application
RUN npm run build

# Image de production, copier tous les fichiers et lancer Next.js
FROM base AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV PORT=5000

# Créer un utilisateur non-root
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Copier les fichiers nécessaires depuis builder
COPY --from=builder /app/public ./public

# Définir les permissions correctes pour les assets pré-rendus
RUN mkdir .next
RUN chown nextjs:nodejs .next

# Copier automatiquement les fichiers de sortie standalone
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 5000

ENV HOSTNAME="0.0.0.0"

# Commande de démarrage
CMD ["node", "server.js"]