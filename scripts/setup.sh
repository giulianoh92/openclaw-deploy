#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# setup.sh — Provisión inicial de la VPS para OpenClaw
# Ejecutar una sola vez con: sudo bash setup.sh
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"

# Cargar .env si existe (para VAULT_REPO y VAULT_DIR)
if [ -f "${ENV_FILE}" ]; then
    # shellcheck source=/dev/null
    source "${ENV_FILE}"
fi

VAULT_REPO="${VAULT_REPO:?ERROR: Definir VAULT_REPO en .env (ej: git@github.com:user/my-vault.git)}"
VAULT_DIR="${VAULT_DIR:-/opt/vault}"

echo "==> Instalando Docker..."
if ! command -v docker &>/dev/null; then
    curl -fsSL https://get.docker.com | sh
    usermod -aG docker "${SUDO_USER:-$USER}"
else
    echo "    Docker ya está instalado."
fi

echo "==> Instalando Git..."
apt-get update -qq && apt-get install -y -qq git

echo "==> Clonando vault en ${VAULT_DIR}..."
if [ ! -d "${VAULT_DIR}/.git" ]; then
    git clone "${VAULT_REPO}" "${VAULT_DIR}"
else
    echo "    El vault ya está clonado."
fi

echo "==> Configurando git user para el bot..."
git -C "${VAULT_DIR}" config user.name "${GIT_USER_NAME:-OpenClaw Bot}"
git -C "${VAULT_DIR}" config user.email "${GIT_USER_EMAIL:-bot@vault.local}"

echo "==> Instalando cron jobs..."
CRON_PULL="*/5 * * * * /usr/bin/flock -n /tmp/vault-pull.lock ${SCRIPT_DIR}/scripts/sync-pull.sh >> /var/log/vault-sync.log 2>&1"
CRON_PUSH="*/2 * * * * /usr/bin/flock -n /tmp/vault-push.lock ${SCRIPT_DIR}/scripts/sync-push.sh >> /var/log/vault-sync.log 2>&1"

# Agregar crons si no existen
(crontab -l 2>/dev/null || true) | grep -qF "sync-pull.sh" || \
    (crontab -l 2>/dev/null || true; echo "${CRON_PULL}") | crontab -

(crontab -l 2>/dev/null || true) | grep -qF "sync-push.sh" || \
    (crontab -l 2>/dev/null || true; echo "${CRON_PUSH}") | crontab -

echo "==> Haciendo scripts ejecutables..."
chmod +x "${SCRIPT_DIR}/scripts/"*.sh

echo ""
echo "============================================================"
echo " Provisión completa. Pasos manuales restantes:"
echo "============================================================"
echo ""
echo " 1. Configurar deploy key SSH con write access en el repo del vault:"
echo "    ssh-keygen -t ed25519 -f ~/.ssh/vault_deploy -N ''"
echo "    → Agregar la clave pública en GitHub > Repo > Settings > Deploy Keys"
echo ""
echo " 2. Editar ${SCRIPT_DIR}/.env con tus API keys (si no lo hiciste antes)"
echo ""
echo " 3. Levantar OpenClaw:"
echo "    cd ${SCRIPT_DIR}"
echo "    docker compose up -d"
echo ""
echo " 4. Verificar que funciona:"
echo "    docker compose logs -f openclaw-gateway"
echo ""
