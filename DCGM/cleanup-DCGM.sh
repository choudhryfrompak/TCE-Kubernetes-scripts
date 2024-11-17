#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to safely delete helm releases
delete_helm_release() {
    local release=$1
    local namespace=${2:-default}

    if helm list -n "$namespace" | grep -q "^$release"; then
        log_info "Removing Helm release: $release from namespace $namespace"
        helm uninstall "$release" -n "$namespace" || log_warn "Failed to uninstall $release"
    else
        log_info "Helm release $release not found in namespace $namespace"
    fi
}

# Function to safely delete kubernetes resources
delete_k8s_resource() {
    local resource_type=$1
    local resource_name=$2
    local namespace=${3:-default}

    if kubectl get "$resource_type" -n "$namespace" 2>/dev/null | grep -q "$resource_name"; then
        log_info "Removing $resource_type: $resource_name from namespace $namespace"
        kubectl delete "$resource_type" "$resource_name" -n "$namespace" || log_warn "Failed to delete $resource_type $resource_name"
    fi
}

log_info "Starting cleanup of telemetry components..."

# List current state
log_info "Current Helm releases:"
helm list -A

log_info "Current pods in prometheus namespace:"
kubectl get pods -n prometheus || true

# Remove DCGM exporter
log_info "Removing DCGM exporter..."
delete_helm_release "dcgm-exporter"

# Remove Prometheus stack
log_info "Removing Prometheus stack..."
delete_helm_release "kube-prometheus-stack" "prometheus"

# Remove any leftover services
log_info "Removing leftover services in prometheus namespace..."
kubectl delete svc --all -n prometheus 2>/dev/null || true

# Remove any leftover pods
log_info "Removing leftover pods in prometheus namespace..."
kubectl delete pods --all -n prometheus 2>/dev/null || true

# Remove any leftover PVCs
log_info "Removing leftover PVCs in prometheus namespace..."
kubectl delete pvc --all -n prometheus 2>/dev/null || true

# Remove any leftover configmaps
log_info "Removing leftover configmaps in prometheus namespace..."
kubectl delete configmap --all -n prometheus 2>/dev/null || true

# Remove any leftover secrets
log_info "Removing leftover secrets in prometheus namespace..."
kubectl delete secret --all -n prometheus 2>/dev/null || true

# Remove the prometheus namespace itself
log_info "Removing prometheus namespace..."
kubectl delete namespace prometheus --timeout=60s 2>/dev/null || true

# Remove CRDs
log_info "Removing Prometheus CRDs..."
kubectl delete crd alertmanagerconfigs.monitoring.coreos.com 2>/dev/null || true
kubectl delete crd alertmanagers.monitoring.coreos.com 2>/dev/null || true
kubectl delete crd podmonitors.monitoring.coreos.com 2>/dev/null || true
kubectl delete crd probes.monitoring.coreos.com 2>/dev/null || true
kubectl delete crd prometheuses.monitoring.coreos.com 2>/dev/null || true
kubectl delete crd prometheusrules.monitoring.coreos.com 2>/dev/null || true
kubectl delete crd servicemonitors.monitoring.coreos.com 2>/dev/null || true
kubectl delete crd thanosrulers.monitoring.coreos.com 2>/dev/null || true

# Wait a bit to ensure everything is cleaned up
sleep 10

# Verify cleanup
log_info "Verifying cleanup..."

# Check for any remaining pods
REMAINING_PODS=$(kubectl get pods -A | grep -E 'prometheus|dcgm-exporter' || true)
if [ ! -z "$REMAINING_PODS" ]; then
    log_warn "Some pods still remain:"
    echo "$REMAINING_PODS"
else
    log_info "All relevant pods have been removed"
fi

# Check for remaining helm releases
REMAINING_RELEASES=$(helm list -A | grep -E 'prometheus|dcgm-exporter' || true)
if [ ! -z "$REMAINING_RELEASES" ]; then
    log_warn "Some Helm releases still remain:"
    echo "$REMAINING_RELEASES"
else
    log_info "All relevant Helm releases have been removed"
fi

log_info "Cleanup complete!"
