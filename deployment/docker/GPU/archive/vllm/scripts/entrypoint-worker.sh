#!/bin/bash

# Wait for head node
until nc -z $HEAD_SERVICE_HOST $RAY_PORT; do
    echo "Waiting for head node..."
    sleep 2
done

# Start Ray worker
ray start --address=$HEAD_SERVICE_HOST:$RAY_PORT --block
