#!/bin/bash

# This script runs llama-bench with optimal settings for prompt processing
# on a ROCm 7.12 build for Strix Halo (gfx1151) GPU.

export ROCM_PATH=${ROCM_PATH:-~/therock-dist-linux-gfx1151-latest}
export LD_LIBRARY_PATH=$ROCM_PATH/lib:~/llama.cpp/build/
echo "Using ROCm from: $ROCM_PATH"

# Fix for ROCm 7.2+ hipBLASLt workspace faults on Strix Halo
export ROCBLAS_USE_HIPBLASLT=1
unset ROCBLAS_USE_HIPBLASLT
export HIPBLASLT_LOG_MASK=32
export HIP_FORCE_DEV_KERNARG=1
# Disabled: MMQ kernels hurt prompt processing performance
# Use auto-detection for optimal kernel selection
export GGML_CUDA_FORCE_MMQ=0

# Enable Unified Memory for that massive 128GB pool
export GGML_CUDA_ENABLE_UNIFIED_MEMORY=1
export GGML_ROCM_FORCE_TILING_ALLOCATOR=1
export HSA_OVERRIDE_GFX_VERSION=11.5.1
export HIP_VISIBLE_DEVICES=0

# Ensure the recurrent states (DeltaNet) are offloaded to the GPU
# This is critical for Qwen3-Next performance
export GGML_HIP_FORCE_RS_GPU=1
export GGML_HIP_FORCE_KV_GPU=1
# HIP graphs can accelerate repetitive prompt processing operations
export GGML_HIP_GRAPHS=1
export GGML_DEBUG=1

export HSA_FORCE_FINE_GRAIN_PCIE=1

# Force a larger workspace
export GGML_HIP_ALLOC_GRAPH_RESERVE=2048
export ROCM_METADATA_WAIT_TIMEOUT=100
export ROCM_ALLOW_INT8_MIXED_PRECISION=1

export LLAMA_LOG_COLORS=1
export LLAMA_LOG_TIMESTAMPS=1
export LLAMA_LOG_PREFIX=1

# SDMA accelerates large memory transfers during prompt processing
export HSA_ENABLE_SDMA=1
export AMD_DEBUG=high

# Using numactl to bind to the first CCD (0-7) and its local memory.
# This reduces Infinity Fabric noise while the GPU is slamming the memory controller.
# With UMA, this also reduces memory latency for large prompt processing bursts.
BIND_CMD=""
if command -v numactl &> /dev/null; then
    BIND_CMD="numactl --cpunodebind=0 --membind=0"
fi

exec $BIND_CMD ~/llama.cpp/build/bin/llama-bench \
    -mmp 0 \
    -b 4096 \
    -ub 1024 \
    -t 8 \
    -tb 8 \
    -fa 1 \
    "$@"
