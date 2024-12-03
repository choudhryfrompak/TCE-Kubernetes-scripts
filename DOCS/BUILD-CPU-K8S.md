# CPU-Based Kubernetes Cluster Setup Guide

This repository will contain all (Iac) for setting up a Kubernetes cluster on CPU nodes using Ansible and some utilities.

## Prerequisites

- Ubuntu/Debian-based OS on all nodes
- SSH access to all nodes
- Ansible installed on all nodes

## Initial Setup
### switch to root:
```bash
sudo -i
```

### 1. Repository Preparation

```bash
# Clone the repository (if not already done)
git clone https://github.com/choudhryfrompak/TCE-Kubernetes-scripts.git

# Make all scripts executable
chmod -R +x TCE-Kubernetes-scripts

# Navigate to the deployment directory
cd TCE-Kubernetes-scripts/deployment/kubernetes/CPU-K8s/
```

### 2. Host Configuration

#### 2.1 Configure /etc/hosts

Add the hostnames and corresponding IP addresses to `/etc/hosts`:

```bash
sudo nano /etc/hosts
```

Add entries for all nodes:
```
# Control Planes
10.0.0.101 control-plane
//add more as you want
# Cluster Workers
10.0.0.10 worker1
10.0.0.20 worker2
//add more as you want
```

#### 2.2 Configure Ansible Hosts

Edit the Ansible inventory file:
```bash
nano ../common/01-inventory/hosts
```

Configure according to your setup:
```ini
# All Kubernetes nodes
[all]
control-plane

# Primary control plane node
[master_main]
control-plane    # Add main master (for multi-master setup)

# All master nodes
[masters]
control-plane  # Add all master nodes

# All worker nodes
[workers]
worker1       # Add all worker nodes
# Common variables for all nodes
[all:vars]
ansible_user=<your-ansible-user>
ansible_become=yes
ansible_become_method=sudo
ansible_ssh_private_key_file=<path-to-your-key-file>
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
```

### 3. Cluster Installation

#### 3.1 Install Ansible on All Nodes
```bash
sudo apt install ansible
```

#### 3.2 Run Installation Playbooks
Test connectivity:
```bash
ansible all -i ../common/01-inventory/hosts -m "ping"
```

Execute the following playbooks in order:

1. System Network Configuration
```bash
ansible-playbook -i ../common/01-inventory/hosts 02-playbooks/01-System-Network.yml
ansible-playbook -i ../common/01-inventory/hosts 02-playbooks/verify-01.yml
```

2. Container Runtime and Drivers
```bash
ansible-playbook -i ../common/01-inventory/hosts 02-playbooks/02-container-runtime-drivers.yml
ansible-playbook -i ../common/01-inventory/hosts 02-playbooks/verify-02.yml
```

3. Kubernetes Installation
```bash
ansible-playbook -i ../common/01-inventory/hosts 02-playbooks/03-kubernetes-installation.yml
ansible-playbook -i ../common/01-inventory/hosts 02-playbooks/verify-03.yml
```

4. Cluster Initialization
```bash
ansible-playbook -i ../common/01-inventory/hosts 02-playbooks/04-cluster-initialization.yml
```

5. Post Installation Setup
```bash
ansible-playbook -i ../common/01-inventory/hosts 02-playbooks/05-post-installation.yml
ansible-playbook -i ../common/01-inventory/hosts 02-playbooks/verify-04-05.yml
```

#### 3.3 Optional: Generate Join Command
If you need to add more nodes later:
```bash
bash 02-playbooks/print-join-command.sh
```

### 4. Verify Cluster Setup

Check node status:
```bash
kubectl get nodes
```

If any node shows 'NotReady' status:
```bash
# SSH into the problematic node and run:
systemctl restart containerd kubelet.service

# Or restart all nodes if needed
```

### 5. Additional Utilities

#### 5.1 Install Helm and Rancher
```bash
bash ../common/03-helm-and-rancher/setup-helm-and-rancher.sh
```

#### 5.2 Verify Rancher Installation
```bash
kubectl get svc -n cattle-system
```
Look for `service/rancher` and note the corresponding port.

## Troubleshooting

1. Node Not Ready Status:
   - Restart container runtime and kubelet
   - Check node logs: `journalctl -u kubelet`
   - Verify network plugin status

2. Network Issues:
   - Ensure Calico is properly installed
   - Check pod network CIDR configuration
   - Verify node connectivity

## Notes

- Ensure all nodes have proper network connectivity
- Verify SSH access before running playbooks