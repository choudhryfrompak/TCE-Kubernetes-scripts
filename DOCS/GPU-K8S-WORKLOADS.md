# 1. vLLM Benchmarking and Serving Project

## Project Structure

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
- Comprehensive benchmarking scripts

## Components

### Benchmark Scripts

- `benchmark-offline-serving.py`: Script for measuring offline serving performance
- `benchmark-online-serving.py`: Script for measuring online serving performance
- `commands.txt`: Common commands and usage examples
- `prompts.txt`: Sample prompts for benchmarking

These will be mounted inside the containers.

### Serving Configurations

Both online and offline serving modes include:

1. Pipeline-parallel Deployment:
   - Head deployment configuration //you can edit to change number of gpus
   - Worker deployment configuration //you can edit to change number of gpus
   - Service definitions
   - Namespace configuration
   - Kustomization settings

2. Tensor-parallel Deployment:
   - Similar structure to pipeline-based deployment
   -  tensor-parallel configurations.

## Setup and Deployment

### Prerequisites

- Kubernetes cluster

### Deployment Steps

1. Choose serving mode (online/offline):
   ```bash
   cd <online-serving|offline-serving>
   ```

2. Select deployment type:
   ```bash
   cd <pipeline-base|tensor-base>
   ```

3. Apply Kubernetes configurations:
   ```bash
   kubectl apply -k .
   ```

### Running Benchmarks

1. Set up your Python environment:
   ```bash
   pip install -r requirements.txt
   ```
2. exec into the pod
```bash
kubectl exec -it -n vllm-<tag> pods/<pod-name> -- /bin/bash

you can get these details by running:
kubectl get all -n vllm-online|vllm-offline
```
3. Run offline benchmarks:
   ```bash
   python examples/benchmark-offline-serving.py
   ```

4. Run online benchmarks:
   ```bash
   python examples/benchmark-online-serving.py
   ```