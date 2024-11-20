import asyncio
import time
import numpy as np
from openai import AsyncOpenAI
import logging
import argparse
import json

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

async def read_prompts(filename):
    with open(filename, 'r') as f:
        return [line.strip() for line in f if line.strip()]

async def process_stream(stream):
    first_token_time = None
    total_tokens = 0
    full_response = ""
    async for chunk in stream:
        if first_token_time is None:
            first_token_time = time.time()
        if chunk.choices[0].delta.content:
            content = chunk.choices[0].delta.content
            full_response += content
            total_tokens += 1
        if chunk.choices[0].finish_reason is not None:
            break
    return first_token_time, total_tokens, full_response

async def process_batch(client, prompts_batch, output_tokens, request_timeout):
    tasks = []
    for prompt in prompts_batch:
        tasks.append(make_request(client, prompt, output_tokens, request_timeout))
    return await asyncio.gather(*tasks)

async def make_request(client, prompt, output_tokens, request_timeout):
    start_time = time.time()
    try:
        stream = await client.chat.completions.create(
            model="ministral",
            messages=[
                {"role": "user", "content": prompt}
            ],
            max_tokens=output_tokens,
            stream=True
        )
        first_token_time, total_tokens, response = await asyncio.wait_for(
            process_stream(stream),
            timeout=request_timeout
        )

        end_time = time.time()
        elapsed_time = end_time - start_time
        ttft = first_token_time - start_time if first_token_time else None
        tokens_per_second = total_tokens / elapsed_time if elapsed_time > 0 else 0

        return {
            "prompt": prompt,
            "response": response,
            "metrics": {
                "total_tokens": total_tokens,
                "elapsed_time": elapsed_time,
                "tokens_per_second": tokens_per_second,
                "ttft": ttft
            }
        }

    except (asyncio.TimeoutError, Exception) as e:
        logging.error(f"Error processing prompt '{prompt[:50]}...': {str(e)}")
        return None

def calculate_percentile(values, percentile, reverse=False):
    if not values:
        return None
    if reverse:
        return np.percentile(values, 100 - percentile)
    return np.percentile(values, percentile)

async def run_benchmark(prompts_file, batch_size, concurrency, request_timeout,
                       output_tokens, vllm_url, api_key):
    client = AsyncOpenAI(base_url=vllm_url, api_key=api_key)
    prompts = await read_prompts(prompts_file)
    results = []

    # Process prompts in batches
    start_time = time.time()
    for i in range(0, len(prompts), batch_size):
        batch = prompts[i:i+batch_size]
        # Process multiple batches concurrently
        semaphore = asyncio.Semaphore(concurrency)
        async with semaphore:
            batch_results = await process_batch(
                client, batch, output_tokens, request_timeout
            )
            results.extend([r for r in batch_results if r is not None])

        logging.info(f"Completed batch {i//batch_size + 1}/{len(prompts)//batch_size + 1}")

    end_time = time.time()

    # Calculate metrics
    total_elapsed_time = end_time - start_time
    metrics = [r["metrics"] for r in results]

    total_tokens = sum(m["total_tokens"] for m in metrics)
    latencies = [m["elapsed_time"] for m in metrics]
    tokens_per_second_list = [m["tokens_per_second"] for m in metrics]
    ttft_list = [m["ttft"] for m in metrics]

    successful_requests = len(results)
    requests_per_second = successful_requests / total_elapsed_time if total_elapsed_time > 0 else 0

    # Calculate averages and percentiles
    percentiles = [50, 95, 99]

    return {
        "total_prompts": len(prompts),
        "successful_requests": successful_requests,
        "batch_size": batch_size,
        "concurrency": concurrency,
        "request_timeout": request_timeout,
        "max_output_tokens": output_tokens,
        "total_time": total_elapsed_time,
        "requests_per_second": requests_per_second,
        "total_output_tokens": total_tokens,
        "latency": {
            "average": np.mean(latencies),
            "p50": calculate_percentile(latencies, 50),
            "p95": calculate_percentile(latencies, 95),
            "p99": calculate_percentile(latencies, 99)
        },
        "tokens_per_second": {
            "average": np.mean(tokens_per_second_list),
            "p50": calculate_percentile(tokens_per_second_list, 50, True),
            "p95": calculate_percentile(tokens_per_second_list, 95, True),
            "p99": calculate_percentile(tokens_per_second_list, 99, True)
        },
        "time_to_first_token": {
            "average": np.mean(ttft_list),
            "p50": calculate_percentile(ttft_list, 50),
            "p95": calculate_percentile(ttft_list, 95),
            "p99": calculate_percentile(ttft_list, 99)
        },
        "responses": [{"prompt": r["prompt"], "response": r["response"]} for r in results]
    }

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Batch API benchmark for vLLM")
    parser.add_argument("--prompts_file", type=str, required=True, help="File containing prompts")
    parser.add_argument("--batch_size", type=int, required=True, help="Number of prompts per batch")
    parser.add_argument("--concurrency", type=int, required=True, help="Number of concurrent batches")
    parser.add_argument("--request_timeout", type=int, default=30, help="Timeout for each request in seconds")
    parser.add_argument("--output_tokens", type=int, default=50, help="Number of output tokens")
    parser.add_argument("--vllm_url", type=str, required=True, help="vLLM server URL")
    parser.add_argument("--api_key", type=str, required=True, help="API key")
    args = parser.parse_args()

    results = asyncio.run(run_benchmark(
        args.prompts_file, args.batch_size, args.concurrency,
        args.request_timeout, args.output_tokens, args.vllm_url, args.api_key
    ))
    print(json.dumps(results, indent=2))
