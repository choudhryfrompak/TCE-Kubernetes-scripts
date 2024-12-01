# Kubernetes Deployment Guide

## Image Preparation
1. Build and push images to your registry:
```bash
cd TCE-Kubernetes-scripts/deployment/docker/CPU/
docker compose up -d
```
after you run docker compose: Do this:

```bash
# Set the variable
DOCKER_ACC="your-account-name"

docker tag testapi:latest ${DOCKER_ACC}/testapi:latest
docker tag testui:latest ${DOCKER_ACC}/testui:latest
docker tag testconsole:latest ${DOCKER_ACC}/testconsole:latest
docker tag cpu-test-db-migrate:latest ${DOCKER_ACC}/cpu-test-db-migrate:latest
docker tag cpu-test-pg-db-seed:latest ${DOCKER_ACC}/cpu-test-pg-db-seed:latest

docker push ${DOCKER_ACC}/testapi:latest
docker push ${DOCKER_ACC}/testui:latest
docker push ${DOCKER_ACC}/testconsole:latest
docker push ${DOCKER_ACC}/cpu-test-db-migrate:latest
docker push ${DOCKER_ACC}/cpu-test-pg-db-seed:latest
```

## Storage Setup
1. Create storage directory on all nodes:
```bash
mkdir -p /root/data/postgres
mkdir -p /root/testconsole/input
mkdir -p /root/testconsole/output
chmod 777 /root/data/postgres
chmod 777 /root/testconsole/input
chmod 777 /root/testconsole/output
```

## Deployment Steps
1. Create namespace:
```bash
kubectl create namespace project
```

2. Deploy using kustomize:

```bash
cd TCE-Kubernetes-scripts/deployment/kubernetes/CPU-K8s/kustomize/
kubectl apply -k overlays/development -n project
```

## Accessing Services
- API: http://<node-ip>:31178
- API (HTTPS): https://<node-ip>:30161
- UI: http://<node-ip>:31193
- Database: <node-ip>:30268

## Verify Deployment
```bash
# Check all resources
kubectl get all -n project

# Verify pods are running
kubectl get pods -n project

# Check service endpoints
kubectl get endpoints -n project
```
