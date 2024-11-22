#!/bin/bash

# Exit on any error
set -e

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

# Function to check if a command exists
check_command() {
    if ! command -v $1 &> /dev/null; then
        log_error "$1 is required but not installed. Please install it first."
        exit 1
    fi
}

# Function to safely delete a helm release
delete_helm_release() {
    local namespace=$1
    local release=$2

    if helm list -n $namespace | grep -q $release; then
        log_info "Uninstalling Helm release: $release from namespace: $namespace"
        helm uninstall $release -n $namespace
        return 0
    else
        log_warn "Helm release $release not found in namespace $namespace"
        return 1
    fi
}

# Function to safely delete a namespace
delete_namespace() {
    local namespace=$1

    if kubectl get namespace $namespace &> /dev/null; then
        log_info "Deleting namespace: $namespace"
        kubectl delete namespace $namespace --timeout=60s

        # Wait for namespace deletion
        local retries=30
        while kubectl get namespace $namespace &> /dev/null && [ $retries -gt 0 ]; do
            log_warn "Waiting for namespace $namespace to be deleted... ($retries attempts remaining)"
            sleep 2
            ((retries--))
        done

        if [ $retries -eq 0 ]; then
            log_warn "Namespace $namespace deletion timed out. You may need to check it manually."
        else
            log_info "Namespace $namespace successfully deleted"
        fi
    else
        log_warn "Namespace $namespace not found"
    fi
}

# Function to remove CRDs
remove_crds() {
    log_info "Removing Prometheus Operator CRDs..."

    local crds=(
        "alertmanagerconfigs.monitoring.coreos.com"
        "alertmanagers.monitoring.coreos.com"
        "podmonitors.monitoring.coreos.com"
        "probes.monitoring.coreos.com"
        "prometheuses.monitoring.coreos.com"
        "prometheusrules.monitoring.coreos.com"
        "servicemonitors.monitoring.coreos.com"
        "thanosrulers.monitoring.coreos.com"
    )

    for crd in "${crds[@]}"; do
        if kubectl get crd $crd &> /dev/null; then
            log_info "Removing CRD: $crd"
            kubectl delete crd $crd
        fi
    done
}

# Check prerequisites
log_info "Checking prerequisites..."
check_command kubectl
check_command helm

# Print warning
echo -e "${RED}"
echo "⚠️  WARNING: This script will remove all GPU monitoring components and their data ⚠️"
echo "This includes:"
echo "  - DCGM Exporter"
echo "  - Prometheus Stack"
echo "  - All associated Custom Resource Definitions"
echo "  - All monitoring data"
echo -e "${NC}"

# Prompt for confirmation
read -p "Are you sure you want to proceed? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Cleanup cancelled"
    exit 0
fi

# Start cleanup process
log_info "Starting cleanup process..."

# Remove DCGM exporter
log_info "Removing DCGM exporter..."
delete_helm_release default dcgm-exporter-release || true

# Remove Prometheus stack
log_info "Removing Prometheus stack..."
delete_helm_release prometheus kube-prometheus-stack || true

# Remove namespaces
log_info "Removing namespaces..."
delete_namespace prometheus

# Remove CRDs
remove_crds

# Remove Helm repositories (optional)
log_info "Removing Helm repositories..."
helm repo remove prometheus-community 2>/dev/null || true
helm repo remove gpu-helm-charts 2>/dev/null || true

# Final cleanup status
log_info "Checking for any remaining resources..."

# Check for any remaining pods
remaining_pods=$(kubectl get pods -A | grep -E 'prometheus|dcgm-exporter' || true)
if [ ! -z "$remaining_pods" ]; then
    log_warn "Some monitoring-related pods are still present:"
    echo "$remaining_pods"
    log_warn "You may need to remove these manually"
fi

# Print completion message
cat << EOF

🧹 Cleanup Complete! 🧹

The following components have been removed:
- DCGM Exporter
- Prometheus Stack
- Associated CRDs and resources
- Monitoring namespaces

Note: If you see any warnings above, some components may require manual cleanup.
To manually remove any stuck resources, you can use:
  kubectl delete pod <pod-name> -n <namespace> --force --grace-period=0

EOF
