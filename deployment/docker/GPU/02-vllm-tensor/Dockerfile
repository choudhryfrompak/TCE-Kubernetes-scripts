# Dockerfile
FROM vllm/vllm-openai:latest

WORKDIR /vllm-workspace

COPY start.sh /vllm-workspace/
COPY python/* /vllm-workspace/
RUN chmod +x /vllm-workspace/start.sh
RUN mkdir -p /root/.cache/huggingface

ENTRYPOINT ["/vllm-workspace/start.sh"]