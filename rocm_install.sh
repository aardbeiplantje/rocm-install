#!/bin/bash


export TARGET_DIR=${TARGET_DIR:-"$HOME/rocm"}
export XDG_CACHE_HOME="/var/tmp/pip-cache"
export PIP_BREAK_SYSTEM_PACKAGES=1
export THEROCK_VERSION=7.12.0a20260203
export THEROCK_TAR=therock-dist-linux-gfx1151-${THEROCK_VERSION}.tar.gz
export THEROCK_DIR=${ROCM_PATH:-"$TARGET_DIR/rocm-$THEROCK_VERSION"}
export LLVM_PATH="$THEROCK_DIR/llvm"
export CXX_INCLUDE_PATH=$THEROCK_DIR/include
export LD_LIBRARY_PATH=$THEROCK_DIR/lib:$THEROCK_DIR/lib64
export PATH=$THEROCK_DIR/bin:$TARGET_DIR/bin:$PATH

# setup directories
mkdir -p "${XDG_CACHE_HOME}" "${TARGET_DIR}" \
    || exit $?

# install amdgpu driver
if [ "${INSTALL_AMDGPU:-0}" = 0 ]; then
    echo "Skipping AMDGPU driver installation. Set INSTALL_AMDGPU=1 to install it."
else
    amdgpu_deb="${XDG_CACHE_HOME}/amdgpu-install_7.2.70200-1_all.deb"
    if [ ! -f "${amdgpu_deb}" ]; then
        (
        cd "${XDG_CACHE_HOME}" && \
            wget https://repo.radeon.com/amdgpu-install/latest/ubuntu/noble/${amdgpu_deb##*/} || exit $?
        ) || exit $?
    fi
    sudo apt install ${amdgpu_deb} -y
    sudo apt install amdgpu-install -y
    sudo amdgpu-install --usecase=rocm,hiplibsdk,graphics,mllib,mlsdk,openmpsdk,openclsdk,opencl,lrt,rocmdevtools,rocmdev --no-dkms -y
fi

# Install python3-venv if not already installed
dpkg -s python3-venv &> /dev/null || sudo apt install python3-venv -y

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

# uninstall tensorflow-rocm + install tf-keras
python3 -m pip uninstall tensorflow-rocm -y \
    || exit $?
python3 -m pip install --prefer-binary --upgrade \
    --upgrade-strategy eager \
    --index-url https://repo.radeon.com/rocm/manylinux/rocm-rel-7.2/ \
    --find-links https://repo.radeon.com/rocm/manylinux/rocm-rel-7.2/ \
    --extra-index-url https://download.pytorch.org/whl/nightly/rocm7.2 \
    --extra-index-url https://pypi.org/simple \
    --extra-index-url https://huggingface.github.io/autogptq-index/whl/rocm573/ \
    --extra-index-url https://rocm.nightlies.amd.com/v2/gfx1151/ \
    tf-keras \
    --no-deps \
    || exit $?

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
    https://repo.radeon.com/rocm/manylinux/rocm-rel-7.2/jaxlib-0.8.0%2Brocm7.2.0-cp312-cp312-manylinux_2_27_x86_64.whl \
    https://repo.radeon.com/rocm/manylinux/rocm-rel-7.2/jax_rocm7_plugin-0.8.0%2Brocm7.2.0-cp312-cp312-manylinux_2_28_x86_64.whl \
    https://repo.radeon.com/rocm/manylinux/rocm-rel-7.2/jax_rocm7_pjrt-0.8.0%2Brocm7.2.0-py3-none-manylinux_2_28_x86_64.whl \
    torchrl \
    https://repo.radeon.com/rocm/manylinux/rocm-rel-7.2/transformer_engine-2.4.0-py3-none-any.whl \
    https://repo.radeon.com/rocm/manylinux/rocm-rel-7.2/transformer_engine_rocm-2.4.0-py3-none-manylinux_2_28_x86_64.whl \
    transformer-engine-rocm \
    'h5py<3.15.0,>=3.11.0' \
    idna==3.7 \
    numpy==2.2.6 \
    "websockets>=12.0" \
    "fsspec[http]<=2025.10.0,>=2023.1.0" \
    hf_transfer \
    setuptools==80.10.2 \
    more_itertools \
    amd-debug-tools \
    hip-python \
    datasets \
    safetensors \
    'opencv-python-headless==4.10.0.84' \
    'opencv-python>=4.6.0' \
    idna==3.7 \
    numpy==2.2.6 \
    matplotlib \
    tensorboard \
    huggingface_hub \
    diffusers \
    || exit $?

# this is needed to avoid flash-attn installing the CUDA version of flash-attn
# and then onnxruntime-rocm installing the ROCm version of flash-attn, which
# causes import errors. We need to uninstall flash-attn in between to make sure
# only the ROCm version is installed.
python3 -m pip uninstall flash-attn

# install onnxruntime and optimum[onnxruntime] from the ROCm repo to make sure
# we get all the dependencies
python3 -m pip install -f https://repo.radeon.com/rocm/manylinux/rocm-rel-7.2/ \
    --prefer-binary \
    "fsspec[http]<=2025.10.0,>=2023.1.0" \
    optimum[onnxruntime] \
    || exit $?

# uninstall onnxruntime and optimum[onnxruntime], we will reinstall them later
# to make sure we get the ROCm version of onnx and onnxslim. We also uninstall
# onnxruntime_migraphx and onnxruntime-rocm to make sure we get all the
# dependencies for optimum[onnxruntime].

python3 -m pip uninstall \
    onnxruntime onnxruntime-gpu onnxruntime_migraphx onnxruntime-rocm onnxruntime-genai optimum[onnxruntime] onnx onnxslim -y \
    || exit $?

# reinstall optimum[onnxruntime], disable dependencies to avoid upgrading
# onnxruntime to the non ROCm version
python3 -m pip install -f https://repo.radeon.com/rocm/manylinux/rocm-rel-7.2/ \
    --prefer-binary \
    "fsspec[http]<=2025.10.0,>=2023.1.0" \
    optimum[onnxruntime] \
    --no-deps \
    || exit $?

# reinstall onnxruntime and optimum[onnxruntime] from the ROCm repo to get the
# ROCm version of onnx, and onnxslim. We also install onnxruntime_migraphx and
# onnxruntime-rocm to make sure we get all the dependencies for
# optimum[onnxruntime].
python3 -m pip install --prefer-binary -f https://repo.radeon.com/rocm/manylinux/rocm-rel-7.2/  \
    --prefer-binary \
    "fsspec[http]<=2025.10.0,>=2023.1.0" \
    onnxruntime_migraphx \
    onnxruntime-rocm \
    onnx \
    onnxslim \
    || exit $?

# general support
python3 -m pip install --prefer-binary --upgrade \
    --upgrade-strategy eager \
    "fsspec[http]<=2025.10.0,>=2023.1.0" \
    idna==3.7 \
    kagglehub \
    awscli \
    || exit $?

exit

# ultralytics/yolo, but with ROCm PyTorch. Make sure those don't get upgraded
python3 -m pip install --prefer-binary --upgrade \
    --upgrade-strategy eager \
    --extra-index-url https://rocm.nightlies.amd.com/v2/gfx1151/ \
    --extra-index-url https://huggingface.github.io/autogptq-index/whl/rocm573/ \
    --extra-index-url https://download.pytorch.org/whl/nightly/rocm7.1 \
    --pre \
    numpy==2.2.6 \
    "fsspec[http]<=2025.10.0,>=2023.1.0" \
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
