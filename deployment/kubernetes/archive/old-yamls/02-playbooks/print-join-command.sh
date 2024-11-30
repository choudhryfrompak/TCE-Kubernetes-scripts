#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_separator() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root"
    exit 1
fi

# Check if kubeadm is installed
if ! command -v kubeadm &> /dev/null; then
    log_error "kubeadm is not installed"
    exit 1
fi

# Print cluster information header
print_separator
echo -e "${GREEN}📊 Kubernetes Cluster Join Information${NC}"
print_separator

# Get cluster information
log_info "Gathering cluster information..."

# Get control plane endpoint
CONTROL_PLANE_IP=$(kubectl get nodes -l node-role.kubernetes.io/control-plane='' -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null || echo "N/A")
API_SERVER_PORT=$(kubectl get configmap kubeadm-config -n kube-system -o jsonpath='{.data.ClusterConfiguration}' | grep "bindPort" | cut -d: -f2 || echo "6443")

# Get cluster information
KUBERNETES_VERSION=$(kubectl version --short 2>/dev/null | grep "Server Version" | cut -d: -f2 | tr -d ' ' || echo "N/A")
NODE_COUNT=$(kubectl get nodes --no-headers 2>/dev/null | wc -l || echo "N/A")
POD_COUNT=$(kubectl get pods -A --no-headers 2>/dev/null | wc -l || echo "N/A")

# Generate new token
log_info "Generating new join token..."
JOIN_COMMAND=$(kubeadm token create --print-join-command)

# Extract token and cert hash from join command
TOKEN=$(echo $JOIN_COMMAND | awk -F' ' '{for(i=1;i<=NF;i++) if($i == "--token") print $(i+1)}')
CERT_HASH=$(echo $JOIN_COMMAND | awk -F' ' '{for(i=1;i<=NF;i++) if($i == "--discovery-token-ca-cert-hash") print $(i+1)}')

# Print cluster details
echo -e "\n${YELLOW}Cluster Details:${NC}"
echo -e "• Kubernetes Version: ${GREEN}${KUBERNETES_VERSION}${NC}"
echo -e "• Control Plane IP: ${GREEN}${CONTROL_PLANE_IP}${NC}"
echo -e "• API Server Port: ${GREEN}${API_SERVER_PORT}${NC}"
echo -e "• Total Nodes: ${GREEN}${NODE_COUNT}${NC}"
echo -e "• Total Pods: ${GREEN}${POD_COUNT}${NC}"

# Print token information
echo -e "\n${YELLOW}Token Details:${NC}"
echo -e "• Token: ${GREEN}${TOKEN}${NC}"
echo -e "• Token TTL: ${GREEN}24h${NC}"
echo -e "• CA Cert Hash: ${GREEN}${CERT_HASH}${NC}"

# Print join command
print_separator
echo -e "${YELLOW}Join Command for Worker Nodes:${NC}"
echo -e "${GREEN}${JOIN_COMMAND}${NC}"
print_separator

# Save join command to file
echo -e "\n${YELLOW}Saving join command to file...${NC}"
JOIN_COMMAND_FILE="cluster-join-command-$(date +%Y%m%d-%H%M%S).txt"
echo "$JOIN_COMMAND" > $JOIN_COMMAND_FILE
echo -e "Join command saved to: ${GREEN}$(pwd)/${JOIN_COMMAND_FILE}${NC}"

# Print additional information
echo -e "\n${YELLOW}Additional Information:${NC}"
echo -e "• The token will expire in 24 hours"
echo -e "• To join a control plane node, add --control-plane to the join command"
echo -e "• Run the join command with sudo on the worker node"

# Print verification instructions
echo -e "\n${YELLOW}After joining, verify on control plane:${NC}"
echo -e "• ${GREEN}kubectl get nodes${NC} - to see the new node"
echo -e "• ${GREEN}kubectl get nodes -o wide${NC} - for detailed node information"

print_separator