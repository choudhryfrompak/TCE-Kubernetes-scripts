from typing import Any, Dict, List
import os
import numpy as np
import ray
from packaging.version import Version
from ray.util.scheduling_strategies import PlacementGroupSchedulingStrategy
from vllm import LLM, SamplingParams

assert Version(ray.__version__) >= Version(
    "2.22.0"), "Ray version must be at least 2.22.0"

# Create a sampling params object.
sampling_params = SamplingParams(
    temperature=0.8,
    top_p=0.95
)

# Set tensor parallelism per instance.
tensor_parallel_size =2
# Set number of instances. Each instance will use tensor_parallel_size GPUs.
num_instances =1

# Create a class to do batch inference.
class LLMPredictor:
    def __init__(self):
        # Get absolute path to the model
        model_path ='/root/.cache/huggingface/hub/models--mistralai--Ministral-8B-Instruct-2410'

        # Verify model path exists
        if not os.path.exists(model_path):
            raise ValueError(f"Model path does not exist: {model_path}")

        # Create an LLM with local model path
        self.llm = LLM(
            model=model_path,
            tensor_parallel_size=tensor_parallel_size,
            max_num_batched_tokens=24000,
            max_model_len=512,
            max_num_seqs=40,
            dtype='half',
            trust_remote_code=True,
            quantization=None
        )

    def __call__(self, batch: Dict[str, np.ndarray]) -> Dict[str, list]:
        outputs = self.llm.generate(batch["text"], sampling_params)
        prompt: List[str] = []
        generated_text: List[str] = []
        for output in outputs:
            prompt.append(output.prompt)
            generated_text.append(' '.join([o.text for o in output.outputs]))
        return {
            "prompt": prompt,
            "generated_text": generated_text,
        }

# Read input file
ds = ray.data.read_text('prompts.txt')

# For tensor_parallel_size > 1, we need to create placement groups
def scheduling_strategy_fn():
    pg = ray.util.placement_group(
        [{
            "GPU": 1,
            "CPU": int(os.getenv('CPU_PER_GPU', 1))
        }] * tensor_parallel_size,
        strategy="STRICT_SPREAD",
    )
    return dict(scheduling_strategy=PlacementGroupSchedulingStrategy(
        pg, placement_group_capture_child_tasks=True))

resources_kwarg: Dict[str, Any] = {}
if tensor_parallel_size == 1:
    resources_kwarg["num_gpus"] = 1
else:
    resources_kwarg["num_gpus"] = 0
    resources_kwarg["ray_remote_args_fn"] = scheduling_strategy_fn

# Apply batch inference for all input data.
ds = ds.map_batches(
    LLMPredictor,
    concurrency=num_instances,
    batch_size=int(os.getenv('BATCH_SIZE', 40)),
    **resources_kwarg,
)

# Peek first results
outputs = ds.take(limit=5800)
for output in outputs:
    prompt = output["prompt"]
    generated_text = output["generated_text"]
    print(f"Prompt: {prompt!r}, Generated text: {generated_text!r}")

output_file = ('responses.txt')
ds.write_parquet(output_file)
