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
cd ../02-vllm-tensor/vllm/
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
docker exec -it vllm-tce /bin/bash

# Inside container
cd app/benchmark/
python3 benchmark-offline-serving.py
```
## Pushing the image to local registry
### Setup local registry
```bash
docker run -d -p 5000:5000 --name local-registry registry:2
##the local registry will start running on localhost:5000 verify that by :
docker ps
##you should see:
<container-id>   registry:2        "/entrypoint.sh /etc…"   14 hours ago     Up 29 minutes   0.0.0.0:5000->5000/tcp, :::5000->5000/tcp   local-registry
```
### Tag and push the image
```bash
docker tag vllm-tce:latest localhost:5000/vllm-tce:latest
docker push localhost:5000/vllm-tce:latest
```
## Troubleshooting
- Ensure HuggingFace cache mounted correctly
- Verify all GPUs are accessible with `nvidia-smi`