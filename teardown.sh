#!/usr/bin/env bash
set -euo pipefail

# NetBox Lab - Teardown Script
# Stops NetBox and removes all Docker resources

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NETBOX_DOCKER_DIR="${SCRIPT_DIR}/netbox-docker"

echo "=== NetBox Lab Teardown ==="

if [ -d "${NETBOX_DOCKER_DIR}" ]; then
    echo "[..] Stopping and removing containers..."
    cd "${NETBOX_DOCKER_DIR}"
    docker compose down -v --remove-orphans 2>/dev/null || true
    echo "[OK] Containers stopped and volumes removed"
else
    echo "[OK] netbox-docker directory not found, nothing to stop"
fi

read -p "Remove netbox-docker directory? (y/N): " confirm
if [[ "${confirm}" =~ ^[Yy]$ ]]; then
    rm -rf "${NETBOX_DOCKER_DIR}"
    echo "[OK] Removed netbox-docker directory"
fi

read -p "Remove Python venv? (y/N): " confirm
if [[ "${confirm}" =~ ^[Yy]$ ]]; then
    rm -rf "${SCRIPT_DIR}/.venv"
    echo "[OK] Removed .venv"
fi

echo ""
echo "[OK] Teardown complete"
