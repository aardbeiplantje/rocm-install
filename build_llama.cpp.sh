#!/bin/bash

cd ~/llama.cpp || exit 1

# Set environment variables explicitly for ROCm 7.10
export HIP_PLATFORM=amd
export ROCM_PATH=${ROCM_PATH:-~/therock-dist-linux-gfx1151-7.12.0a20260203}
export HIP_PATH=$ROCM_PATH

# This is the critical fix: The compiler needs to know where the bitcode is
export HIP_DEVICE_LIB_PATH=$ROCM_PATH/lib/llvm/amdgcn/bitcode
export HIP_DEVICE_LIB_PATH=$ROCM_PATH/lib/llvm/lib/clang/22/lib/amdgcn/bitcode

echo HIP_DEVICE_LIB_PATH $HIP_DEVICE_LIB_PATH

# Configure with explicit compiler paths and architecture
# We add --rocm-path directly to the HIP flags to stop Clang from complaining
mkdir -p build && cd build || exit 1
cmake .. \
    -DCMAKE_SYSTEM_PROCESSOR=x86_64 \
    -DGGML_NATIVE=ON \
    -DGGML_HIP=ON \
    -DGGML_HIP_UMA=ON \
    -DCMAKE_C_FLAGS="-march=native -O3" \
    -DCMAKE_CXX_FLAGS="-march=native -O3" \
    -DCMAKE_HIP_COMPILER=$ROCM_PATH/llvm/bin/clang++ \
    -DCMAKE_CXX_COMPILER=$ROCM_PATH/llvm/bin/clang++ \
    -DCMAKE_C_COMPILER=$ROCM_PATH/llvm/bin/clang \
    -DCMAKE_HIP_FLAGS="--rocm-device-lib-path=$HIP_DEVICE_LIB_PATH" \
    -DLLAMA_BUILD_TESTS=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DAMDGPU_TARGETS=gfx1151 \
    -DGPU_TARGETS="gfx1151" \
    -DBUILD_SHARED_LIBS=ON \
    -DLLAMA_BUILD_TESTS=OFF \
    -DGGML_HIP=ON \
    -DGGML_OPENMP=OFF \
    -DGGML_CUDA_FORCE_CUBLAS=OFF \
    -DGGML_HIP_ROCWMMA_FATTN=ON \
    -DGGML_STATIC=OFF \
    -DCMAKE_SYSTEM_NAME=Linux

# Build with all cores
cd ..
cmake --build build --config Release -j$(nproc)
