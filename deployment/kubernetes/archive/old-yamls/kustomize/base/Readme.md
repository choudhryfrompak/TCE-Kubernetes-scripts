1. **Database Configuration**:

**Docker (compose.yaml)**:
```yaml
services:
  test-pg-db:
    image: postgres:13
    container_name: test-pg-db
    restart: always
    ports:
      - 5488:5432
    volumes:
      - ${SQL_Pg_Data_Folder}/data:/var/lib/postgresql/data
    networks:
      - test-network
    env_file:
      - .env
```

**Kubernetes (base/deployments/db-deployment.yaml)**:
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: test-pg-db
spec:
  serviceName: test-pg-db
  replicas: 1
  selector:
    matchLabels:
      app: test-pg-db
  template:
    metadata:
      labels:
        app: test-pg-db
    spec:
      containers:
      - name: postgres
        image: postgres:13
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_USER
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: POSTGRES_USER
        # ... other env vars
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
```

Key differences:
- Docker uses direct volume mounting, K8s uses PVC
- Docker uses env_file, K8s uses Secrets
- K8s needs StatefulSet for database persistence
- Network is handled differently in K8s

2. **API Configuration**:

**Docker (Api.Dockerfile)**:
```dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
USER $APP_UID
WORKDIR /app
EXPOSE 8080
EXPOSE 8081

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY ["TestApi/TestApi.csproj", "TestApi/"]
RUN dotnet restore "TestApi/TestApi.csproj"
```

**Docker (compose.yaml)**:
```yaml
services:
  testapi:
    image: testapi
    container_name: testapi
    build:
      context: ../../../app/backend
      dockerfile: ../../deployment/docker/CPU/Api.Dockerfile
    ports:
      - "8093:8081"
      - ${API_HOST_PORT}:8080
```

**Kubernetes (base/deployments/api-deployment.yaml)**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: testapi
spec:
  replicas: 1
  template:
    spec:
      containers:
      - name: testapi
        image: mcr.microsoft.com/dotnet/sdk:9.0
        workingDir: /src/TestApi
        command: ["dotnet"]
        args: ["watch", "run", "--urls", "http://0.0.0.0:8080"]
        volumeMounts:
        - name: api-source
          mountPath: /src
      volumes:
      - name: api-source
        hostPath:
          path: ../../app/backend
```

Key differences:
- Docker builds image, K8s uses base image with mounted code
- Docker uses ports mapping, K8s uses Services
- K8s adds health checks and resource limits
- Development mode is handled differently

3. **UI Configuration**:

**Docker (Ui.Dockerfile)**:
```dockerfile
FROM node:20.18-alpine as build
WORKDIR /app
COPY package*.json ./
COPY pnpm-lock.yaml ./
RUN corepack enable && corepack prepare pnpm@latest --activate
```

**Docker (compose.yaml)**:
```yaml
services:
  testui:
    image: testui
    container_name: testui
    build:
      context: ../../../app
      dockerfile: ../deployment/docker/CPU/Ui.Dockerfile
    ports:
      - "8092:80"
```

**Kubernetes (base/deployments/ui-deployment.yaml)**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: testui
spec:
  template:
    spec:
      containers:
      - name: testui
        image: node:20.18-alpine
        workingDir: /app
        command: ["/bin/sh", "-c"]
        args:
        - |
          corepack enable && 
          corepack prepare pnpm@latest --activate &&
          cd frontend &&
          pnpm install &&
          pnpm dev --host 0.0.0.0
        volumeMounts:
        - name: ui-source
          mountPath: /app
```

Key differences:
- Docker builds UI, K8s runs dev server directly
- Docker uses nginx for production, K8s runs development mode
- Code mounting vs copying in Docker

4. **Migration and Seeding**:

**Docker (compose.yaml)**:
```yaml
services:
  test-db-migrate:
    platform: linux/amd64
    container_name: test-db-migrate
    build:
      context: ../../../app/backend
      dockerfile: ../../deployment/docker/CPU/Dockerfile.database.migrate
    networks:
      - test-network
    depends_on: [ test-pg-db ]

  test-pg-db-seed:
    container_name: test-pg-db-seed
    platform: linux/amd64
    build:
      context: ../../../app/backend
      dockerfile: ../../deployment/docker/CPU/Dockerfile.database.seed
```

**Kubernetes (base/jobs/db-migration-job.yaml, db-seed-job.yaml)**:
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: test-db-migrate
spec:
  template:
    spec:
      containers:
      - name: db-migrate
        image: mcr.microsoft.com/dotnet/sdk:9.0
        command: ["/bin/sh", "-c"]
        args:
        - |
          dotnet tool install --global dotnet-ef &&
          dotnet ef migrations bundle
```

Key differences:
- Docker uses custom images, K8s uses base images with commands
- Docker uses depends_on, K8s needs manual ordering
- Jobs vs Services in Docker

5. **Networking**:

**Docker (compose.yaml)**:
```yaml
networks:
  test-network:
    driver: bridge
```

