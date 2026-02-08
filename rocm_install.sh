#!/bin/bash


export TARGET_DIR=${TARGET_DIR:-"$HOME/rocm"}
export XDG_CACHE_HOME="/var/tmp/pip-cache"
export TMPDIR="/var/tmp"
export PIP_BREAK_SYSTEM_PACKAGES=1
export THEROCK_VERSION=7.12.0a20260203
export THEROCK_TAR=therock-dist-linux-gfx1151-${THEROCK_VERSION}.tar.gz
export THEROCK_DIR=${ROCM_PATH:-"$TARGET_DIR/rocm-$THEROCK_VERSION"}
export LLVM_PATH="$THEROCK_DIR/llvm"
export CXX_INCLUDE_PATH=$THEROCK_DIR/include
export LD_LIBRARY_PATH=$THEROCK_DIR/lib:$THEROCK_DIR/lib64
export PATH=$THEROCK_DIR/bin:$TARGET_DIR/bin:$PATH

ROCM_VERSION=$THEROCK_VERSION

# from https://rocm.nightlies.amd.com/v2/gfx1151/torch/
#TORCH_VERSION=2.9.1+rocm$ROCM_VERSION
#TORCHAUDIO_VERSION=2.9.0+rocm$ROCM_VERSION
#TORCHVISION_VERSION=0.22.1+rocm$ROCM_VERSION

# from https://repo.radeon.com/rocm/manylinux/rocm-rel-7.2/
#TORCH_VERSION=2.10.0.dev20260113+Brocm7.2.0.lw.gitdea53f5b
#TORCHAUDIO_VERSION=2.10.0+rocm7.2.0.git3b0e7a6f
#TORCHVISION_VERSION=0.25.0+rocm7.2.0.gitaa35ca19
#TRITON_VERSION=3.5.1+rocm7.2.0.gita272dfa8

# from https://download.pytorch.org/whl/nightly/rocm7.1/
#TORCH_VERSION=2.11.0.dev20260204+rocm7.1
#TORCHVISION_VERSION=0.26.0.dev20260206+rocm7.1
#TORCHAUDIO_VERSION=2.11.0.dev20260206+rocm7.1
#TRITON_VERSION=3.6.0+git9844da95


# setup directories
mkdir -p "${XDG_CACHE_HOME}" "${TMPDIR}" "${TARGET_DIR}" \
    || exit $?

# install amdgpu driver
amdgpu_deb="${XDG_CACHE_HOME}/amdgpu-install_7.2.70200-1_all.deb"
if [ ! -f "${amdgpu_deb}" ]; then
    (
    cd "${XDG_CACHE_HOME}" && \
        wget https://repo.radeon.com/amdgpu-install/latest/ubuntu/noble/${amdgpu_deb##*/} || exit $?
    ) || exit $?
fi
#sudo apt install ${amdgpu_deb} -y
#sudo apt install amdgpu-install -y
#sudo amdgpu-install --usecase=rocm,hiplibsdk,graphics,mllib,mlsdk,openmpsdk,openclsdk,opencl,lrt,rocmdevtools,rocmdev --no-dkms -y


# Install python3-venv if not already installed
#sudo apt install python3-venv -y

# create a venv in TARGET_DIR
python3 -m venv "$TARGET_DIR" \
    || exit $?
source "$TARGET_DIR/bin/activate" \
    || exit $?

# untar TheRock ROCm tarball in the venv TARGET_DIR
if [ ! -d "$THEROCK_DIR" ]; then
    echo "Downloading TheRock ROCm tarball..."
    if [ ! -f "${XDG_CACHE_HOME}/$THEROCK_TAR" ]; then
        (
        cd "${XDG_CACHE_HOME}" && \
            wget https://therock-nightly-tarball.s3.amazonaws.com/$THEROCK_TAR \
                || exit $?
        ) || exit $?
    fi
    echo "Extracting TheRock ROCm tarball..."
    mkdir -p "$THEROCK_DIR" \
        || exit $?
    tar -C "$THEROCK_DIR" -xzf "${XDG_CACHE_HOME}/$THEROCK_TAR" \
        || exit $?
else
    echo "TheRock ROCm directory already exists. Skipping extraction."
fi

   # https://repo.radeon.com/rocm/manylinux/rocm-rel-7.2/torch-2.7.1%2Brocm7.2.0.lw.git262e50d5-cp312-cp312-linux_x86_64.whl \
   # https://repo.radeon.com/rocm/manylinux/rocm-rel-7.2/torchaudio-2.9.0%2Brocm7.2.0.gite3c6ee2b-cp312-cp312-linux_x86_64.whl \
   # https://repo.radeon.com/rocm/manylinux/rocm-rel-7.2/torchvision-0.25.0%2Brocm7.2.0.gitaa35ca19-cp312-cp312-linux_x86_64.whl \
   # https://repo.radeon.com/rocm/manylinux/rocm-rel-7.2/triton-3.3.1%2Brocm7.2.0.git28a7371e-cp312-cp312-linux_x86_64.whl \
   # https://repo.radeon.com/rocm/manylinux/rocm-rel-7.2/tf_nightly_rocm-2.21.0.dev0%2Bselfbuilt-cp312-cp312-manylinux_2_28_x86_64.whl \

