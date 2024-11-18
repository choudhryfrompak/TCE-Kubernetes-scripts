#!/bin/bash

# Create the directory structure
mkdir -p base overlays/{development,production}

# Create base files
cat > base/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namePrefix: vllm-
namespace: vllm-cluster

resources:
- namespace.yaml
- head-deployment.yaml
- worker-deployment.yaml
- service.yaml

configMapGenerator:
- name: vllm-config
  literals:
  - RAY_PORT=6379
  - VLLM_PORT=8000

commonLabels:
  app.kubernetes.io/name: vllm
  app.kubernetes.io/instance: vllm-cluster
EOF

cat > base/namespace.yaml << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: vllm-cluster
EOF

cat > base/head-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: head
spec:
  replicas: 1
  selector:
    matchLabels:
      component: head
  template:
    metadata:
      labels:
        component: head
    spec:
      nodeSelector:
        role: master
      containers:
      - name: vllm-head
        image: vllm/vllm-openai:latest
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 6379
          name: ray
        - containerPort: 8000
          name: vllm
        resources:
          limits:
            nvidia.com/gpu: 1
          requests:
            nvidia.com/gpu: 1
        volumeMounts:
        - name: huggingface-cache
          mountPath: /root/.cache/huggingface
        - name: model-cache
          mountPath: /vllm-workspace/examples
        command:
        - "/bin/sh"
        - "-c"
        - "ray start --head --port=6379 --block && tail -f /dev/null"
      volumes:
      - name: huggingface-cache
        hostPath:
          path: /root/.cache/huggingface
      - name: benchmarks
        hostPath:
          path: /home/ubuntu/models
EOF

cat > base/worker-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: worker
spec:
  selector:
    matchLabels:
      component: worker
  template:
    metadata:
      labels:
        component: worker
    spec:
      nodeSelector:
        role: worker
      tolerations:
      - key: "role"
        operator: "Equal"
        value: "worker"
        effect: "NoSchedule"
      containers:
      - name: vllm-worker
        image: vllm/vllm-openai:latest
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 8000
          name: vllm
        resources:
          limits:
            nvidia.com/gpu: 1
          requests:
            nvidia.com/gpu: 1
        volumeMounts:
        - name: huggingface-cache
          mountPath: /root/.cache/huggingface
        - name: model-cache
          mountPath: /vllm-workspace/examples
        command:
        - "/bin/sh"
        - "-c"
        - "ray start --address=$(VLLM_HEAD_SERVICE):6379 --block"
        env:
        - name: VLLM_HEAD_SERVICE
          value: vllm-head-service
      volumes:
      - name: huggingface-cache
        hostPath:
          path: /root/.cache/huggingface
      - name: benchmarks
        hostPath:
          path: /home/ubuntu/models
EOF

cat > base/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: head-service
spec:
  type: ClusterIP
  selector:
    component: head
  ports:
  - protocol: TCP
    port: 6379
    targetPort: ray
    name: ray
---
apiVersion: v1
kind: Service
metadata:
  name: vllm-service
spec:
  type: NodePort
  selector:
    component: head
  ports:
  - protocol: TCP
    port: 8000
    targetPort: vllm
    name: vllm
    nodePort: 30080
EOF

# Create development overlay files
cat > overlays/development/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namePrefix: dev-
namespace: vllm-cluster-dev

resources:
- ../../base

patches:
- path: resources-patch.yaml
EOF

cat > overlays/development/resources-patch.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vllm-head
spec:
  template:
    spec:
      containers:
      - name: vllm-head
        resources:
          limits:
            nvidia.com/gpu: 1
          requests:
            nvidia.com/gpu: 1
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: vllm-worker
spec:
  template:
    spec:
      containers:
      - name: vllm-worker
        resources:
          limits:
            nvidia.com/gpu: 1
          requests:
            nvidia.com/gpu: 1
EOF

# Create production overlay files
cat > overlays/production/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namePrefix: prod-
namespace: vllm-cluster-prod

resources:
- ../../base

patches:
- path: resources-patch.yaml
EOF

cat > overlays/production/resources-patch.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vllm-head
spec:
  template:
    spec:
      containers:
      - name: vllm-head
        resources:
          limits:
            nvidia.com/gpu: 2
          requests:
            nvidia.com/gpu: 2
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: vllm-worker
spec:
  template:
    spec:
      containers:
      - name: vllm-worker
        resources:
          limits:
            nvidia.com/gpu: 2
          requests:
            nvidia.com/gpu: 2
EOF

echo "Kustomize directory structure and files created successfully!"
echo "To deploy:"
echo "  Development: kubectl apply -k overlays/development"
echo "  Production: kubectl apply -k overlays/production"
