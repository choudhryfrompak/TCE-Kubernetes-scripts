
# Project Structure Overview

## Application Source Structure
```
app/
├── backend/               # .NET Backend
│   ├── TestApi/          # Main API Project
│   ├── TestApi.Domain/   # Domain Layer
│   ├── TestApi.Migrations/ # Database Migrations
│   └── scripts/          # Database Scripts
└── frontend/             # React Frontend
    ├── apps/
    │   └── web/         # Main Web Application
    └── packages/        # Shared Packages
```

## Deployment Structures

### Docker Deployment (deployment/docker/CPU/) - OLD
```
CPU/
├── Api.Dockerfile        # API build and runtime
├── Ui.Dockerfile        # UI build and runtime
├── Dockerfile.database.migrate  # DB migrations
├── Dockerfile.database.seed    # DB seeding
└── compose.yaml         # Service orchestration
```

### Kubernetes Deployment (deployment/docker/CPU-K8s/) - NEW
```
CPU-K8s/
├── base/                # Base Kubernetes Configurations
│   ├── configmaps/     # Configuration Files
│   │   ├── api-config.yaml
│   │   ├── console-config.yaml
│   │   ├── ui-config.yaml
│   │   └── appsettings.json
│   ├── secrets/        # Sensitive Data
│   │   ├── db-credentials.yaml
│   │   └── api-secrets.yaml
│   ├── services/       # Service Definitions
│   │   ├── api-service.yaml
│   │   ├── ui-service.yaml
│   │   └── db-service.yaml
│   ├── deployments/    # Main Components
│   │   ├── api-deployment.yaml   # Uses dotnet sdk:9.0 base image
│   │   ├── ui-deployment.yaml    # Uses node:20.18-alpine base image
│   │   ├── console-deployment.yaml #Uses mcr.microsoft.com/dotnet/sdk:9.0 base image
│   │   └── db-deployment.yaml    # Uses postgres:13
│   ├── jobs/           # One-time Operations
│   │   ├── db-migration-job.yaml
│   │   └── db-seed-job.yaml
│   ├── volumes/        # Storage Configurations
│   │   ├── postgres-pv.yaml
│   │   └── postgres-pvc.yaml
│   ├── networking/     # Network Configurations
│   │   ├── ingress.yaml
│   │   └── network-policies.yaml
│   └── kustomization.yaml
└── overlays/           # Environment-specific Configurations
    ├── development/
    │   └── kustomization.yaml
    └── production/
        └── kustomization.yaml
```

## Key Differences

### 1. Image Building vs Direct Runtime
- **Docker**: 
  - Builds images containing application code
  - Uses multi-stage builds
  - Copies code into containers

- **Kubernetes**: 
  - Uses base images directly
  - Mounts source code as volumes
  - Runs in development mode with hot-reload

### 2. Configuration Management
- **Docker**: 
  - Uses .env file
  - Environment variables in compose.yaml
  - Direct volume mounts

- **Kubernetes**:
  - ConfigMaps for non-sensitive data
  - Secrets for sensitive data
  - PersistentVolumes for storage
  - Kustomize overlays for environment differences

### 3. Networking
- **Docker**:
  - Simple bridge network
  - Direct port mappings
  - Service discovery via container names

- **Kubernetes**:
  - Services for internal communication
  - Ingress for external access
  - Network Policies for security
  - DNS-based service discovery

### 4. Code Mounting
- **Docker**:
```yaml
volumes:
  - ../../../app/backend:/src
```

- **Kubernetes**:
```yaml
volumes:
  - name: api-source-code
    hostPath:
      path: /root/app/backend
      type: Directory
```

### 5. Development Workflow
- **Docker**:
  - Single compose file for all services
  - Direct environment variable injection
  - Simple start/stop commands

- **Kubernetes**:
  - Separate configurations for each component
  - Base/overlay structure for environments
  - Rolling updates and scaling capabilities

### 6. Database Operations
- **Docker**:
  - Direct volume mapping for persistence
  - Wait-for scripts in compose

- **Kubernetes**:
  - StatefulSet for database
  - PersistentVolumeClaims
  - Init Containers and readiness probes

## Common Elements
Both setups maintain:
1. Same source code structure
2. Similar base images
3. Similar environment variables
4. Database migrations and seeding
5. Code mounting for development
6. Service isolation and networking

## Usage Comparison
```bash
# Docker
docker-compose -f deployment/docker/CPU/compose.yaml up

# Kubernetes
kubectl apply -k CPU-K8s/overlays/development
```

This structure allows for:
- Development environment parity
- Easy transition between Docker and Kubernetes
- Consistent configuration management
- Scalable deployment options
