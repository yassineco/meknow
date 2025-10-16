module.exports = {
  apps: [
    {
      name: 'meknow-server',
      script: 'basic-server.js',
      cwd: '/opt/meknow',
      instances: 1, // Or use 'max' for cluster mode
      exec_mode: 'fork', // Use 'cluster' for multiple instances
      watch: false,
      max_memory_restart: '1G',
      env: {
        NODE_ENV: 'development',
        PORT: 8080,
        DB_HOST: 'localhost',
        DB_PORT: 5432,
        DB_NAME: 'meknow_production',
        DB_USER: 'meknow_user',
        DB_PASSWORD: 'your_secure_password_here',
        JWT_SECRET: 'your_jwt_secret_here_change_this_in_production'
      },
      env_production: {
        NODE_ENV: 'production',
        PORT: 8080,
        DB_HOST: 'localhost',
        DB_PORT: 5432,
        DB_NAME: 'meknow_production',
        DB_USER: 'meknow_user',
        DB_PASSWORD: 'your_secure_password_here',
        JWT_SECRET: 'your_super_secure_jwt_secret_for_production'
      },
      log_file: '/var/log/pm2/meknow-combined.log',
      out_file: '/var/log/pm2/meknow-out.log',
      error_file: '/var/log/pm2/meknow-error.log',
      merge_logs: true,
      time: true,
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      restart_delay: 1000,
      max_restarts: 10,
      min_uptime: '10s',
      kill_timeout: 5000,
      wait_ready: true,
      listen_timeout: 8000
    }
  ]
};