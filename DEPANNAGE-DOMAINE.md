# 🚨 DÉPANNAGE URGENT - Site inaccessible sur meknow.fr

## 📊 DIAGNOSTIC DU PROBLÈME

Vous voyez "Ce site est inaccessible" car :
❌ **Le domaine meknow.fr** n'est pas encore configuré
✅ **Les services Docker fonctionnent** sur les ports 3001, 9001, 8082

## 🚀 SOLUTIONS IMMÉDIATES

### 🥇 **SOLUTION RAPIDE - Testez avec l'IP directement**

**Au lieu de `meknow.fr`, utilisez :**

1. **Trouvez votre IP serveur :**
   ```bash
   curl ifconfig.me
   ```

2. **Testez ces URLs dans votre navigateur :**
   - `http://VOTRE_IP:3001` → Site e-commerce 
   - `http://VOTRE_IP:9001/health` → API backend
   - `http://VOTRE_IP:8082` → Interface admin

### 🥈 **SOLUTION COMPLÈTE - Configuration du domaine**

**Sur votre VPS, exécutez :**

```bash
# Télécharger et lancer le script de configuration domaine
curl -L https://raw.githubusercontent.com/yassineco/meknow/main/configure-domain.sh -o configure-domain.sh
chmod +x configure-domain.sh
./configure-domain.sh
```

## 🌍 CONFIGURATION DNS NÉCESSAIRE

Pour que `meknow.fr` fonctionne, vous devez :

### 1. **Chez votre registrar de domaine (OVH, Gandi, etc.) :**

Créez ces enregistrements DNS :
```
Type: A
Nom: meknow.fr
Valeur: VOTRE_IP_SERVEUR

Type: A  
Nom: www.meknow.fr
Valeur: VOTRE_IP_SERVEUR
```

### 2. **Attendez la propagation DNS** (1-24h)

### 3. **Vérifiez la propagation :**
```bash
nslookup meknow.fr
# Doit retourner votre IP serveur
```

## 🔧 TESTS DE VÉRIFICATION

### **Test 1 : Services locaux**
```bash
curl http://localhost:3001    # Frontend
curl http://localhost:9001/health    # Backend
curl http://localhost:8082    # Admin
```

### **Test 2 : Accès externe par IP**
```bash
curl http://VOTRE_IP:3001     # Depuis l'extérieur
```

### **Test 3 : DNS du domaine**
```bash
nslookup meknow.fr           # Vérifier DNS
ping meknow.fr               # Test connectivité
```

## 🎯 SOLUTIONS PAR ORDRE DE PRIORITÉ

### ⚡ **IMMÉDIAT (0-5 min)**
Utilisez `http://VOTRE_IP:3001` pour tester votre site **maintenant**

### 🔧 **COURT TERME (10-30 min)**
Configurez Nginx avec le script `configure-domain.sh`

### 🌐 **MOYEN TERME (1-24h)**
Configurez les DNS chez votre registrar de domaine

### 🔒 **LONG TERME (après DNS)**
Installez SSL avec certbot pour HTTPS

## 🚨 VÉRIFICATIONS CRITIQUES

1. **Votre domaine meknow.fr est-il bien acheté ?**
2. **Avez-vous accès à la configuration DNS ?**
3. **Connaissez-vous l'IP de votre serveur ?**

**Pour connaître votre IP serveur :**
```bash
# Sur votre VPS
curl ifconfig.me
# ou
wget -qO- ifconfig.me
```

## 📞 SUPPORT RAPIDE

**Si ça ne marche toujours pas :**

1. **Vérifiez les services :**
   ```bash
   docker-compose ps
   ```

2. **Testez l'accès direct :**
   ```bash
   curl http://localhost:3001
   ```

3. **Vérifiez les logs :**
   ```bash
   docker-compose logs frontend
   ```

## 🎊 RÉSUMÉ

- ✅ **Vos services fonctionnent** (Docker OK)
- ❌ **Le domaine n'est pas configuré** 
- ⚡ **Testez avec l'IP directement** en attendant
- 🌐 **Configurez DNS** pour le domaine définitif

**Votre site marche, il faut juste l'atteindre par la bonne URL !** 🎯