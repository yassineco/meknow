# 📋 PRE-DEPLOYMENT CHECKLIST - MEKNOW

**Date**: 22 octobre 2025  
**Status**: Ready for Production

---

## ✅ LOCAL VERIFICATION (Before pushing)

### Code Quality
- [x] All files committed and pushed
- [x] No uncommitted changes
- [x] Git history clean
- [x] Branch: frontend-sync-complete

### Backend
- [x] Express.js server (backend-minimal.js)
- [x] PostgreSQL connection working
- [x] API endpoints tested (/products, /admin, etc.)
- [x] CORS configured
- [x] Error handling implemented
- [x] Database persistence working (5+ restarts tested)
- [x] Image serving working (/images/*)

### Frontend
- [x] Next.js 14 building without errors
- [x] No SVG rendering errors
- [x] CSS imports correct (@import './theme.css')
- [x] Image URLs using backend proxy (getImageUrl)
- [x] All products displaying in Lookbook
- [x] Admin interface loading
- [x] No console errors on page load
- [x] Responsive design working

### Database
- [x] PostgreSQL running
- [x] Database created (meknow_production)
- [x] Schema initialized (products_data table)
- [x] 6 products in database
- [x] JSONB versioning implemented
- [x] Version 17 current with 4 lookbook products

### Environment
- [x] .env file configured
- [x] .env.local configured
- [x] API URL pointing to localhost:9000
- [x] NEXT_PUBLIC_* variables set

### Services
- [x] Backend running on port 9000
- [x] Frontend running on port 3000
- [x] PostgreSQL running on port 5432
- [x] Ports not conflicting

---

## 🌐 DOMAIN & DNS READY?

- [ ] Domain purchased (meknow.fr)
- [ ] Registrar/DNS provider accessed
- [ ] A record configured: meknow.fr → 31.97.196.215
- [ ] A record configured: www.meknow.fr → 31.97.196.215
- [ ] DNS propagation verified (nslookup works)
- [ ] Can ping 31.97.196.215 successfully

**Timeline**: DNS takes 10-30 minutes to propagate globally

---

## 🖥️ VPS PREPARATION

### Access
- [ ] VPS IP: 31.97.196.215
- [ ] Root SSH access available
- [ ] Can connect: `ssh root@31.97.196.215`

### System
- [ ] OS: Ubuntu 24.04 LTS
- [ ] SSH key setup (if using key-based auth)
- [ ] Root password secure
- [ ] Firewall allowing SSH (port 22)

### Requirements
- [ ] Minimum 2 GB RAM
- [ ] Minimum 20 GB storage
- [ ] Internet connectivity
- [ ] Port 22 (SSH) open
- [ ] Port 80 (HTTP) open
- [ ] Port 443 (HTTPS) open

---

## 📦 DEPLOYMENT SCRIPT

### Files Ready
- [x] deploy-vps-production.sh created
- [x] Script executable (chmod +x)
- [x] Script includes all 17 steps
- [x] VPS-DEPLOYMENT-QUICK-START.md created
- [x] DNS-DOMAIN-SETUP.md created

### Script Coverage
- [x] System updates
- [x] Node.js 18+ installation
- [x] PostgreSQL setup with database
- [x] Nginx installation
- [x] Certbot/Let's Encrypt setup
- [x] Repository cloning
- [x] Dependency installation
- [x] Environment files creation
- [x] Systemd services creation
- [x] Frontend build
- [x] Nginx reverse proxy config
- [x] SSL certificate setup
- [x] Permissions fixing
- [x] Service startup
- [x] Verification tests
- [x] Summary output

---

## 🚀 DEPLOYMENT STEPS

### 1. DNS Configuration (10 minutes)
```
[ ] Configure DNS records pointing to 31.97.196.215
[ ] Wait for DNS to propagate
[ ] Verify: nslookup meknow.fr
[ ] Should return: 31.97.196.215
```

### 2. Connect to VPS (1 minute)
```bash
ssh root@31.97.196.215
```
- [ ] Can connect without issues
- [ ] Prompt shows `root@...`
- [ ] No permission errors

### 3. Clone Repository (1 minute)
```bash
cd /var/www
git clone https://github.com/yassineco/meknow.git
cd meknow
```
- [ ] Clone successful
- [ ] Files present
- [ ] .git directory exists

### 4. Run Deployment Script (5-10 minutes)
```bash
bash deploy-vps-production.sh
```
- [ ] Script starts without errors
- [ ] Each step completes (1-17)
- [ ] No critical failures reported

### 5. Verify Services (2 minutes)
```bash
systemctl status meknow-backend
systemctl status meknow-frontend
systemctl status nginx
```
- [ ] Backend: `active (running)`
- [ ] Frontend: `active (running)`
- [ ] Nginx: `active (running)`

### 6. Test API (1 minute)
```bash
curl https://meknow.fr/api/products
```
- [ ] Returns 200 OK
- [ ] JSON response with products
- [ ] No 404 or 500 errors

### 7. Browser Test (2 minutes)
```
[ ] Open https://meknow.fr
[ ] Page loads
[ ] Products display
[ ] No console errors
[ ] Admin accessible at /admin
```

---

## 🔍 POST-DEPLOYMENT VERIFICATION

### Frontend
- [ ] Page title correct
- [ ] Header displays (logo, cart)
- [ ] Products section visible
- [ ] Product images show
- [ ] Lookbook section has 4 products with images
- [ ] No styling issues
- [ ] Mobile responsive (check DevTools)

### Backend API
- [ ] `/api/products` returns all products
- [ ] `/api/products/lookbook` returns 4 lookbook items
- [ ] `/images/test.jpg` serves image (200)
- [ ] `/admin` returns HTML interface
- [ ] `/health` returns "healthy"

### Database
- [ ] PostgreSQL running: `systemctl status postgresql`
- [ ] Database exists: `sudo -u postgres psql -l | grep meknow`
- [ ] Tables created: `sudo -u postgres psql -d meknow_production -dt`
- [ ] Data present: `SELECT COUNT(*) FROM products_data;`

### SSL/HTTPS
- [ ] https://meknow.fr loads (no certificate warning)
- [ ] Certificate valid: `certbot certificates`
- [ ] Renews automatically: `systemctl status certbot.timer`

### Services Auto-Restart
- [ ] Kill backend: `systemctl stop meknow-backend`
- [ ] Verify auto-restart: `systemctl status meknow-backend`
- [ ] Kill frontend: `systemctl stop meknow-frontend`
- [ ] Verify auto-restart: `systemctl status meknow-frontend`

---

## 📊 EXPECTED RESULTS

### Performance
- Frontend loads in < 3 seconds
- API responds in < 500ms
- Images display without delay

### Functionality
- All products visible (6 total)
- Lookbook section shows 4 products
- Admin interface fully functional
- Can filter/search products (if implemented)

### Security
- HTTPS/SSL working
- Security headers present
- No mixed content warnings
- Database credentials secure

### Data
- Products persist across restarts
- Database backups accessible
- Logs available in journalctl

---

## 🆘 TROUBLESHOOTING QUICK LINKS

| Issue | Solution |
|-------|----------|
| DNS not resolving | Wait 30 min, use dnschecker.org |
| Can't SSH to VPS | Check IP, firewall, SSH key permissions |
| Services not starting | Check logs: `journalctl -u meknow-backend -n 50` |
| API returning 404 | Backend might not be running: `systemctl restart meknow-backend` |
| Frontend blank page | Check browser console, frontend logs |
| Images not loading | Check backend at :9000, image paths |
| SSL certificate errors | Verify DNS propagated, run `certbot certificates` |
| Database connection errors | Check DB credentials in .env file |

---

## 📋 SIGN-OFF

**Performed by**: _________________  
**Date**: _________________  
**Time**: _________________  

**All checks passed**: ☐ YES ☐ NO

**Notes/Issues**: 
```
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```

**Approved for Production**: ☐ YES ☐ NO

---

## 🎯 DEPLOYMENT COMPLETE!

Once all items are checked, the deployment is **production-ready** ✅

**Access Points**:
- Frontend: https://meknow.fr
- API: https://meknow.fr/api
- Admin: https://meknow.fr/admin

**Monitoring**:
- Backend logs: `journalctl -u meknow-backend -f`
- Frontend logs: `journalctl -u meknow-frontend -f`
- Database: `sudo -u postgres psql -d meknow_production`

**Support Files**:
- See `GUIDE-DEPLOIEMENT-PRODUCTION.md` for manual steps
- See `VPS-DEPLOYMENT-QUICK-START.md` for quick reference
- See `DNS-DOMAIN-SETUP.md` for domain configuration

---

**Version**: 1.0.0  
**Last Updated**: 22 octobre 2025  
**Status**: Ready for Production Deployment ✅
