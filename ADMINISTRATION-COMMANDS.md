# 🔧 ADMINISTRATION COMMANDS - MEKNOW PRODUCTION

**Date**: 22 octobre 2025  
**VPS**: 31.97.196.215  
**Environment**: Ubuntu 24.04 + Node.js 18 + PostgreSQL 16 + Nginx  

---

## 🚀 QUICK START COMMANDS

### SSH Access
```bash
# Connect to VPS
ssh root@31.97.196.215

# Working directory
cd /var/www/meknow
```

---

## 📋 SERVICE MANAGEMENT

### Check All Services

```bash
# Status of all services
systemctl status meknow-backend.service meknow-frontend.service nginx postgresql@16-main

# Detailed output
systemctl status meknow-backend.service --no-pager

# Auto-refresh (every 2 seconds)
watch -n 2 'systemctl status meknow-backend.service meknow-frontend.service | grep -E "Active:|Status:"'
```

### Restart Services

```bash
# Restart backend only
systemctl restart meknow-backend.service

# Restart frontend only
systemctl restart meknow-frontend.service

# Restart both
systemctl restart meknow-backend.service meknow-frontend.service

# Restart all services
systemctl restart meknow-backend.service meknow-frontend.service nginx

# Restart with 5-second delay between each
systemctl restart meknow-backend.service && sleep 5 && systemctl restart meknow-frontend.service
```

### Stop/Start Services

```bash
# Stop backend
systemctl stop meknow-backend.service

# Start backend
systemctl start meknow-backend.service

# Stop both
systemctl stop meknow-backend.service meknow-frontend.service

# Start both
systemctl start meknow-backend.service meknow-frontend.service

# Stop all including nginx
systemctl stop meknow-backend.service meknow-frontend.service nginx

# Start all
systemctl start meknow-backend.service meknow-frontend.service nginx
```

### Enable/Disable Auto-Start

```bash
# Enable auto-start on boot
systemctl enable meknow-backend.service
systemctl enable meknow-frontend.service
systemctl enable nginx
systemctl enable postgresql@16-main

# Disable auto-start
systemctl disable meknow-backend.service

# Check if enabled
systemctl is-enabled meknow-backend.service
```

---

## 📊 MONITORING & LOGS

### Real-Time Logs

```bash
# Follow backend logs
journalctl -u meknow-backend.service -f

# Follow frontend logs
journalctl -u meknow-frontend.service -f

# Follow Nginx logs
journalctl -u nginx -f

# Follow PostgreSQL logs
journalctl -u postgresql@16-main -f

# Follow all related logs
journalctl -u meknow-backend.service -u meknow-frontend.service -u nginx -f
```

### View Historical Logs

```bash
# Last 50 lines
journalctl -u meknow-backend.service -n 50

# Last 100 lines
journalctl -u meknow-backend.service -n 100 --no-pager

# All logs for today
journalctl -u meknow-backend.service --since today

# Logs from last hour
journalctl -u meknow-backend.service --since "1 hour ago"

# Logs from specific date
journalctl -u meknow-backend.service --since "2025-10-22" --until "2025-10-23"

# Search for errors
journalctl -u meknow-backend.service | grep ERROR

# Search for warnings
journalctl -u meknow-backend.service | grep WARNING

# Count errors
journalctl -u meknow-backend.service | grep -c ERROR
```

### System Health

```bash
# Check disk usage
df -h

# Check memory
free -h

# Check CPU
top -b -n 1 | head -10

# Check running processes
ps aux | grep -E "node|next|postgres|nginx" | grep -v grep

# Check load average
uptime

# Check temperature (if available)
sensors
```

---

## 🔌 PORT & PROCESS MANAGEMENT

### Check Open Ports

