#!/bin/bash

# Script pour mettre à jour l'URL de base de l'API dans tout le projet (Web + Mobile)

NEW_URL=$1

if [ -z "$NEW_URL" ]; then
  echo "❌ Erreur : Veuillez fournir la nouvelle URL de l'API."
  echo "Exemple d'utilisation :"
  echo "  ./update_api_url.sh http://192.168.1.50:8000"
  echo "  ./update_api_url.sh http://127.0.0.1:8000"
  exit 1
fi

# Remplacer http par ws pour les WebSockets
WS_URL=${NEW_URL/http/ws}

echo "🔄 Mise à jour de l'API vers : $NEW_URL"
echo "🔄 Mise à jour des WebSockets vers : $WS_URL"

# 1. Mise à jour Web Pro (Vue 3)
cat <<EOF > web_pro/src/config.js
export const API_BASE = '${NEW_URL}/api/v1';
export const WS_BASE = '${WS_URL}/ws';
EOF
echo "✅ Configuration Web Pro mise à jour (web_pro/src/config.js)"

# 2. Mise à jour Mobile Client (Flutter)
mkdir -p mobile_client/lib/core
cat <<EOF > mobile_client/lib/core/config.dart
class AppConfig {
  static const String apiBaseUrl = '${NEW_URL}/api/v1';
  static const String wsBaseUrl = '${WS_URL}/ws';
}
EOF
echo "✅ Configuration Mobile mise à jour (mobile_client/lib/core/config.dart)"

echo "🎉 Succès ! Le projet entier pointera désormais vers $NEW_URL."
