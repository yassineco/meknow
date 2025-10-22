# 🌐 CONFIGURATION DNS & DOMAINE - MEKNOW

**Date**: 22 octobre 2025  
**Domaine**: meknow.fr  
**VPS IP**: 31.97.196.215

---

## ✅ DNS Configuration Checklist

### Before Deployment

Avant de lancer le script de déploiement, vous devez configurer le DNS de votre domaine.

```
┌─────────────────────────────────────────────────────────────┐
│                    DNS RECORDS TO ADD                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Type   │ Name          │ Value           │ TTL            │
│ --------|---------------|-----------------|--------------- │
│  A      │ meknow.fr     │ 31.97.196.215   │ 3600 (1 hour)  │
│  A      │ www           │ 31.97.196.215   │ 3600 (1 hour)  │
│  CNAME  │ www           │ meknow.fr       │ 3600 (1 hour)  │
│  MX     │ -             │ 10 mail.meknow  │ 3600 (1 hour)  │
│         │               │                 │                │
└─────────────────────────────────────────────────────────────┘
```

### Step 1: Access Your DNS Provider

Login to your domain registrar or DNS provider:
- OVH
- Godaddy
- Namecheap
- Gandi
- etc.

### Step 2: Add A Records

**Record 1: Root Domain**
```
Type:  A
Name:  meknow.fr (or leave empty for @)
Value: 31.97.196.215
TTL:   3600
```

**Record 2: WWW Subdomain**
```
Type:  A
Name:  www.meknow.fr
Value: 31.97.196.215
TTL:   3600
```

### Step 3: Verify DNS Propagation

```bash
# Check DNS resolution (wait 10-30 minutes for propagation)
nslookup meknow.fr
# Expected: 31.97.196.215

nslookup www.meknow.fr
# Expected: 31.97.196.215

# Or use dig
dig meknow.fr
dig www.meknow.fr

# Or use online tool
# https://mxtoolbox.com/
```

---

## 🔒 SSL Certificate Setup

### Automatic (Recommended)

The deployment script will automatically:
1. Install Certbot
2. Request Let's Encrypt certificate
3. Configure Nginx with SSL
4. Setup auto-renewal

**No manual steps needed!** ✅

### Manual Setup (if needed)

```bash
# SSH to VPS
ssh root@31.97.196.215

# Request certificate (after DNS is configured)
certbot certonly --nginx -d meknow.fr -d www.meknow.fr

# Check certificate
certbot certificates

# Force renewal
certbot renew --force-renewal
```

---

## 🔍 Verification Commands

### 1. Check DNS Resolution

```bash
# From your local machine
nslookup meknow.fr
# Should return: 31.97.196.215

dig meknow.fr
# Should show: 31.97.196.215 in the ANSWER section
```

### 2. Check Connectivity

```bash
# Test connection to VPS
ping 31.97.196.215
# Should see responses

# Test HTTP
curl -I http://31.97.196.215
# Should see response before SSL is setup

# Test HTTPS (after SSL setup)
curl -I https://meknow.fr
# Should see 200 OK
```

### 3. Check SSL Certificate

```bash
# On the VPS
certbot certificates
# Should show your meknow.fr certificate

# Check certificate details
openssl s_client -connect meknow.fr:443
# Should show valid certificate
```

### 4. Test All Endpoints

```bash
# After deployment completes
curl https://meknow.fr/api/products
curl https://meknow.fr/admin
curl https://meknow.fr/health
```

---

## 📋 Pre-Deployment Checklist

- [ ] Domain purchased (meknow.fr)
- [ ] DNS provider configured
- [ ] A record added: meknow.fr → 31.97.196.215
- [ ] WWW record added: www.meknow.fr → 31.97.196.215
- [ ] DNS verified with `nslookup meknow.fr`
- [ ] Can ping 31.97.196.215
- [ ] SSH access to VPS confirmed

---

## 🚀 Deployment Ready?

Once all above steps are complete, you can run:

```bash
# SSH to VPS
ssh root@31.97.196.215

# Clone repo and run deployment
cd /var/www
git clone https://github.com/yassineco/meknow.git
cd meknow
bash deploy-vps-production.sh
```

---

## 🐛 DNS Troubleshooting

### DNS not resolving?

```bash
# Check if DNS servers are correct
whois meknow.fr | grep "Name Server"

# Flush DNS cache (on your local machine)
# macOS:
sudo dscacheutil -flushcache

# Linux:
sudo systemctl restart systemd-resolved

# Windows:
ipconfig /flushdns
```

### Wait for DNS propagation

DNS can take 10 minutes to 24 hours to propagate globally.

Check status: https://dnschecker.org/
- Enter: meknow.fr
- Should show 31.97.196.215 everywhere

### Temporary IP verification

If DNS isn't working yet, test directly with IP:

```bash
# Test with IP instead of domain
curl -H "Host: meknow.fr" http://31.97.196.215

# After SSL is setup
curl -k --resolve meknow.fr:443:31.97.196.215 https://meknow.fr
```

---

## 🔐 Email Setup (Optional)

If you want to use meknow.fr email addresses:

### Add MX Record

```
Type:  MX
Name:  meknow.fr
Value: 10 mail.meknow.fr
TTL:   3600
Priority: 10
```

### Add SPF Record

```
Type:  TXT
Name:  meknow.fr
Value: v=spf1 include:_spf.google.com ~all
```

*(Adjust based on your email provider)*

---

## 📞 Common DNS Providers

| Provider | Setup Page | Support |
|----------|-----------|---------|
| OVH | ovh.com/manager | [OVH DNS](https://docs.ovh.com/fr/domains/generalites-serveurs-dns/) |
| Godaddy | godaddy.com/domains | [Godaddy DNS](https://www.godaddy.com/help/edit-dns-records-19236) |
| Namecheap | namecheap.com | [Namecheap DNS](https://www.namecheap.com/support/knowledgebase/article.aspx/319/2237/how-do-i-set-the-domain-nameservers-to-custom-nameservers) |
| Gandi | gandi.net | [Gandi DNS](https://doc.gandi.net/fr/dns/modification) |
| AWS Route53 | aws.amazon.com | [Route53 DNS](https://docs.aws.amazon.com/route53/) |

---

## ✨ Summary

**Order of Steps**:
1. ✅ Buy domain meknow.fr
2. ✅ Configure DNS (A records)
3. ✅ Verify DNS propagation (10-30 min)
4. ✅ SSH to VPS
5. ✅ Run deployment script
6. ✅ Wait for SSL certificate (auto)
7. ✅ Test https://meknow.fr

---

**Status**: Ready for DNS Configuration ✅

**Next**: Once DNS is configured → Run deployment script
