# 🚀 VPS DEPLOYMENT QUICK START - MEKNOW

**Date**: 22 octobre 2025  
**Target**: 31.97.196.215 (Ubuntu 24.04)  
**Domain**: meknow.fr

---

## ⚡ Quick Deployment (5 Minutes)

### Step 1: Connect to VPS
```bash
ssh root@31.97.196.215
```

### Step 2: Clone & Download Script
```bash
cd /var/www
git clone https://github.com/yassineco/meknow.git
cd meknow
```

### Step 3: Run Automated Deployment
```bash
bash deploy-vps-production.sh
```

**That's it!** ✅ Script handles everything:
- ✅ System updates
- ✅ Node.js + npm + pnpm
- ✅ PostgreSQL + database setup
- ✅ Nginx reverse proxy
- ✅ Let's Encrypt SSL
- ✅ systemd services
- ✅ Frontend build
- ✅ Service startup

---

## 📋 What the Script Does

1. **System Setup** (2 min)
   - Update Ubuntu packages
   - Install Node.js 18+, npm, pnpm

2. **Database Setup** (1 min)
   - Install PostgreSQL 16
   - Create meknow_production database
   - Setup meknow user with permissions

3. **Application Setup** (1 min)
   - Clone from GitHub
   - Install npm dependencies
   - Install pnpm dependencies

4. **Web Server Setup** (1 min)
   - Install Nginx
   - Configure reverse proxy
   - Setup SSL with Let's Encrypt

5. **Services Startup** (30 sec)
   - Create systemd services
   - Start backend (Express.js)
   - Start frontend (Next.js)

---

## 🔍 Verify Deployment

After script completes, check:

```bash
# ✅ Check services
systemctl status meknow-backend
systemctl status meknow-frontend
systemctl status nginx
systemctl status postgresql

# ✅ Check logs
journalctl -u meknow-backend -f   # Follow backend logs
journalctl -u meknow-frontend -f  # Follow frontend logs

# ✅ Test API
curl https://meknow.fr/api/products

# ✅ Browser test
# Open https://meknow.fr in browser
```

---

## 🐛 Troubleshooting

### Backend not responding?
```bash
# Check logs
journalctl -u meknow-backend -n 50

# Restart service
systemctl restart meknow-backend

# Check database
sudo -u postgres psql -d meknow_production -c "SELECT COUNT(*) FROM products_data;"
```

### Frontend not loading?
```bash
# Check logs
journalctl -u meknow-frontend -n 50

# Rebuild frontend
cd /var/www/meknow/menow-web
pnpm run build

# Restart service
systemctl restart meknow-frontend
```

### SSL certificate issues?
```bash
# Check certificate
certbot certificates

# Renew manually
certbot renew --force-renewal

# Check Nginx config
nginx -t

# Reload Nginx
systemctl reload nginx
```

---

## 📊 Post-Deployment Checklist

- [ ] SSH to VPS: `ssh root@31.97.196.215`
- [ ] Run: `bash deploy-vps-production.sh`
- [ ] Wait for completion (~5 minutes)
- [ ] Test: `curl https://meknow.fr/api/products`
- [ ] Browser: Open https://meknow.fr
- [ ] Admin: Check https://meknow.fr/admin
- [ ] Images: Verify product images display
- [ ] Services: `systemctl status meknow-backend meknow-frontend`
- [ ] Logs: Check for errors in journalctl
- [ ] Database: Verify data persists after restart

---

## 🔐 Security Notes

**Environment Variables** are set in:
- Backend: `/var/www/meknow/.env`
- Frontend: `/var/www/meknow/menow-web/.env.local`

**Default values** (change these!):
```env
DB_PASSWORD=meknow_secure_2025    # CHANGE THIS!
NODE_ENV=production
CORS_ORIGIN=https://meknow.fr
```

**SSL Certificate** auto-renews via certbot (timer enabled)

**Firewall** (if enabled):
```bash
# Allow HTTP/HTTPS
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 22/tcp
```

---

## 🚨 Important Files

| File | Purpose | Location |
|------|---------|----------|
| `.env` | Backend config | `/var/www/meknow/.env` |
| `.env.local` | Frontend config | `/var/www/meknow/menow-web/.env.local` |
| Nginx config | Reverse proxy | `/etc/nginx/sites-available/meknow` |
| Backend service | systemd unit | `/etc/systemd/system/meknow-backend.service` |
| Frontend service | systemd unit | `/etc/systemd/system/meknow-frontend.service` |
| Database | PostgreSQL | `meknow_production` database |
| App directory | Source code | `/var/www/meknow` |

---

## 📞 Support Commands

```bash
# Full logs
journalctl -u meknow-backend -u meknow-frontend --no-pager

# Service restart all
systemctl restart meknow-backend meknow-frontend nginx

# Check ports
netstat -tuln | grep -E ":80|:443|:3000|:9000|:5432"

# Database backup
sudo -u postgres pg_dump meknow_production > /backup/meknow_$(date +%Y%m%d).sql

# Check disk space
df -h

# Check memory
free -h

# Monitor services
watch -n 1 'systemctl status meknow-backend meknow-frontend | grep Active'
```

---

## 🎯 Next Steps After Deployment

1. **Test in Production**
   - Verify all products display
   - Test product filtering
   - Check admin interface
   - Test checkout flow (when ready)

2. **Setup Monitoring**
   - Enable log monitoring
   - Setup uptime monitoring
   - Configure alerts

3. **Setup Backups**
   - Daily database backups
   - App file backups
   - Test restore procedure

4. **Performance Tuning**
   - Monitor frontend build times
   - Optimize database queries
   - Setup caching headers

5. **Domain & Email**
   - Setup email for admin
   - Configure contact forms
   - Setup transactional emails

---

## 📞 Questions?

Refer to these documentation files:
- `GUIDE-DEPLOIEMENT-PRODUCTION.md` - Detailed manual steps
- `README-LATEST.md` - Full technical documentation
- `RAPPORT-AVANCEMENT-v1.2.md` - Progress and architecture
- `MODIFICATIONS-TECHNIQUES-v1.2.md` - Technical changes

---

**Version**: 1.0.0  
**Last Updated**: 22 octobre 2025  
**Status**: Ready for Production Deployment ✅