```bash
# List all listening ports
netstat -tulpn

# Check specific port
netstat -tulpn | grep 9000

# Check port 3000
netstat -tulpn | grep 3000

# Check port 5432 (PostgreSQL)
netstat -tulpn | grep 5432

# Check port 80/443 (Nginx)
netstat -tulpn | grep -E ":80|:443"

# Modern alternative
ss -tulpn | grep 9000
```

### Process Management

```bash
# Find all Node processes
ps aux | grep node | grep -v grep

# Find Next.js process
ps aux | grep next | grep -v grep

# Find PostgreSQL process
ps aux | grep postgres | grep -v grep

# Kill a process by PID
kill -9 12345

# Kill all Node processes
pkill -f "node" --signal 9

# List processes by memory usage
ps aux --sort=-%mem | head -10

# List processes by CPU usage
ps aux --sort=-%cpu | head -10
```

---

## 🗄️ DATABASE MANAGEMENT

### Connect to Database

```bash
# Connect as postgres user
sudo -u postgres psql -d meknow_production

# Connect with specific user
sudo -u postgres psql -d meknow_production -U meknow

# Execute single command
sudo -u postgres psql -d meknow_production -c "SELECT COUNT(*) FROM products_data;"

# List all databases
sudo -u postgres psql -lqt

# List all users
sudo -u postgres psql -c "\du"
```

### SQL Commands (inside psql)

```sql
-- View all products
SELECT * FROM products_data;

-- Count products
SELECT count(*) FROM products_data;

-- View latest version
SELECT MAX(version) as latest_version FROM products_data;

-- View product versions
SELECT version, COUNT(*) as count FROM products_data GROUP BY version ORDER BY version DESC;

-- Export products JSON
SELECT products FROM products_data ORDER BY version DESC LIMIT 1;

-- List all tables
\dt

-- List table structure
\d products_data

-- List all users
\du

-- List database privileges
\l

-- Exit psql
\q
```

### Database Backups

```bash
# Full backup
sudo -u postgres pg_dump meknow_production > /backup/meknow_$(date +%Y%m%d_%H%M%S).sql

# Backup with compression
sudo -u postgres pg_dump meknow_production | gzip > /backup/meknow_$(date +%Y%m%d).sql.gz

# Restore from backup
sudo -u postgres psql meknow_production < /backup/meknow_20251022.sql

# Restore from compressed backup
gunzip -c /backup/meknow_20251022.sql.gz | sudo -u postgres psql meknow_production

# List backups
ls -lh /backup/meknow_*.sql*

# Size of database
sudo -u postgres psql -d meknow_production -c "SELECT pg_size_pretty(pg_database_size('meknow_production'));"
```

---

## 🌐 API & ENDPOINT TESTING

### Health Checks

```bash
# Backend health
curl http://localhost:9000/health
curl -s http://localhost:9000/health | jq .

# Frontend health
curl http://localhost:3000
curl -s http://localhost:3000 | head -20

# Nginx health
curl -I http://localhost

# Full check
curl -s http://localhost:9000/health
curl -s http://localhost:3000 | grep -o "<title>.*</title>"
curl -s http://localhost:9000/api/products | jq '.products | length'
```

### API Endpoints

```bash
# Get all products
curl http://localhost:9000/api/products | jq .

# Get product count
curl -s http://localhost:9000/api/products | jq '.products | length'

# Get lookbook products
curl http://localhost:9000/api/products/lookbook | jq .

# Get lookbook count
curl -s http://localhost:9000/api/products/lookbook | jq '.products | length'

# Get admin interface
curl http://localhost:9000/admin

# Test CORS
curl -H "Origin: http://localhost:3000" \
     -H "Access-Control-Request-Method: POST" \
     -H "Access-Control-Request-Headers: X-Custom-Header" \
     -X OPTIONS \
     http://localhost:9000/api/products -v
```

### POST Requests (Add Products)

```bash
# Create new product
curl -X POST http://localhost:9000/api/products \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Product",
    "description": "Test Description",
    "price": 9999,
    "imageUrl": "/images/test.jpg"
  }'

# Delete product
curl -X DELETE http://localhost:9000/api/products/prod_123abc
```

