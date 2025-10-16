# VPS Deployment Guide - Native Setup

## Migration from Docker to Native Services

This guide will help you migrate your MeNow e-commerce platform from Docker containers to native services on your VPS.

## Prerequisites

- Ubuntu/Debian VPS with sudo access
- Domain name pointing to your VPS IP
- SSH access to your VPS

## Step 1: Server Preparation

### Update system
```bash
sudo apt update && sudo apt upgrade -y
```

### Install required packages
```bash
sudo apt install -y postgresql postgresql-contrib nodejs npm nginx git curl wget
```

### Install PM2 for process management
```bash
sudo npm install -g pm2
```

## Step 2: PostgreSQL Setup

### Configure PostgreSQL
```bash
# Switch to postgres user
sudo -u postgres psql

# Create database and user
CREATE DATABASE meknow_production;
CREATE USER meknow_user WITH PASSWORD 'your_secure_password_here';
GRANT ALL PRIVILEGES ON DATABASE meknow_production TO meknow_user;
\q
```

### Configure PostgreSQL authentication
```bash
# Edit pg_hba.conf
sudo nano /etc/postgresql/*/main/pg_hba.conf

# Add this line (replace with your actual IP if needed):
local   meknow_production   meknow_user                     md5
```

### Restart PostgreSQL
```bash
sudo systemctl restart postgresql
sudo systemctl enable postgresql
```

## Step 3: Application Deployment

### Clone your repository
```bash
cd /opt
sudo git clone https://github.com/yassineco/meknow.git
sudo chown -R $USER:$USER /opt/meknow
cd /opt/meknow
```

### Install dependencies
```bash
npm install
```

### Environment Configuration
```bash
# Create production environment file
cp .env.example .env.production

# Edit with your production values
nano .env.production
```

### Database Setup
```bash
# Import your schema
PGPASSWORD='your_secure_password_here' psql -h localhost -U meknow_user -d meknow_production -f schema.sql
```

## Step 4: PM2 Process Management

### Create PM2 ecosystem file
```bash
# See ecosystem.config.js file created separately
```

### Start application with PM2
```bash
pm2 start ecosystem.config.js --env production
pm2 save
pm2 startup
```

## Step 5: Nginx Configuration

### Create Nginx configuration
```bash
# See nginx configuration file created separately
sudo ln -s /etc/nginx/sites-available/meknow /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl enable nginx
```

## Step 6: SSL Certificate (Let's Encrypt)

### Install Certbot
```bash
sudo apt install certbot python3-certbot-nginx
```

### Obtain certificate
```bash
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

## Step 7: Firewall Configuration

### Configure UFW
```bash
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw --force enable
```

## Step 8: Monitoring and Logs

### View application logs
```bash
pm2 logs meknow-server
```

### Monitor processes
```bash
pm2 monit
```

### Nginx logs
```bash
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

## Maintenance Commands

### Update application
```bash
cd /opt/meknow
git pull origin main
npm install
pm2 restart meknow-server
```

### Database backup
```bash
pg_dump -h localhost -U meknow_user meknow_production > backup_$(date +%Y%m%d_%H%M%S).sql
```

### Database restore
```bash
PGPASSWORD='your_password' psql -h localhost -U meknow_user -d meknow_production < backup_file.sql
```

## Troubleshooting

### Check service status
```bash
sudo systemctl status postgresql
sudo systemctl status nginx
pm2 status
```

### Check ports
```bash
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :8080
sudo netstat -tlnp | grep :5432
```

### Check logs
```bash
# Application logs
pm2 logs meknow-server

# Nginx logs
sudo tail -f /var/log/nginx/error.log

# PostgreSQL logs
sudo tail -f /var/log/postgresql/postgresql-*.log
```

## Security Considerations

1. Change default PostgreSQL passwords
2. Configure fail2ban for SSH protection
3. Regular security updates
4. Database backups
5. Monitor application logs
6. Use strong JWT secrets
7. Configure proper file permissions

## Performance Optimization

1. Enable Nginx gzip compression
2. Configure PostgreSQL for your VPS specs
3. Use PM2 cluster mode for multiple CPU cores
4. Implement caching strategies
5. Monitor resource usage

---

*Last updated: October 16, 2025*