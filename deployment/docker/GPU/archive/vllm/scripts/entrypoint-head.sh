#!/bin/bash

# Start Ray head node
ray start --head --port=$RAY_PORT --block &

if [ "$SERVING_TYPE" = "online" ]; then
    # Wait for Ray to be ready
    sleep 30

    # Start vLLM server with appropriate parallelism
    PARALLEL_ARGS=""
    if [ "$DEPLOYMENT_TYPE" = "pipeline" ]; then
        PARALLEL_ARGS="--tensor-parallel-size 1 --pipeline-parallel-size 2"
    elif [ "$DEPLOYMENT_TYPE" = "tensor" ]; then
        PARALLEL_ARGS="--tensor-parallel-size 2"
    fi

    python3 -m vllm.entrypoints.openai.api_server \
        --port $VLLM_PORT \
        --trust-remote-code \
        --served-model-name $SERVED_MODEL_NAME \
        --model $MODEL_NAME \
        --gpu-memory-utilization $GPU_MEM_UTIL \
        $PARALLEL_ARGS \
        --dtype $USE_DTYPE &
fi

# Keep container running
tail -f /dev/null
