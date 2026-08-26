#!/usr/bin/env bash
# Deploys the portfolio to a traditional VPS (root/sudo access, PM2, Nginx
# you control): builds the Flutter web release locally, syncs both frontend
# build and backend source to the server, installs backend deps, and
# restarts the API under PM2. Run from the repo root: ./deploy/deploy.sh
#
# NOTE: this script targets a plain VPS. If you're deploying to shared/PaaS
# hosting (e.g. alwaysdata) where you don't control Nginx/PM2 directly, see
# deploy/ALWAYSDATA.md instead — the app/database code is identical, only
# the hosting mechanics differ.
#
# Requires: an SSH key already authorized on the VPS, and the variables
# below filled in for your setup. The database schema (sql/schema.sql) must
# already be applied once — see DEPLOY.md step 2.

set -euo pipefail

# ---- Configure these for your VPS ----
VPS_USER="deploy"                     # SSH user on the VPS
VPS_HOST="your.server.ip.or.host"     # VPS IP or hostname
VPS_APP_DIR="/var/www/portfolio"      # matches nginx.conf / ecosystem.config.js
API_BASE_URL="/api"                   # relative -> same-origin via Nginx in prod
# ---------------------------------------

echo "==> Building Flutter web (release)"
(cd frontend && flutter build web --release --dart-define=API_BASE_URL="$API_BASE_URL")

echo "==> Building backend (TypeScript)"
(cd backend && npm ci && npm run build)

echo "==> Syncing frontend build to $VPS_HOST"
rsync -az --delete frontend/build/web/ "$VPS_USER@$VPS_HOST:$VPS_APP_DIR/frontend/"

echo "==> Syncing backend to $VPS_HOST (excluding node_modules, .env, uploads)"
rsync -az --delete \
  --exclude 'node_modules' \
  --exclude '.env' \
  --exclude 'uploads' \
  backend/ "$VPS_USER@$VPS_HOST:$VPS_APP_DIR/backend/"

echo "==> Installing backend deps, restarting API"
# shellcheck disable=SC2087
ssh "$VPS_USER@$VPS_HOST" bash -s <<EOF
  set -euo pipefail
  cd "$VPS_APP_DIR/backend"
  npm ci --omit=dev
  pm2 startOrReload "$VPS_APP_DIR/deploy/ecosystem.config.js" || pm2 restart portfolio-api
EOF

echo "==> Done. Visit https://yourdomain.com to verify."
