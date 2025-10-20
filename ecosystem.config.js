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
        PORT: 9000
      },
      env_production: {
        NODE_ENV: 'production',
        PORT: 9000
      },
      error_file: './logs/err.log',
      out_file: './logs/out.log',
      log_file: './logs/combined.log',
      time: true,
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z'
    }
  ]
};