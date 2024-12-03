FROM vllm/vllm-openai:latest
WORKDIR /vllm-workspace
RUN mkdir -p /vllm-workspace/app/ /vllm-workspace/benchmark/
COPY deployment/docker/GPU/vllm/02-vllm/start.sh /vllm-workspace/
COPY app/python/* /vllm-workspace/benchmark
RUN rm -rf /vllm-workspace/examples && \
    chmod +x /vllm-workspace/start.sh && \
    mkdir -p /root/.cache/huggingface
ENTRYPOINT ["tail", "-f", "/dev/null"]
