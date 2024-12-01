# vLLM Tensor Parallel Setup Guide

## Prerequisites
- Docker installed
- NVIDIA Container Toolkit installed
- At least 2 GPUs available
- HuggingFace model cache available at `/root/.cache/huggingface` if not downloaded:

## Quick Setup
```bash
cd TCE-Kubernetes-scripts/deployment/docker/GPU/vllm
```
## Download Model:
```bash
cd 01-Download-model
chmod +x huggingface.sh
./huggingface.sh
#enter you api-key
#enter model name
#model will be downloaded at `/root/.cache/huggingface`
```



1. setup-inference:
```bash
cd ../02-vllm-tensor
```
4. Start container:
```bash
docker compose up -d

# Check container is running
docker ps
```

5. Run inference:
```bash
# Enter container
docker exec -it vllm-tensor-vllm-1 /bin/bash

# Inside container
python3 benchmark-offline-serving.py
```

## Troubleshooting
- Ensure HuggingFace cache mounted correctly
- Verify all GPUs are accessible with `nvidia-smi`