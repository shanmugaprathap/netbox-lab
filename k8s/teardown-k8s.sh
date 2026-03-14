#!/usr/bin/env bash
set -euo pipefail

# NetBox Lab - Kubernetes Teardown Script

NAMESPACE="${1:-netbox-lab}"
RELEASE_NAME="netbox-lab"

echo "=== NetBox Lab - Kubernetes Teardown ==="
echo ""

# -------------------------------------------------------------------
# Uninstall Helm release
# -------------------------------------------------------------------
if helm status "${RELEASE_NAME}" -n "${NAMESPACE}" &>/dev/null 2>&1; then
    echo "[..] Uninstalling Helm release '${RELEASE_NAME}'..."
    helm uninstall "${RELEASE_NAME}" -n "${NAMESPACE}"
    echo "[OK] Helm release uninstalled"
else
    echo "[OK] No Helm release '${RELEASE_NAME}' found in namespace '${NAMESPACE}'"
fi

# -------------------------------------------------------------------
# Delete PVCs (with confirmation)
# -------------------------------------------------------------------
pvcs=$(kubectl get pvc -n "${NAMESPACE}" --no-headers 2>/dev/null || true)
if [ -n "$pvcs" ]; then
    echo ""
    echo "Persistent Volume Claims in namespace '${NAMESPACE}':"
    echo "$pvcs" | while read -r line; do
        echo "  ${line}"
    done
    echo ""
    read -rp "Delete all PVCs? This will destroy all data. [y/N] " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        kubectl delete pvc --all -n "${NAMESPACE}"
        echo "[OK] PVCs deleted"
    else
        echo "[OK] PVCs preserved"
    fi
fi

# -------------------------------------------------------------------
# Delete namespace (with confirmation)
# -------------------------------------------------------------------
if kubectl get namespace "${NAMESPACE}" &>/dev/null 2>&1; then
    echo ""
    read -rp "Delete namespace '${NAMESPACE}'? [y/N] " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        kubectl delete namespace "${NAMESPACE}"
        echo "[OK] Namespace deleted"
    else
        echo "[OK] Namespace preserved"
    fi
fi

# -------------------------------------------------------------------
# Stop minikube (with confirmation)
# -------------------------------------------------------------------
if command -v minikube &>/dev/null && minikube status &>/dev/null 2>&1; then
    echo ""
    read -rp "Stop minikube? [y/N] " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        minikube stop
        echo "[OK] minikube stopped"
    else
        echo "[OK] minikube still running"
    fi
fi

echo ""
echo "[OK] Teardown complete"
