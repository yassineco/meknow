/** @type {import('next').NextConfig} */
const nextConfig = {
  // Configuration pour déploiement Docker
  output: 'standalone',
  
  // Configuration des images
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'images.unsplash.com',
      },
      {
        protocol: 'https',
        hostname: 'picsum.photos',
      },
      {
        protocol: 'http',
        hostname: 'localhost',
        port: '9000',
      },
      {
        protocol: 'https',
        hostname: 'meknow.fr',
      },
    ],
  },
  
  // Configuration expérimentale pour le build
  experimental: {
    // Permettre les fetches pendant le build même si le serveur n'est pas disponible
    allowedRevalidateHeaderKeys: ['x-revalidate'],
  },
};

export default nextConfig;
