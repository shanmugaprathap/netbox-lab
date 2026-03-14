#!/usr/bin/env bash
set -euo pipefail

# NetBox Lab - Kubernetes Setup Script
# Deploys NetBox + full monitoring stack via Helm on minikube (or GKE)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CHART_DIR="${SCRIPT_DIR}/netbox-chart"
NAMESPACE="netbox-lab"
RELEASE_NAME="netbox-lab"

# Parse arguments
ENV="minikube"
while [[ $# -gt 0 ]]; do
    case $1 in
        --env)
            ENV="$2"
            shift 2
            ;;
        --namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [--env minikube|gke] [--namespace <name>]"
            echo ""
            echo "Options:"
            echo "  --env        Target environment: minikube (default) or gke"
            echo "  --namespace  Kubernetes namespace (default: netbox-lab)"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "=== NetBox Lab - Kubernetes Setup ==="
echo "  Environment: ${ENV}"
echo "  Namespace:   ${NAMESPACE}"
echo ""

# -------------------------------------------------------------------
# Prerequisites check
# -------------------------------------------------------------------
check_prereqs() {
    local missing=()

    if ! command -v kubectl &>/dev/null; then
        missing+=("kubectl (brew install kubectl)")
    fi

    if ! command -v helm &>/dev/null; then
        missing+=("helm (brew install helm)")
    fi

    if [ "$ENV" = "minikube" ]; then
        if ! command -v minikube &>/dev/null; then
            missing+=("minikube (brew install minikube)")
        fi

        if ! command -v docker &>/dev/null; then
            missing+=("docker (brew install --cask docker)")
        fi
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        echo "ERROR: Missing required tools:"
        for tool in "${missing[@]}"; do
            echo "  - ${tool}"
        done
        exit 1
    fi

    echo "[OK] Prerequisites check passed"
}

# -------------------------------------------------------------------
# Start minikube (if local environment)
# -------------------------------------------------------------------
start_minikube() {
    if [ "$ENV" != "minikube" ]; then
        return
    fi

    # Check Docker is running
    if ! docker info &>/dev/null 2>&1; then
        echo "ERROR: Docker is not running. Start Docker Desktop first."
        exit 1
    fi

    if minikube status &>/dev/null 2>&1; then
        echo "[OK] minikube is already running"
    else
        echo "[..] Starting minikube (cpus=2, memory=3072MB)..."
        minikube start \
            --cpus=2 \
            --memory=3072 \
            --driver=docker \
            --kubernetes-version=stable
        echo "[OK] minikube started"
    fi

    # Enable addons
    echo "[..] Enabling minikube addons..."
    minikube addons enable metrics-server 2>/dev/null || true
    echo "[OK] Addons enabled"
}

# -------------------------------------------------------------------
# Add Helm repositories
# -------------------------------------------------------------------
add_helm_repos() {
    echo "[..] Adding Helm repositories..."
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
    helm repo update
    echo "[OK] Helm repositories ready"
}

# -------------------------------------------------------------------
# Build chart dependencies
# -------------------------------------------------------------------
build_deps() {
    echo "[..] Building Helm chart dependencies (this may take a few minutes on first run)..."
    cd "${CHART_DIR}"
    helm dependency build
    echo "[OK] Dependencies built"
}

# -------------------------------------------------------------------
# Deploy with Helm
# -------------------------------------------------------------------
deploy() {
    local values_file="${CHART_DIR}/values-${ENV}.yaml"

    if [ ! -f "${values_file}" ]; then
        echo "ERROR: Values file not found: ${values_file}"
        exit 1
    fi

    echo "[..] Deploying NetBox Lab to namespace '${NAMESPACE}'..."
    helm upgrade --install "${RELEASE_NAME}" "${CHART_DIR}" \
        -f "${values_file}" \
        --create-namespace \
        --namespace "${NAMESPACE}" \
        --timeout 10m \
        --wait
    echo "[OK] Helm release deployed"
}

# -------------------------------------------------------------------
# Wait for pods
# -------------------------------------------------------------------
wait_for_pods() {
    echo "[..] Waiting for all pods to be ready (timeout: 5m)..."
    kubectl wait --for=condition=ready pod \
        -l "app.kubernetes.io/instance=${RELEASE_NAME}" \
        --namespace "${NAMESPACE}" \
        --timeout=300s 2>/dev/null || true

    echo ""
    echo "Pod status:"
    kubectl get pods -n "${NAMESPACE}" --no-headers | while read -r line; do
        echo "  ${line}"
    done
}

# -------------------------------------------------------------------
# Print access info
# -------------------------------------------------------------------
print_info() {
    echo ""
    echo "============================================"
    echo "  NetBox Lab on Kubernetes is ready!"
    echo "============================================"
    echo ""

    if [ "$ENV" = "minikube" ]; then
        local netbox_url
        netbox_url=$(minikube service "${RELEASE_NAME}-netbox" -n "${NAMESPACE}" --url 2>/dev/null || echo "")

        if [ -n "$netbox_url" ]; then
            echo "  NetBox UI:    ${netbox_url}"
        else
            echo "  NetBox UI:    Run: minikube service ${RELEASE_NAME}-netbox -n ${NAMESPACE}"
        fi
        echo ""
        echo "  Or use port-forward:"
        echo "    kubectl port-forward svc/${RELEASE_NAME}-netbox 8080:8080 -n ${NAMESPACE}"
        echo "    Then open: http://localhost:8080"
    else
        echo "  NetBox UI:    Check your Ingress endpoint"
        echo "    kubectl get ingress -n ${NAMESPACE}"
    fi

    echo ""
    echo "  Login:     admin / admin"
    echo "  API Token: 0123456789abcdef0123456789abcdef01234567"
    echo ""
    echo "  Grafana:"
    echo "    kubectl port-forward svc/${RELEASE_NAME}-grafana 3000:80 -n ${NAMESPACE}"
    echo "    Then open: http://localhost:3000  (admin / admin)"
    echo ""
    echo "  Prometheus:"
    echo "    kubectl port-forward svc/${RELEASE_NAME}-kube-prometheus-stack-prometheus 9090:9090 -n ${NAMESPACE}"
    echo "    Then open: http://localhost:9090"
    echo ""
    echo "  Useful commands:"
    echo "    kubectl get pods -n ${NAMESPACE}         # Check pod status"
    echo "    kubectl logs -f deploy/${RELEASE_NAME}-netbox -n ${NAMESPACE}  # NetBox logs"
    echo "    helm test ${RELEASE_NAME} -n ${NAMESPACE}  # Run connectivity test"
    echo ""
}

# -------------------------------------------------------------------
# Main
# -------------------------------------------------------------------
main() {
    check_prereqs
    start_minikube
    add_helm_repos
    build_deps
    deploy
    wait_for_pods
    print_info
}

main "$@"
