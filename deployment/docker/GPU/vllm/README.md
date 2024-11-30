# vLLM Docker Deployment

This repository contains Docker configurations for deploying vLLM inference server with different parallelization strategies (Pipeline and Tensor) and serving modes (Online and Offline).

## Project Structure
```
vllm/
├── Dockerfile.base              # Base Dockerfile with common configurations
├── Dockerfile.pipeline-online   # Pipeline parallelism for online serving
├── Dockerfile.pipeline-offline  # Pipeline parallelism for offline serving
├── Dockerfile.tensor-online     # Tensor parallelism for online serving
├── Dockerfile.tensor-offline    # Tensor parallelism for offline serving
├── docker-compose.yaml         # Docker Compose configuration
├── .env                        # Environment variables
└── scripts/
    ├── entrypoint-head.sh     # Entrypoint script for head node
    └── entrypoint-worker.sh   # Entrypoint script for worker nodes
```

## Prerequisites

- Docker and Docker Compose
- NVIDIA Container Toolkit
- NVIDIA drivers compatible with CUDA
- At least one GPU with sufficient VRAM for the model

## Configuration

### Environment Variables

Edit the `.env` file to customize your deployment:

```env
RAY_PORT=6379                   # Ray head node port
VLLM_PORT=8000                 # vLLM serving port
GPU_MEM_UTIL=0.99             # GPU memory utilization
MODEL_NAME=mistralai/Ministral-8B-Instruct-2410  # Model to load
SERVED_MODEL_NAME=ministral    # Name for the served model
TENSOR_PARALLEL_SIZE=1        # Number of GPUs for tensor parallelism
PIPELINE_PARALLEL_SIZE=1      # Number of pipeline stages
USE_DTYPE=half               # Model precision (float16/bfloat16/float32)
WORKER_REPLICAS=1           # Number of worker nodes
DEPLOYMENT_TYPE=pipeline    # pipeline or tensor
SERVING_TYPE=online        # online or offline
```

## Deployment Types

1. **Pipeline Parallelism**:
   - Splits the model across multiple GPUs in a pipeline fashion
   - Better for reducing memory per GPU
   - Use when you have models larger than single GPU memory

2. **Tensor Parallelism**:
   - Splits individual tensors across multiple GPUs
   - Better for throughput in some cases
   - Use when you want to parallelize computation

## Serving Types

1. **Online Serving**:
   - Real-time inference with REST API
   - Suitable for production deployments
   - Exposes OpenAI-compatible API

2. **Offline Serving**:
   - Batch processing capabilities
   - Better for bulk inference tasks
   - No API endpoint exposed

## Getting Started

1. Build the base image:
```bash
docker build -t vllm-base:latest -f Dockerfile.base .
```

2. Set execution permissions for scripts:
```bash
chmod +x scripts/entrypoint-*.sh
```

3. Choose your deployment configuration:

For Pipeline Online:
```bash
DEPLOYMENT_TYPE=pipeline SERVING_TYPE=online docker-compose up
```

For Tensor Offline:
```bash
DEPLOYMENT_TYPE=tensor SERVING_TYPE=offline docker-compose up
```

## API Usage (Online Serving)

Once deployed in online mode, you can interact with the API:

```bash
# Example curl request
curl http://localhost:8080/v1/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "ministral",
    "prompt": "Tell me a joke",
    "max_tokens": 100,
    "temperature": 0.7
  }'
```

## Scaling

To scale worker nodes:
```bash
docker-compose up --scale vllm-worker=3
```

## Monitoring

Monitor your deployment using:
```bash
# View logs
docker-compose logs -f

# Check container status
docker-compose ps
```

## Troubleshooting

1. If head node fails to start:
   - Check GPU availability: `nvidia-smi`
   - Verify port availability: `netstat -tulpn | grep <port>`

2. If workers can't connect:
   - Check network connectivity
   - Verify Ray port is accessible
   - Check logs: `docker-compose logs vllm-worker`

## GPU Requirements

- Pipeline parallel: Minimum 2 GPUs recommended
- Tensor parallel: Minimum 2 GPUs recommended
- Memory requirements depend on model size:
  - Mistral 8B: ~16GB VRAM per GPU with fp16
  - Adjust GPU_MEM_UTIL if needed

## Performance Tuning

1. Memory Optimization:
   - Adjust `GPU_MEM_UTIL` (0.0-1.0)
   - Use `half` precision when possible
   - Consider pipeline parallelism for large models

2. Throughput Optimization:
   - Increase worker replicas
   - Use tensor parallelism for smaller models
   - Adjust batch sizes in client requests