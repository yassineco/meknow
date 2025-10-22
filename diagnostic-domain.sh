#!/bin/bash
echo "🔍 DIAGNOSTIC COMPLET DOMAINE MEKNOW.FR"
echo "========================================"
echo

echo "1. 🌐 Test DNS:"
echo "nslookup meknow.fr:"
nslookup meknow.fr
echo

echo "2. 🔗 Test connexion directe IP:"
echo "curl -I http://31.97.196.215/ :"
timeout 10 curl -I http://31.97.196.215/ 2>&1 | head -5
echo

echo "3. 🌍 Test connexion domaine:"
echo "curl -I http://meknow.fr/ :"
timeout 10 curl -I http://meknow.fr/ 2>&1 | head -5
echo

echo "4. 📡 Test avec différents DNS:"
echo "Test avec DNS 8.8.8.8:"
nslookup meknow.fr 8.8.8.8
echo

echo "5. 🔍 Trace route vers le domaine:"
echo "traceroute meknow.fr (premières étapes):"
timeout 10 traceroute meknow.fr 2>&1 | head -5
echo

echo "6. 🧪 Test avec wget:"
echo "wget --spider http://meknow.fr/ :"
timeout 10 wget --spider http://meknow.fr/ 2>&1 | head -3
echo

echo "7. 💻 Informations système:"
echo "OS: $(uname -a)"
echo "Date: $(date)"
echo

echo "📊 RÉSULTATS:"
echo "- Si l'IP fonctionne mais pas le domaine = problème DNS/réseau"
echo "- Si rien ne fonctionne = problème de connectivité"
echo "- Si tout fonctionne = problème de cache navigateur"
