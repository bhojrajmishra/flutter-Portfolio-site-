#!/usr/bin/env bash
# Deploys the portfolio to alwaysdata: builds both backend and frontend,
# strips unused Flutter web assets (this account's disk quota is small),
# uploads via tar+scp (much faster than copying hundreds of files one by
# one), and reminds you to restart the Node site.
#
# Usage (from the repo root): ./deploy/alwaysdata_deploy.sh
# Requires: the SSH key below already installed on the account (see
# ALWAYSDATA.md "SSH key" section) and `tar`/`scp` on your machine (already
# present in Git Bash on Windows, or any Linux/macOS shell).

set -euo pipefail

# ---- Configuration for this account ----
SSH_KEY="$HOME/.ssh/alwaysdata_portfolio"
SSH_HOST="bhojrajmishra@ssh-bhojrajmishra.alwaysdata.net"
REMOTE_DIR="/home/bhojrajmishra/portfolio"
SSH="ssh -i $SSH_KEY -o IdentitiesOnly=yes $SSH_HOST"
SCP="scp -i $SSH_KEY -o IdentitiesOnly=yes"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
# -----------------------------------------

echo "==> Building backend"
(cd backend && npm run build)

echo "==> Packaging backend (dist + sql, no node_modules/.env/uploads)"
tar -C backend -czf "$TMP/backend.tar.gz" dist sql

echo "==> Uploading backend"
$SCP "$TMP/backend.tar.gz" "$SSH_HOST:$REMOTE_DIR/backend/backend.tar.gz"
$SSH "cd $REMOTE_DIR/backend && rm -rf dist sql && tar xzf backend.tar.gz && rm backend.tar.gz"

echo "==> Syncing backend package.json/package-lock.json + reinstalling prod deps"
$SCP backend/package.json backend/package-lock.json "$SSH_HOST:$REMOTE_DIR/backend/"
$SSH "cd $REMOTE_DIR/backend && rm -rf node_modules && npm ci --omit=dev --no-audit --no-fund"

echo "==> Building frontend (release)"
(cd frontend && flutter build web --release)

echo "==> Stripping unused CanvasKit renderer variants + debug symbol maps"
CK="frontend/build/web/canvaskit"
rm -f "$CK"/skwasm*.{wasm,js} "$CK"/skwasm*.js.symbols \
      "$CK"/wimp.{wasm,js} "$CK"/wimp.js.symbols \
      "$CK"/canvaskit.js.symbols "$CK"/chromium/canvaskit.js.symbols
rm -rf "$CK/experimental_webparagraph"

echo "==> Packaging + uploading frontend"
tar -C frontend/build/web -czf "$TMP/frontend.tar.gz" .
$SSH "rm -rf $REMOTE_DIR/frontend/* && echo cleared"
$SCP "$TMP/frontend.tar.gz" "$SSH_HOST:$REMOTE_DIR/frontend.tar.gz"
$SSH "cd $REMOTE_DIR/frontend && tar xzf ../frontend.tar.gz && rm ../frontend.tar.gz"

echo "==> Done."
echo "Frontend is live immediately (static files)."
echo "If you changed any backend code, restart it manually:"
echo "  admin.alwaysdata.com -> Web -> Sites -> the Node.js /api site -> Restart"
echo "If you added new tables/columns, apply them first:"
echo "  ssh -i $SSH_KEY -o IdentitiesOnly=yes $SSH_HOST \"mysql -h mysql-bhojrajmishra.alwaysdata.net -u bhojrajmishra_portfolio -p'<password>' bhojrajmishra_portfolio\" < backend/sql/schema.sql"
echo "Then verify: https://bhojrajmishra.com.np"
