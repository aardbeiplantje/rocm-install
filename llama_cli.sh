#!/bin/bash

# --- Environment Setup ---
# Your specific ROCm 7.12 build for gfx1151
export ROCM_PATH=${ROCM_PATH:-~/therock-dist-linux-gfx1151-latest}
export LD_LIBRARY_PATH=$ROCM_PATH/lib:~/llama.cpp/build/

# CRITICAL: Fix for ROCm 7.2+ hipBLASLt workspace faults on Strix Halo
#export ROCBLAS_USE_HIPBLASLT=0

# Enable Unified Memory for that massive 128GB pool
export GGML_CUDA_ENABLE_UNIFIED_MEMORY=1
export HSA_OVERRIDE_GFX_VERSION=11.5.1

# --- Performance Tweaks ---
# Using numactl to bind to the first CCD (0-7) and its local memory. 
# This reduces Infinity Fabric noise while the GPU is slamming the memory controller.
BIND_CMD=""
if command -v numactl &> /dev/null; then
    BIND_CMD="numactl --cpunodebind=0 --membind=0"
fi

exec $BIND_CMD ~/llama.cpp/build/bin/llama-cli \
    -lv 1 \
    -t 8 \
    --prio 3 \
    --context-shift \
    --jinja \
    --temp 0 \
    --top-p 0 \
    --min-p 0 \
    --color on \
    --no-mmap \
    --no-warmup \
    --mlock \
    -ngl 999 \
    --flash-attn on \
    -sm none \
    --batch-size 1024 \
    --ubatch-size 128 \
    "$@"