python3 -m pip install --prefer-binary --upgrade \
    --upgrade-strategy eager \
    --index-url https://repo.radeon.com/rocm/manylinux/rocm-rel-7.2/ \
    --find-links https://repo.radeon.com/rocm/manylinux/rocm-rel-7.2/ \
    --extra-index-url https://download.pytorch.org/whl/nightly/rocm7.2 \
    --extra-index-url https://pypi.org/simple \
    --extra-index-url https://huggingface.github.io/autogptq-index/whl/rocm573/ \
    --extra-index-url https://rocm.nightlies.amd.com/v2/gfx1151/ \
    --pre \
    "rocm[libraries,devel]" \
    https://repo.radeon.com/rocm/manylinux/rocm-rel-7.2/torch-2.9.1%2Brocm7.2.0.lw.git7e1940d4-cp312-cp312-linux_x86_64.whl \
    https://repo.radeon.com/rocm/manylinux/rocm-rel-7.2/torchvision-0.24.0%2Brocm7.2.0.gitb919bd0c-cp312-cp312-linux_x86_64.whl \
    https://repo.radeon.com/rocm/manylinux/rocm-rel-7.2/torchaudio-2.9.0%2Brocm7.2.0.gite3c6ee2b-cp312-cp312-linux_x86_64.whl \
    https://repo.radeon.com/rocm/manylinux/rocm-rel-7.2/triton-3.5.1%2Brocm7.2.0.gita272dfa8-cp312-cp312-linux_x86_64.whl \
    https://repo.radeon.com/rocm/manylinux/rocm-rel-7.2/tensorflow_rocm-2.20.0.dev0%2Bselfbuilt-cp312-cp312-manylinux_2_28_x86_64.whl \
    torchrl \
    tf-keras \
    jax-rocm7-pjrt \
    jax-rocm7-plugin \
    jax \
    jaxlib \
    https://repo.radeon.com/rocm/manylinux/rocm-rel-7.2/transformer_engine-2.4.0-py3-none-any.whl \
    https://repo.radeon.com/rocm/manylinux/rocm-rel-7.2/transformer_engine_rocm-2.4.0-py3-none-manylinux_2_28_x86_64.whl \
    transformer-engine-rocm \
    'h5py<3.15.0,>=3.11.0' \
    idna==3.7 \
    numpy==2.2.6 \
    "websockets>=12.0" \
    "fsspec[http]<=2025.10.0,>=2023.1.0" \
    'transformers<5,>=4.56.0' \
    transformers==4.56.1 \
    transformer_engine-rocm \
    hf_transfer \
    setuptools==80.10.2 \
    more_itertools \
    amd-debug-tools \
    hip-python \
    datasets \
    safetensors \
    'huggingface-hub<1.0,>=0.34.0' \
    'opencv-python-headless==4.10.0.84' \
    'opencv-python>=4.6.0' \
    idna==3.7 \
    numpy==2.2.6 \
    matplotlib \
    tensorboard \
    "fsspec[http]<=2025.10.0,>=2023.1.0" \
    diffusers \
    || exit $?

python3 -m pip uninstall flash-attn
pip3 install -f https://repo.radeon.com/rocm/manylinux/rocm-rel-7.2/ \
    --prefer-binary \
    optimum[onnxruntime] \
    || exit $?
python3 -m pip uninstall \
    onnxruntime onnxruntime-gpu onnxruntime_migraphx onnxruntime-rocm onnxruntime-genai optimum[onnxruntime] onnx onnxslim -y
    || exit $?
python3 -m pip install --prefer-binary -f https://repo.radeon.com/rocm/manylinux/rocm-rel-7.2/  \
    --prefer-binary \
    onnxruntime_migraphx \
    onnxruntime-rocm \
    onnx \
    onnxslim \
    || exit $?
pip3 install -f https://repo.radeon.com/rocm/manylinux/rocm-rel-7.2/ \
    --prefer-binary \
    optimum[onnxruntime] \
    --no-deps \
    || exit $?
exit

# ultralytics/yolo, but with ROCm PyTorch. Make sure those don't get upgraded
python3 -m pip install --prefer-binary --upgrade \
    --upgrade-strategy eager \
    --extra-index-url https://rocm.nightlies.amd.com/v2/gfx1151/ \
    --extra-index-url https://huggingface.github.io/autogptq-index/whl/rocm573/ \
    --extra-index-url https://download.pytorch.org/whl/nightly/rocm7.1 \
    --pre \
    torch==${TORCH_VERSION} \
    torchaudio==${TORCHAUDIO_VERSION} \
    torchvision==${TORCHVISION_VERSION} \
    triton_rocm==${TRITON_VERSION} \
    idna==3.7 \
    numpy==2.2.6 \
    "fsspec[http]<=2025.10.0,>=2023.1.0" \
    hf \
    kagglehub \
    awscli \
    ultralytics \
    yolov8 \
    'onnx>=1.12.0,<=1.19.1' \
    'onnxslim>=0.1.71' \
    || exit $?

if [ "${INSTALL_VLLM:-0}" = 1 -a -d "$HOME/vllm" ]; then
python3 -m pip install --prefer-binary --upgrade \
    --upgrade-strategy eager \
    --extra-index-url https://rocm.nightlies.amd.com/v2/gfx1151/ \
    --extra-index-url https://huggingface.github.io/autogptq-index/whl/rocm573/ \
    --extra-index-url https://download.pytorch.org/whl/nightly/rocm7.1 \
    --only-binary=:all: \
    --pre \
    torch==${TORCH_VERSION} \
    torchaudio==${TORCHAUDIO_VERSION} \
    torchvision==${TORCHVISION_VERSION} \
    triton_rocm==${TRITON_VERSION} \
    idna==3.7 \
    numpy==2.2.6 \
    ninja cmake wheel pybind11 \
    vllm==0.13.0 \
    || exit $?
fi
