# Dockerfile
FROM vllm/vllm-openai:latest

WORKDIR /vllm-workspace

COPY start.sh /vllm-workspace/
COPY python/* /vllm-workspace/
RUN mkdir -p /root/.cache/huggingface

# Fix NCCL permissions
RUN chmod -R 755 /root/.config/vllm/nccl

ENTRYPOINT ["/vllm-workspace/start.sh"]