---

## 🔄 FILE & CODE MANAGEMENT

### Code Updates

```bash
# Pull latest from GitHub
cd /var/www/meknow
git pull origin frontend-sync-complete

# Check git status
git status

# View recent commits
git log --oneline -10

# View changes
git diff

# Revert changes
git reset --hard HEAD
```

### Frontend Rebuild

```bash
# Build frontend
cd /var/www/meknow/menow-web
pnpm run build

# Clean and rebuild
rm -rf .next
pnpm run build

# Restart frontend
systemctl restart meknow-frontend.service

# Verify
curl -s http://localhost:3000 | grep -o "<title>.*</title>"
```

### Backend Reload

```bash
# Edit code
nano /var/www/meknow/backend-minimal.js

# Restart backend
systemctl restart meknow-backend.service

# Check logs
journalctl -u meknow-backend.service -f
```

---

## 🛡️ SECURITY & PERMISSIONS

### File Permissions

```bash
# Fix ownership
chown -R www-data:www-data /var/www/meknow

# Fix permissions
chmod -R 755 /var/www/meknow
chmod -R 775 /var/www/meknow/uploads /var/www/meknow/logs

# Check permissions
ls -la /var/www/meknow | head -5

# Verify ownership
stat /var/www/meknow/backend-minimal.js | grep -E "Uid|Gid"
```

### Service Account

```bash
# Check www-data user
id www-data

# Add/modify user
usermod -aG docker www-data

# Check sudo access
sudo -u www-data whoami
```

### SSL Certificates

```bash
# List certificates
certbot certificates

# Renew certificates
certbot renew

# Force renewal
certbot renew --force-renewal

# Check certificate details
openssl x509 -in /etc/letsencrypt/live/meknow.fr/fullchain.pem -noout -text

# Test SSL
openssl s_client -connect meknow.fr:443

# Nginx SSL test
nginx -t

# Reload Nginx with SSL
systemctl reload nginx
```

---

## 🔍 TROUBLESHOOTING COMMANDS

### Diagnostic

```bash
# Full system diagnostic
echo "=== SERVICES ===" && \
systemctl status meknow-backend.service meknow-frontend.service nginx postgresql@16-main --no-pager && \
echo -e "\n=== PORTS ===" && \
netstat -tulpn | grep -E ":9000|:3000|:5432|:80|:443" && \
echo -e "\n=== PROCESSES ===" && \
ps aux | grep -E "node|next|postgres|nginx" | grep -v grep && \
echo -e "\n=== DISK ===" && \
df -h | head -3 && \
echo -e "\n=== MEMORY ===" && \
free -h | head -2
```

### Common Issues

```bash
# Port already in use
lsof -i :9000
lsof -i :3000

# Permission denied
ls -la /var/www/meknow/backend-minimal.js

# Database connection failed
sudo -u postgres psql -d meknow_production -c "SELECT 1;"

# Nginx configuration error
nginx -t

# Out of disk space
df -h
du -sh /var/www/meknow
du -sh /var/lib/postgresql

# Memory issues
free -h
top -b -n 1 | head -10

# Service won't start
journalctl -u meknow-backend.service -n 50 --no-pager
```

---

## 📅 MAINTENANCE SCHEDULE

### Daily

```bash
# Check service status
systemctl status meknow-backend.service meknow-frontend.service

# Review error logs
journalctl -u meknow-backend.service --since today | grep ERROR
journalctl -u meknow-frontend.service --since today | grep ERROR

# Check disk usage
df -h /

# Check memory
free -h
```

### Weekly

```bash
# Full system check
(diagnostic command above)

# Database backup
sudo -u postgres pg_dump meknow_production | gzip > /backup/meknow_$(date +%Y%m%d).sql.gz

# Check certificate renewal
certbot certificates

# Review logs
journalctl -u meknow-backend.service --since "7 days ago" | grep -E "ERROR|WARNING" | tail -20
```

