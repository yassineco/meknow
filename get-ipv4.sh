#!/bin/bash
# get-ipv4.sh - Récupération IP v4 du serveur

echo "🔍 RÉCUPÉRATION IP v4"
echo "====================="

echo "🌐 Tentative 1 - ipv4.icanhazip.com:"
IPV4_1=$(curl -s -4 ipv4.icanhazip.com 2>/dev/null)
echo "Résultat: $IPV4_1"

echo ""
echo "🌐 Tentative 2 - ipinfo.io/ip:"
IPV4_2=$(curl -s -4 ipinfo.io/ip 2>/dev/null)
echo "Résultat: $IPV4_2"

echo ""
echo "🌐 Tentative 3 - api.ipify.org:"
IPV4_3=$(curl -s -4 api.ipify.org 2>/dev/null)
echo "Résultat: $IPV4_3"

echo ""
echo "🌐 Tentative 4 - checkip.amazonaws.com:"
IPV4_4=$(curl -s -4 checkip.amazonaws.com 2>/dev/null)
echo "Résultat: $IPV4_4"

echo ""
echo "📋 Informations réseau complètes:"
ip addr show | grep -E "inet " | grep -v "127.0.0.1"

echo ""
echo "🔧 Configuration réseau interface:"
ip route get 8.8.8.8 | grep -oP 'src \K\S+' 2>/dev/null || echo "Pas d'IP source trouvée"

# Test de l'IP la plus probable
if [[ $IPV4_1 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    BEST_IP=$IPV4_1
elif [[ $IPV4_2 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    BEST_IP=$IPV4_2
elif [[ $IPV4_3 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    BEST_IP=$IPV4_3
elif [[ $IPV4_4 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    BEST_IP=$IPV4_4
else
    BEST_IP="NON TROUVÉE"
fi

echo ""
echo "🎯 RÉSULTAT FINAL:"
echo "=================="
if [[ $BEST_IP != "NON TROUVÉE" ]]; then
    echo "✅ IP v4 trouvée: $BEST_IP"
    echo ""
    echo "📝 À SAISIR DANS HOSTINGER:"
    echo "   Type: A"
    echo "   Nom: @"
    echo "   Pointe vers: $BEST_IP"
    echo ""
    echo "   Type: A" 
    echo "   Nom: www"
    echo "   Pointe vers: $BEST_IP"
else
    echo "❌ Aucune IP v4 trouvée"
    echo "🔧 Votre serveur utilise peut-être uniquement IPv6"
    echo "💡 Solutions:"
    echo "   1. Contactez votre hébergeur VPS pour une IP v4"
    echo "   2. Utilisez un service comme Cloudflare (gratuit)"
    echo "   3. Configurez un tunnel IPv4/IPv6"
fi

echo ""
echo "🧪 Test de connectivité IPv4:"
if [[ $BEST_IP != "NON TROUVÉE" ]]; then
    curl -s -4 -o /dev/null -w "Status IPv4: %{http_code}\n" "http://$BEST_IP" 2>/dev/null || echo "Status IPv4: Non accessible"
fi