**Kubernetes (base/networking/)**:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-network-policy
spec:
  podSelector:
    matchLabels:
      app: testapi
  policyTypes:
  - Ingress
  - Egress
```
Docker and Kubernetes configurations side by side (COnsole app):

### 1. Main Container Configuration

**Docker (Dockerfile.console)**:
```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
COPY ["TestConsoleApp/TestConsoleApp.csproj", "TestConsoleApp/"]
RUN dotnet restore "TestConsoleApp/TestConsoleApp.csproj"
COPY . .
WORKDIR "/src/TestConsoleApp"
RUN dotnet build "TestConsoleApp.csproj" -c $BUILD_CONFIGURATION -o /app/build
FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "TestConsoleApp.csproj" -c $BUILD_CONFIGURATION -o /app/publish
FROM build AS final
USER $APP_UID
WORKDIR /app
COPY --from=publish /app/publish .
CMD ["tail", "-f", "/dev/null"]
```

**Kubernetes (base/deployments/console-deployment.yaml)**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: testconsole
spec:
  template:
    spec:
      containers:
      - name: testconsole
        image: mcr.microsoft.com/dotnet/sdk:9.0
        workingDir: /src/TestConsoleApp
        command: ["dotnet"]
        args: ["watch", "run", "--no-restore"]
```

Key Differences:
- Docker builds an image, K8s uses base image directly
- Docker copies code, K8s mounts it
- Docker runs in production mode, K8s in development mode

### 2. Environment Configuration

**Docker (.env)**:
```dotenv
AllowedWebsites="http://localhost:8092"
FileConfig__InputFolder="/input"
FileConfig__OutputFolder="/output"
Host_FileConfig_Input="~/testconsole"
Host_FileConfig_Output="~/testconsole/outd"
```

**Kubernetes (base/configmaps/console-config.yaml)**:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: console-config
data:
  FileConfig__InputFolder: "/input"
  FileConfig__OutputFolder: "/output"
```

Key Differences:
- Docker uses .env file
- K8s uses ConfigMap
- Environment variables are structured differently

### 3. Service Definition

**Docker (compose.yaml)**:
```yaml
services:
  testconsole:
    image: testconsole
    platform: linux/amd64
    container_name: testconsole
    build:
      context: ../../../app/backend
      dockerfile: ../../deployment/docker/CPU/Dockerfile.console
    networks:
      - test-network
    volumes:
      - ${Host_FileConfig_Input}:${FileConfig__InputFolder}
      - ${Host_FileConfig_Output}:${FileConfig__OutputFolder}
    env_file:
      - .env
```

**Kubernetes (full deployment spec)**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: testconsole
spec:
  replicas: 1
  selector:
    matchLabels:
      app: testconsole
  template:
    metadata:
      labels:
        app: testconsole
    spec:
      containers:
      - name: testconsole
        image: mcr.microsoft.com/dotnet/sdk:9.0
        env:
        - name: FileConfig__InputFolder
          value: "/input"
        - name: FileConfig__OutputFolder
          value: "/output"
        volumeMounts:
        - name: console-source
          mountPath: /src
        - name: input-volume
          mountPath: /input
        - name: output-volume
          mountPath: /output
      volumes:
      - name: console-source
        hostPath:
          path: /root/app/backend
          type: Directory
      - name: input-volume
        hostPath:
          path: /root/testconsole
          type: Directory
      - name: output-volume
        hostPath:
          path: /root/testconsole/outd
          type: Directory
```

Key Differences:
- Volume mounting syntax
  - Docker: Simple path mapping
  - K8s: More verbose with separate volume definitions
- Networking
  - Docker: Simple network name
  - K8s: Uses labels and selectors
- Configuration
  - Docker: Build and runtime in one file
  - K8s: Separates concerns into deployment, config, and volumes

### 4. Environment Variables

**Docker**:
```yaml
env_file:
  - .env
```

**Kubernetes**:
```yaml
env:
- name: FileConfig__InputFolder
  value: "/input"
- name: FileConfig__OutputFolder
  value: "/output"
```

### 5. Volume Mounting

**Docker**:
```yaml
volumes:
  - ${Host_FileConfig_Input}:${FileConfig__InputFolder}
  - ${Host_FileConfig_Output}:${FileConfig__OutputFolder}
```

**Kubernetes**:
```yaml
volumeMounts:
- name: input-volume
  mountPath: /input
- name: output-volume
  mountPath: /output
volumes:
- name: input-volume
  hostPath:
    path: /root/testconsole
- name: output-volume
  hostPath:
    path: /root/testconsole/outd
```
Key differences:
- Docker uses simple bridge network
- K8s uses NetworkPolicies for fine-grained control
- K8s adds Ingress for external access

The main differences are:
1. **Development Mode**:
   - Docker builds images
   - K8s mounts code and runs in dev mode

2. **Configuration**:
   - Docker uses .env files
   - K8s uses ConfigMaps and Secrets

3. **Networking**:
   - Docker uses simple bridge network
   - K8s uses Services and NetworkPolicies

4. **Storage**:
   - Docker uses direct volume mounts
   - K8s uses PV/PVC system