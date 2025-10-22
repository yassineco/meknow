# ✅ Checklist Pré-Migration : Docker → Natif

## 📋 Avant de commencer la migration

### 1. Préparation système VPS
- [ ] Connexion SSH au VPS vérifiée
- [ ] Espace disque disponible ≥ 2GB : `df -h`
- [ ] Utilisateur root/sudo disponible
- [ ] Node.js 18+ installé : `node --version`
- [ ] npm ou pnpm disponible : `npm --version`
- [ ] Git installé : `git --version`
- [ ] PostgreSQL 12+ en cours d'exécution : `sudo systemctl status postgresql`

### 2. Données et backups
- [ ] Base de données PostgreSQL sauvegardée
  ```bash
  sudo -u postgres pg_dump meknow_production > /root/backups/meknow_pre_migration_$(date +%Y%m%d_%H%M%S).sql
  ```
- [ ] Fichiers .env sauvegardés
  ```bash
  mkdir -p /root/backups
  cp /var/www/meknow/.env /root/backups/.env.backup
  cp /var/www/meknow/menow-web/.env.local /root/backups/.env.local.backup
  ```
- [ ] Uploads/assets sauvegardés (si applicable)
- [ ] Liste des variables d'environnement vérifiée

### 3. Code et Git
- [ ] Branche Git à jour : `git status`
- [ ] Tous les changements committé : `git log --oneline -5`
- [ ] Accès GitHub vérifié
- [ ] SSH key GitHub configurée

### 4. Vérification Docker actuel
- [ ] Services Docker actifs : `docker ps`
- [ ] Volumes Docker listés : `docker volume ls`
- [ ] Images Docker listées : `docker images`
- [ ] Espace utilisé par Docker : `docker system df`
- [ ] Configuration docker-compose.yml sauvegardée
- [ ] Logs Docker récents vérifiés

### 5. Configuration Nginx (si utilisé)
- [ ] Configuration Nginx sauvegardée
  ```bash
  cp /etc/nginx/sites-available/meknow /root/backups/nginx.meknow.backup
  ```
- [ ] Certificats SSL sauvegardés (si applicable)
  ```bash
  sudo cp -r /etc/letsencrypt/live/yourdomain.com /root/backups/ssl.backup
  ```
- [ ] Logs Nginx vérifiés pour erreurs

### 6. PM2 (si utilisé anciennement)
- [ ] Processus PM2 arrêtés : `pm2 list`
- [ ] Configuration ecosystem.config.js sauvegardée

### 7. Planification du downtime
- [ ] Fenêtre de maintenance annoncée aux utilisateurs
- [ ] Durée estimée : 15-20 minutes
- [ ] Point de contact identifié en cas de problème
- [ ] Horaire choisi (préférer heures creuses)

### 8. Tests de préparation
- [ ] Scripts de migration vérifiés localement
- [ ] Permissions des fichiers vérifiées : `ls -la migrate-docker-to-native.sh`
- [ ] Plan de rollback préparé
- [ ] Contact support prêt

## 🔄 Jour de la migration

### Phase 1 : Avant (T-5 min)
- [ ] Dernier backup effectué
- [ ] Services Docker stoppés (optionnel, le script le fait)
- [ ] Pas d'utilisateurs actifs sur le site
- [ ] Terminal SSH prêt

### Phase 2 : Migration (T-0)
- [ ] Exécuter le script de migration
  ```bash
  cd /var/www/meknow
  sudo bash migrate-docker-to-native.sh
  ```
- [ ] Surveiller la sortie du script
- [ ] Ne pas arrêter le script prématurément

### Phase 3 : Vérification (T+5 min)
- [ ] Services systemd actifs
  ```bash
  sudo systemctl status meknow-api meknow-web
  ```
- [ ] API répond : `curl http://localhost:9000/api/products`
- [ ] Frontend accessible : `curl http://localhost:3000`
- [ ] Pas d'erreurs dans les logs : `sudo journalctl -u meknow-api -n 20`
- [ ] Base de données fonctionnelle
- [ ] Images chargent correctement

### Phase 4 : Post-migration (T+10 min)
- [ ] Services configurés en auto-start
- [ ] Test complet du site via navigateur
- [ ] Admin panel testé
- [ ] Authentification vérifiée
- [ ] Panier fonctionne correctement
- [ ] Endpoints API fonctionnent

## 🚨 Rollback (Si problème)

### Signe d'alerte
- [ ] Services ne démarrent pas
- [ ] API ne répond pas après 2 min
- [ ] Erreurs de connexion base de données
- [ ] Pages frontend blanches/erreurs 500
- [ ] Logs remplis d'erreurs critiques

### Procédure rollback
```bash
# 1. Arrêter les services natifs
sudo systemctl stop meknow-api meknow-web

# 2. Activer Docker
cd /var/www/meknow
docker-compose up -d

# 3. Vérifier
docker ps
curl http://localhost:9000/api/products

# 4. Restaurer la configuration Nginx
sudo systemctl reload nginx
```

## 📊 Points de monitoring post-migration

### Tous les jours (1ère semaine)
- [ ] Services au démarrage
- [ ] Utilisation mémoire/CPU
- [ ] Logs pour erreurs
- [ ] Temps réponse API

### Hebdomadaire
- [ ] Taille base de données
- [ ] Sauvegardes actives
- [ ] Certificats SSL (expiration)
- [ ] Performance générale

### Mensuel
- [ ] Logs archivés
- [ ] Mises à jour de sécurité
- [ ] Espace disque
- [ ] Rapports de performance

## 📞 Contacts d'urgence

| Problème | Action |
|----------|--------|
| API ne démarre pas | `sudo journalctl -u meknow-api -n 50` |
| Port occupé | `sudo lsof -i :9000` + `kill -9 PID` |
| Accès BD | `psql -U meknow_user -d meknow_production` |
| Permissions | `sudo chown -R www-data:www-data /var/www/meknow` |
| Logs | `sudo journalctl -u meknow-api -f` |

## ✅ Signature d'approbation

- **Responsable** : _______________
- **Date** : _______________
- **Heure de début** : _______________
- **Heure de fin** : _______________
- **Statut** : ☐ Succès ☐ Rollback effectué

---

**Gardez ce document pour toute future migration ou incident!**
