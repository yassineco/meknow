module.exports = {
  apps: [
    {
      name: 'meknow-backend',
      script: 'backend-minimal.js',
      cwd: '/var/www/meknow',
      instances: 1,
      exec_mode: 'fork',
      watch: false,
      max_memory_restart: '500M',
      env: {
        NODE_ENV: 'production',
        PORT: 9000,
        DATABASE_URL: 'postgresql://postgres:meknow2024!@localhost:5432/meknow_production'
      },
      error_file: '/var/log/meknow/backend-error.log',
      out_file: '/var/log/meknow/backend-out.log',
      log_file: '/var/log/meknow/backend-combined.log',
      time: true,
      autorestart: true,
      max_restarts: 10,
      min_uptime: '10s'
    },
    {
      name: 'meknow-frontend',
      script: 'npm',
      args: 'start',
      cwd: '/var/www/meknow/menow-web',
      instances: 1,
      exec_mode: 'fork',
      watch: false,
      max_memory_restart: '800M',
      env: {
        NODE_ENV: 'production',
        PORT: 5000,
        NEXT_PUBLIC_API_URL: 'http://localhost:9000',
        NEXT_PUBLIC_SITE_URL: 'https://votre-domaine.com'
      },
      error_file: '/var/log/meknow/frontend-error.log',
      out_file: '/var/log/meknow/frontend-out.log',
      log_file: '/var/log/meknow/frontend-combined.log',
      time: true,
      autorestart: true,
      max_restarts: 10,
      min_uptime: '10s'
    },
    {
      name: 'meknow-admin',
      script: 'python3',
      args: '-m http.server 8082',
      cwd: '/var/www/meknow',
      instances: 1,
      exec_mode: 'fork',
      watch: false,
      max_memory_restart: '100M',
      env: {
        PYTHONUNBUFFERED: '1'
      },
      error_file: '/var/log/meknow/admin-error.log',
      out_file: '/var/log/meknow/admin-out.log',
      log_file: '/var/log/meknow/admin-combined.log',
      time: true,
      autorestart: true,
      max_restarts: 10,
      min_uptime: '5s'
    }
  ],

  // Configuration de déploiement (optionnel)
  deploy: {
    production: {
      user: 'deploy',
      host: '31.97.196.215',
      ref: 'origin/main',
      repo: 'https://github.com/votre-username/meknow.git',
      path: '/var/www/meknow',
      'pre-deploy-local': '',
      'post-deploy': 'npm install --production && pm2 reload ecosystem.config.js --env production',
      'pre-setup': ''
    }
  }
};