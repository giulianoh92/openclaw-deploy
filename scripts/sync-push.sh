#!/usr/bin/env bash
set -euo pipefail

# sync-push.sh — Commitea y pushea cambios hechos por OpenClaw
# Se ejecuta via cron cada 2 min con flock para evitar concurrencia

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/.env"

VAULT_DIR="${VAULT_DIR:-/opt/vault}"
cd "${VAULT_DIR}"

# Stage todo
git add --all

# Si no hay cambios staged, no-op
if git diff --cached --quiet; then
    exit 0
fi

TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"
git commit -m "vault sync: ${TIMESTAMP}"
git push

echo "$(date -Iseconds) [push] Cambios pusheados"
