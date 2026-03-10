#!/usr/bin/env bash
set -euo pipefail

# sync-pull.sh — Trae cambios desde GitHub al vault local
# Se ejecuta via cron cada 5 min con flock para evitar concurrencia

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/.env"

VAULT_DIR="${VAULT_DIR:-/opt/vault}"
cd "${VAULT_DIR}"

# Si hay cambios locales sin commitear, skip (sync-push los maneja primero)
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "$(date -Iseconds) [pull] Cambios locales detectados, skipping pull"
    exit 0
fi

# Pull con rebase para evitar merge commits
if git pull --rebase --autostash; then
    echo "$(date -Iseconds) [pull] OK"
else
    echo "$(date -Iseconds) [pull] ERROR: falló git pull" >&2
    exit 1
fi
