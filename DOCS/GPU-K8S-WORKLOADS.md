# 1. vLLM Benchmarking and Serving Project

## Project Structure
This project uses the image built by Docker compose in the GPU-DOCKER-WORKLOADS.md
```
vllm/
├── benchmark-scripts/          # Benchmarking utilities
├── offline-serving/           # Offline serving configurations
│   ├── pipeline-base/        # Pipeline-based deployment
│   └── tensor-base/         # Tensor-based deployment
└── online-serving/           # Online serving configurations
    ├── pipeline-base/        # Pipeline-based deployment
    └── tensor-base/         # Tensor-based deployment
```

## Features

- Online and offline serving modes
- Pipeline-based and tensor-based deployment options
- Kubernetes-ready configurations
- Comprehensive benchmarking scripts inside the containers.

### Serving Configurations

Both online and offline serving modes include:

1. Pipeline-parallel Deployment:
   - Head deployment configuration //you can edit to change number of gpus
   - Worker deployment configuration //you can edit to change number of gpus
   - Service definitions
   - Namespace configuration
   - Kustomization settings

2. Tensor-parallel Deployment:
   - Head deployment configuration(only) //you can edit to change number of gpus
   - Service definitions
   - Namespace configuration
   - Kustomization settings
## Setup and Deployment

### Prerequisites

- Kubernetes cluster

### Deployment Steps
```bash
cd TCE-Kubernetes-scripts/deployment/kubernetes/GPU-K8s/06-kustomize/vllm/
```

1. Go to the specific directory:
```bash
   cd <online-serving|offline-serving>
```

2. Select deployment type:
```bash
   cd <pipeline-base|tensor-base>
```
### edit the configs if you want.
3. Apply Kubernetes configurations:
```bash
   kubectl apply -k .
```

### Running Benchmarks

1. exec into the pod
```bash
kubectl exec -it -n vllm-<tag> pods/<pod-name> -- /bin/bash

you can get these details by running:
kubectl get all -n vllm-online|vllm-offline
```
2. Run offline benchmarks:
```bash
   cd app/benchmark/
   python3 benchmark-offline-serving.py
```

3. Run online benchmarks:
```bash
   python examples/benchmark-online-serving.py
```