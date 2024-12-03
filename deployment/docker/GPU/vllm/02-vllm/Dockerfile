# Dockerfile
FROM vllm/vllm-openai:latest

WORKDIR /vllm-workspace

COPY deployment/docker/GPU/vllm/02-vllm-tensor/start.sh /vllm-workspace/
COPY app/python/* /vllm-workspace/
CMD rm -rf /vllm-workspace/examples
RUN chmod +x /vllm-workspace/start.sh
RUN mkdir -p /root/.cache/huggingface