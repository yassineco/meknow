module.exports = {
  apps: [
    {
      name: 'meknow-backend',
      script: 'backend-minimal.js',
      cwd: '/media/yassine/IA/Projects/menow',
      instances: 1,
      exec_mode: 'fork',
      watch: false,
      max_memory_restart: '1G',
      autorestart: true,
      restart_delay: 1000,
      env: {
        NODE_ENV: 'development',
        PORT: 9000,
        ENABLE_RUBRIQUES: true,
        ENABLE_LOOKBOOK: true
      },
      env_production: {
        NODE_ENV: 'production',
        PORT: 9000,
        DOMAIN: 'meknow.fr',
        ENABLE_RUBRIQUES: true,
        ENABLE_LOOKBOOK: true,
        ENABLE_ADMIN_INTERFACE: true,
        DATABASE_URL: 'postgresql://postgres:meknow2024!@localhost:5432/meknow_production'
      },
      error_file: './logs/err.log',
      out_file: './logs/out.log',
      log_file: './logs/combined.log',
      time: true,
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z'
    },
    {
      name: 'meknow-frontend',
      script: 'npm',
      args: 'start',
      cwd: '/media/yassine/IA/Projects/menow/menow-web',
      instances: 1,
      exec_mode: 'fork',
      watch: false,
      max_memory_restart: '500M',
      autorestart: true,
      restart_delay: 1000,
      env: {
        NODE_ENV: 'development',
        PORT: 3000,
        NEXT_PUBLIC_API_URL: 'http://localhost:9000'
      },
      env_production: {
        NODE_ENV: 'production',
        PORT: 3000,
        NEXT_PUBLIC_API_URL: 'https://meknow.fr',
        API_URL: 'http://localhost:9000',
        ENABLE_RUBRIQUES: true,
        ENABLE_LOOKBOOK: true
      },
      error_file: './logs/frontend-err.log',
      out_file: './logs/frontend-out.log',
      log_file: './logs/frontend-combined.log',
      time: true,
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z'
    }
  ]
};