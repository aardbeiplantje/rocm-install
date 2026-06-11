#!/bin/bash


export TARGET_DIR=${TARGET_DIR:-"$HOME/rocm"}
export XDG_CACHE_HOME=${XDG_CACHE_HOME:-/var/tmp/pip-cache}
export PIP_BREAK_SYSTEM_PACKAGES=1
export THEROCK_DIR=${ROCM_PATH?Need ROCM_PATH}
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
if [ "${INSTALL_THE_ROCK:-0}" = 0 ]; then
    echo "Skipping TheRock install. Set INSTALL_THE_ROCK=1 to install it."
else
    THEROCK_VERSION=${THEROCK_VERSION?Need THEROCK_VERSION=7.12.0a20260205}
    THEROCK_TAR=therock-dist-linux-gfx1151-${THEROCK_VERSION}.tar.gz
    THEROCK_DIR=${ROCM_PATH:-"$TARGET_DIR/rocm-$THEROCK_VERSION"}
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
fi

# uninstall tensorflow-rocm + install tf-keras
python3 -m pip install --prefer-binary --upgrade \
    --index-url https://repo.amd.com/rocm/whl/gfx1151/ \
    "rocm[libraries,devel]" \
    torch \
    torchvision \
    torchaudio \
    || exit $?
python3 -m pip install --prefer-binary --upgrade \
    --extra-index-url https://repo.amd.com/rocm/whl/gfx1151/ \
    "jax_rocm7_plugin==0.9.1+rocm7.13.0" \
    "jax_rocm7_pjrt==0.9.1+rocm7.13.0" \
    "triton==3.6.0+rocm7.13.0" \
    tf-keras \
    || exit $?
python3 -m pip install --prefer-binary --upgrade \
    "jax==0.9.1" \
    "jaxlib==0.9.1" \
    || exit $?
python3 -m pip install --prefer-binary --upgrade \
    https://rocm.frameworks.amd.com/whl/gfx1151/flash_attn-2.8.3-py3-none-any.whl \
    || exit $?
python3 -m pip install --prefer-binary --upgrade \
    diffusers \
    datasets \
    llamafactory \
    matplotlib \
    huggingface_hub==1.19.0 \
    safetensors \
    tensorboard \
    transformers==5.6.0 \
    awscli \
    || exit $?
python3 -m pip install --prefer-binary --upgrade \
    idna==3.7 \
    kagglehub \
    ninja \
    cmake \
    wheel \
    pybind11 \
    || exit $?



# ultralytics/yolo, but with ROCm PyTorch. Make sure those don't get upgraded
python3 -m pip install --prefer-binary --upgrade \
    --extra-index-url https://repo.amd.com/rocm/whl/gfx1151/ \
    --extra-index-url https://rocm.nightlies.amd.com/v2/gfx1151/ \
    --extra-index-url https://huggingface.github.io/autogptq-index/whl/rocm573/ \
    --extra-index-url https://download.pytorch.org/whl/nightly/rocm7.1 \
    --pre \
    huggingface_hub==1.19.0 \
    ultralytics \
    yolov8 \
    || exit $?
exit;

# reinstall onnxruntime and optimum[onnxruntime] from the ROCm repo to get the
# ROCm version of onnx, and onnxslim. We also install onnxruntime_migraphx and
# onnxruntime-rocm to make sure we get all the dependencies for
# optimum[onnxruntime].
python3 -m pip install --prefer-binary -f https://repo.amd.com/rocm/whl/gfx1151/ \
    transformers==5.6.0 \
    onnxruntime_migraphx \
    onnxruntime-rocm \
    onnx \
    onnxslim \
    optimum[onnxruntime] \
    || exit $?
