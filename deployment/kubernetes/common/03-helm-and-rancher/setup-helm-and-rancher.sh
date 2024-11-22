#!/bin/bash

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

# Function to verify pod status
verify_pods() {
    local namespace=$1
    local label=$2
    local timeout=${3:-300}
    local start_time=$(date +%s)
    local end_time=$((start_time + timeout))

    while true; do
        local current_time=$(date +%s)
        if [ $current_time -gt $end_time ]; then
            log_error "Timeout waiting for pods in namespace $namespace"
            return 1
        fi

        local not_ready_pods=$(kubectl get pods -n $namespace | grep -v Running | grep -v Completed | grep -v NAME || true)
        if [ -z "$not_ready_pods" ]; then
            log_info "All pods in namespace $namespace are ready"
            return 0
        fi

        log_warn "Waiting for pods to be ready in namespace $namespace..."
        sleep 10
    done
}

# Install Helm if not present
install_helm() {
    if ! command -v helm &> /dev/null; then
        log_info "Installing Helm..."
        curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
        chmod 700 get_helm.sh
        ./get_helm.sh
        rm get_helm.sh
    else
        log_info "Helm is already installed"
    fi
}

# Function to check if a namespace exists
check_namespace() {
    kubectl get namespace $1 &> /dev/null
}

# Get customization preferences
read -p "Enter Rancher hostname [rancher.my.org]: " rancher_hostname
rancher_hostname=${rancher_hostname:-rancher.my.org}

read -p "Enter Rancher bootstrap password [admin]: " rancher_password
rancher_password=${rancher_password:-admin}

# Install Helm
install_helm

# Add required Helm repositories
log_info "Adding Helm repositories..."
helm repo add rancher-alpha https://releases.rancher.com/server-charts/alpha
helm repo add jetstack https://charts.jetstack.io
helm repo update

# Create namespaces
log_info "Creating required namespaces..."
if ! check_namespace cattle-system; then
    kubectl create namespace cattle-system
fi

if ! check_namespace cert-manager; then
    kubectl create namespace cert-manager
fi

# Install cert-manager CRDs
log_info "Installing cert-manager CRDs..."
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.16.1/cert-manager.crds.yaml

# Install cert-manager
log_info "Installing cert-manager..."
helm install cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --set crds.enabled=false \
    --wait

# Verify cert-manager installation
log_info "Verifying cert-manager installation..."
verify_pods cert-manager "" 300

# Install Rancher
log_info "Installing Rancher..."
helm install rancher rancher-alpha/rancher --devel \
    --namespace cattle-system \
    --set hostname=$rancher_hostname \
    --set bootstrapPassword=$rancher_password \
    --wait

# Verify Rancher installation
log_info "Verifying Rancher installation..."
verify_pods cattle-system "" 300

# Patch Rancher service to NodePort
log_info "Patching Rancher service to NodePort..."
kubectl patch svc rancher -n cattle-system -p '{"spec": {"type": "NodePort"}}'

# Get NodePort and Node IP
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
RANCHER_PORT=$(kubectl get svc rancher -n cattle-system -o jsonpath='{.spec.ports[0].nodePort}')

# Final output
cat << EOF

🚀 Rancher Setup Complete! 🚀

Rancher Endpoint: https://${NODE_IP}:${RANCHER_PORT}
Bootstrap Password: ${rancher_password}

Note: The endpoint uses HTTPS. You might need to accept the self-signed certificate in your browser.

To access Rancher:
1. Open https://${NODE_IP}:${RANCHER_PORT} in your browser
2. Log in with:
   - Username: admin
   - Password: ${rancher_password}

Current Rancher pod status:
EOF

kubectl get pods -n cattle-system

log_info "Recent events from cattle-system namespace:"
kubectl get events -n cattle-system --sort-by='.lastTimestamp' | tail -n 20