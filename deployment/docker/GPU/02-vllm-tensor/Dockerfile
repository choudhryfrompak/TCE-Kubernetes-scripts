FROM vllm/vllm-openai:latest

WORKDIR /vllm-workspace

COPY start.sh /vllm-workspace/
COPY ../../../../app/python /vllm-workspace/
RUN chmod +x /vllm-app/start.sh

RUN mkdir -p /root/.cache/huggingface