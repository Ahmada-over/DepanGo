#!/usr/bin/env bash
# Quick launcher for Admin Dashboard
cd "$(dirname "$0")"
PORT="${1:-8080}"
echo "🚀 Démarrage du Dashboard Administrateur sur http://localhost:$PORT ..."
python3 -m http.server "$PORT"
