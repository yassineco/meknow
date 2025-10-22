module.exports = {
  apps: [
    {
      name: 'meknow-api',
      script: 'backend-minimal.js',
      cwd: '/var/www/meknow',
      instances: 1,
      exec_mode: 'fork',
      watch: false,
      max_memory_restart: '512M',
      autorestart: true,
      restart_delay: 1000,
      env: {
        NODE_ENV: 'development',
        PORT: 9000
      },
      env_production: {
        NODE_ENV: 'production',
        PORT: 9000
      },
      env_staging: {
        NODE_ENV: 'staging',
        PORT: 9000
      },
      error_file: '/var/log/meknow/api-err.log',
      out_file: '/var/log/meknow/api-out.log',
      log_file: '/var/log/meknow/api-combined.log',
      time: true,
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z'
    },
    {
      name: 'meknow-web',
      script: 'npm',
      args: 'start',
      cwd: '/var/www/meknow/menow-web',
      instances: 1,
      exec_mode: 'fork',
      watch: false,
      max_memory_restart: '1G',
      autorestart: true,
      restart_delay: 1000,
      env: {
        NODE_ENV: 'development',
        PORT: 3000
      },
      env_production: {
        NODE_ENV: 'production',
        PORT: 3000
      },
      env_staging: {
        NODE_ENV: 'staging',
        PORT: 3000
      },
      error_file: '/var/log/meknow/web-err.log',
      out_file: '/var/log/meknow/web-out.log',
      log_file: '/var/log/meknow/web-combined.log',
      time: true,
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z'
    }
  ]
};