### Monthly

```bash
# Update packages (if needed)
apt list --upgradable

# Update Node dependencies
cd /var/www/meknow
npm outdated
npm update

# Update frontend dependencies
cd menow-web
pnpm outdated
pnpm update

# Clean up old logs
journalctl --vacuum-time=30d

# System review
uname -a
lsb_release -a
node --version
npm --version
```

---

## 📞 EMERGENCY PROCEDURES

### Service Crash Recovery

```bash
# If backend crashes:
systemctl restart meknow-backend.service
journalctl -u meknow-backend.service -f

# If frontend crashes:
systemctl restart meknow-frontend.service
journalctl -u meknow-frontend.service -f

# If database crashes:
systemctl restart postgresql@16-main
sudo -u postgres pg_isready

# If Nginx crashes:
systemctl restart nginx
nginx -t
```

### Full System Recovery

```bash
# Stop all services
systemctl stop meknow-backend.service meknow-frontend.service nginx

# Check for issues
journalctl --since "10 minutes ago" --no-pager

# Start services in order
systemctl start postgresql@16-main
sleep 2
systemctl start nginx
sleep 2
systemctl start meknow-backend.service
sleep 2
systemctl start meknow-frontend.service

# Verify
curl http://localhost:9000/health
curl -s http://localhost:3000 | head -1
```

### Data Recovery

```bash
# List backups
ls -lh /backup/meknow_*.sql.gz

# Restore from backup
gunzip -c /backup/meknow_20251022.sql.gz | sudo -u postgres psql meknow_production

# Verify recovery
sudo -u postgres psql -d meknow_production -c "SELECT COUNT(*) FROM products_data;"
```

---

## 🎯 COMMON WORKFLOWS

### Add a New Product

```bash
# Via curl
curl -X POST http://localhost:9000/api/products \
  -H "Content-Type: application/json" \
  -d '{
    "title": "New Product",
    "description": "Product Description",
    "price": 12900,
    "imageUrl": "/images/new-product.jpg",
    "display_sections": ["catalog", "lookbook"],
    "lookbook_category": "collection-premium"
  }'

# Or use admin at: http://localhost:9000/admin
```

### Deploy Code Changes

```bash
# Pull from GitHub
cd /var/www/meknow
git pull origin frontend-sync-complete

# Rebuild frontend if needed
cd menow-web
pnpm run build
cd ..

# Restart services
systemctl restart meknow-backend.service meknow-frontend.service

# Verify
curl -s http://localhost:9000/health
journalctl -u meknow-backend.service -n 5 --no-pager
```

### Backup and Restore

```bash
# Create backup
sudo -u postgres pg_dump meknow_production | gzip > /backup/meknow_$(date +%Y%m%d_%H%M%S).sql.gz

# List backups
ls -lh /backup/meknow_*.sql.gz

# Restore
gunzip -c /backup/meknow_BACKUP_DATE.sql.gz | sudo -u postgres psql meknow_production

# Verify
sudo -u postgres psql -d meknow_production -c "SELECT COUNT(*) FROM products_data;"
```

---

## 📚 ADDITIONAL RESOURCES

**Main Documentation**:
- See `README-LATEST.md` for architecture
- See `DEPLOYMENT-SUCCESS-REPORT.md` for deployment status
- See `MODIFICATIONS-TECHNIQUES-v1.2.md` for technical details

**Quick Links**:
- Admin: http://localhost:9000/admin
- Frontend: http://localhost:3000
- API: http://localhost:9000/api
- Health: http://localhost:9000/health

---

**Last Updated**: 22 octobre 2025  
**Version**: 1.0.0  
**Status**: Production Ready ✅

**Keep this file bookmarked for quick access to all admin commands!** 📌
