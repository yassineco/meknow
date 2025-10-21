#!/bin/bash

# 🌐 Détection IPv4 pour configuration Hostinger DNS
# Usage: ./get-ipv4-hostinger.sh

echo "🌐 DÉTECTION IPv4 POUR HOSTINGER DNS"
echo "=================================="

echo "1. 🔍 Recherche de l'adresse IPv4..."

# Méthodes multiples pour détecter l'IPv4
echo "📡 Tentative de détection IPv4..."

# Méthode 1: Services externes IPv4 uniquement
echo "🌍 Test via services externes IPv4..."
IPV4_1=$(curl -4 -s --connect-timeout 5 ifconfig.me 2>/dev/null || echo "")
IPV4_2=$(wget -qO- -4 --timeout=5 ifconfig.me 2>/dev/null || echo "")
IPV4_3=$(curl -4 -s --connect-timeout 5 ipv4.icanhazip.com 2>/dev/null || echo "")
IPV4_4=$(curl -4 -s --connect-timeout 5 api.ipify.org 2>/dev/null || echo "")

echo "   ifconfig.me (curl): ${IPV4_1:-Non détecté}"
echo "   ifconfig.me (wget): ${IPV4_2:-Non détecté}"  
echo "   icanhazip.com: ${IPV4_3:-Non détecté}"
echo "   ipify.org: ${IPV4_4:-Non détecté}"

# Méthode 2: Interfaces réseau locales
echo ""
echo "🔌 Vérification des interfaces réseau..."
IPV4_LOCAL=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -1)
echo "   Interface locale: ${IPV4_LOCAL:-Non détecté}"

# Méthode 3: hostname -I
IPV4_HOSTNAME=$(hostname -I 2>/dev/null | tr ' ' '\n' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | head -1)
echo "   Hostname -I: ${IPV4_HOSTNAME:-Non détecté}"

echo ""
echo "2. 📋 RÉSULTATS DE DÉTECTION IPv4..."

# Choisir la meilleure IPv4 détectée
FINAL_IPV4=""
for ip in "$IPV4_1" "$IPV4_2" "$IPV4_3" "$IPV4_4" "$IPV4_LOCAL" "$IPV4_HOSTNAME"; do
    if [[ -n "$ip" && "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        FINAL_IPV4="$ip"
        break
    fi
done

if [ -n "$FINAL_IPV4" ]; then
    echo "✅ IPv4 détectée: $FINAL_IPV4"
    
    echo ""
    echo "3. 🎯 CONFIGURATION HOSTINGER DNS..."
    echo ""
    echo "Dans votre panel Hostinger DNS, ajoutez :"
    echo ""
    echo "┌────────────────────────────────────────┐"
    echo "│  ENREGISTREMENT DNS #1                 │"
    echo "│  Type: A                               │"
    echo "│  Nom: @ (ou meknow.fr)                 │"
    echo "│  Contenu: $FINAL_IPV4                  │"
    echo "│  TTL: 300                              │"
    echo "└────────────────────────────────────────┘"
    echo ""
    echo "┌────────────────────────────────────────┐"
    echo "│  ENREGISTREMENT DNS #2                 │"
    echo "│  Type: A                               │"
    echo "│  Nom: www                              │"
    echo "│  Contenu: $FINAL_IPV4                  │"
    echo "│  TTL: 300                              │"
    echo "└────────────────────────────────────────┘"
    
    echo ""
    echo "4. ⚡ TESTS IMMÉDIATS..."
    echo ""
    echo "🔍 Test de votre site maintenant :"
    echo "   http://$FINAL_IPV4:3001"
    echo ""
    
    # Test de connectivité
    echo "🌐 Test de connectivité IPv4..."
    if curl -4 -s --connect-timeout 5 "http://$FINAL_IPV4:3001" >/dev/null 2>&1; then
        echo "✅ Site accessible via IPv4 !"
    else
        echo "⚠️ Site pas encore accessible via IPv4 (normal si pas configuré)"
    fi
    
    echo ""
    echo "5. 📝 PROCHAINES ÉTAPES..."
    echo ""
    echo "1. ✅ Copiez l'IPv4: $FINAL_IPV4"
    echo "2. 🌐 Ajoutez les DNS dans Hostinger (voir ci-dessus)"
    echo "3. ⏱️ Attendez 5-60 minutes (propagation DNS)"
    echo "4. 🚀 Testez https://meknow.fr"
    echo ""
    
    # Créer un script de test
    cat > test-dns.sh << EOL
#!/bin/bash
echo "🔍 Test DNS meknow.fr..."
nslookup meknow.fr
echo ""
echo "🌐 Test site meknow.fr..."
curl -I http://meknow.fr
EOL
    chmod +x test-dns.sh
    echo "📄 Script de test créé: ./test-dns.sh"
    
else
    echo "❌ AUCUNE IPv4 DÉTECTÉE !"
    echo ""
    echo "🚨 PROBLÈMES POSSIBLES :"
    echo "   - Votre VPS n'a peut-être qu'IPv6"
    echo "   - Firewall bloque les connexions sortantes"
    echo "   - Configuration réseau spéciale"
    echo ""
    echo "💡 SOLUTIONS ALTERNATIVES :"
    echo "   1. Contactez votre hébergeur VPS"
    echo "   2. Vérifiez la configuration réseau"
    echo "   3. Utilisez un tunnel IPv4 (comme CloudFlare)"
    echo ""
    echo "📞 Commandes de diagnostic :"
    echo "   ip addr show"
    echo "   route -n"
    echo "   cat /etc/network/interfaces"
fi

echo ""
echo "🎯 IPv6 actuelle détectée: 2a02:4780:28:448f::1"
echo "🎯 IPv4 nécessaire pour Hostinger: $FINAL_IPV4"