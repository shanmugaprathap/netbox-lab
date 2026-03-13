#!/usr/bin/env bash
set -euo pipefail

# NetBox Lab - Local Setup Script
# Deploys NetBox via Docker Compose on macOS

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NETBOX_DOCKER_DIR="${SCRIPT_DIR}/netbox-docker"
NETBOX_VERSION="${NETBOX_VERSION:-latest}"

echo "=== NetBox Lab Setup ==="

# -------------------------------------------------------------------
# Prerequisites check
# -------------------------------------------------------------------
check_prereqs() {
    local missing=()

    if ! command -v docker &>/dev/null; then
        missing+=("docker")
    fi

    if ! docker info &>/dev/null 2>&1; then
        echo "ERROR: Docker is installed but not running."
        echo "  Start Docker Desktop and re-run this script."
        exit 1
    fi

    if ! command -v python3 &>/dev/null; then
        missing+=("python3")
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        echo "ERROR: Missing required tools: ${missing[*]}"
        echo ""
        echo "Install them with:"
        echo "  brew install --cask docker   # Docker Desktop"
        echo "  brew install python@3.12     # Python 3"
        exit 1
    fi

    echo "[OK] Prerequisites: docker, python3"
}

# -------------------------------------------------------------------
# Clone netbox-docker (official community Docker Compose setup)
# -------------------------------------------------------------------
clone_netbox_docker() {
    if [ -d "${NETBOX_DOCKER_DIR}" ]; then
        echo "[OK] netbox-docker already cloned"
        return
    fi

    echo "[..] Cloning netbox-community/netbox-docker (release branch)..."
    git clone -b release https://github.com/netbox-community/netbox-docker.git "${NETBOX_DOCKER_DIR}"
    echo "[OK] Cloned netbox-docker"
}

# -------------------------------------------------------------------
# Configure docker-compose override for local access
# -------------------------------------------------------------------
configure_override() {
    local override_file="${NETBOX_DOCKER_DIR}/docker-compose.override.yml"

    if [ -f "${override_file}" ]; then
        echo "[OK] docker-compose.override.yml already exists"
        return
    fi

    cat > "${override_file}" <<'YAML'
services:
  netbox:
    ports:
      - "8000:8080"
    environment:
      # Superuser credentials (created on first start)
      SUPERUSER_API_TOKEN: "0123456789abcdef0123456789abcdef01234567"
      SUPERUSER_NAME: "admin"
      SUPERUSER_EMAIL: "admin@example.com"
      SUPERUSER_PASSWORD: "admin"
YAML

    echo "[OK] Created docker-compose.override.yml"
    echo "     NetBox will be available at: http://localhost:8000"
    echo "     Login: admin / admin"
    echo "     API Token: 0123456789abcdef0123456789abcdef01234567"
}

# -------------------------------------------------------------------
# Start NetBox
# -------------------------------------------------------------------
start_netbox() {
    echo "[..] Starting NetBox (this may take 2-5 minutes on first run)..."
    cd "${NETBOX_DOCKER_DIR}"
    docker compose up -d

    echo ""
    echo "[..] Waiting for NetBox to become healthy..."
    local retries=0
    local max_retries=60
    while [ $retries -lt $max_retries ]; do
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/api/ 2>/dev/null | grep -q "200"; then
            echo ""
            echo "[OK] NetBox is running!"
            return
        fi
        printf "."
        sleep 5
        retries=$((retries + 1))
    done

    echo ""
    echo "WARN: NetBox may still be starting. Check: docker compose logs -f netbox"
}

# -------------------------------------------------------------------
# Setup Python automation environment
# -------------------------------------------------------------------
setup_python_env() {
    local venv_dir="${SCRIPT_DIR}/.venv"

    if [ -d "${venv_dir}" ]; then
        echo "[OK] Python venv already exists"
    else
        echo "[..] Creating Python virtual environment..."
        python3 -m venv "${venv_dir}"
        echo "[OK] Created .venv"
    fi

    echo "[..] Installing Python dependencies..."
    "${venv_dir}/bin/pip" install -q -r "${SCRIPT_DIR}/requirements.txt"
    echo "[OK] Installed pynetbox and dependencies"
}

# -------------------------------------------------------------------
# Main
# -------------------------------------------------------------------
main() {
    check_prereqs
    clone_netbox_docker
    configure_override
    start_netbox
    setup_python_env

    echo ""
    echo "============================================"
    echo "  NetBox Lab is ready!"
    echo "============================================"
    echo ""
    echo "  Web UI:    http://localhost:8000"
    echo "  Login:     admin / admin"
    echo "  API:       http://localhost:8000/api/"
    echo "  API Token: 0123456789abcdef0123456789abcdef01234567"
    echo ""
    echo "  Populate sample data:"
    echo "    source .venv/bin/activate"
    echo "    python automation/populate.py"
    echo ""
    echo "  Stop NetBox:"
    echo "    cd netbox-docker && docker compose down"
    echo ""
    echo "  Restart NetBox:"
    echo "    cd netbox-docker && docker compose up -d"
    echo ""
}

main "$@"
