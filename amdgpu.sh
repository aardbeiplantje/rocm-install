#!/bin/bash
sudo bash <<"EOF"
echo -ne "MES parameter:"
cat /sys/module/amdgpu/parameters/mes
#echo high > /sys/class/drm/card*/device/power_dpm_force_performance_level
echo "echo manual > /sys/class/drm/card*/device/power_dpm_force_performance_level"
echo auto > /sys/class/drm/card*/device/power_dpm_force_performance_level
echo manual > /sys/class/drm/card*/device/power_dpm_force_performance_level
for i in /sys/devices/system/cpu/cpu*; do
    if [ "$i" == "/sys/devices/system/cpu/cpufreq" -o "$i" == "/sys/devices/system/cpu/cpuidle" ]; then
        continue
    fi
    echo "balance_performance > $i/cpufreq/energy_performance_preference"
    echo balance_performance > $i/cpufreq/energy_performance_preference
    echo -ne "CUR:"
    cat $i/cpufreq/scaling_cur_freq
    echo "5187000 > $i/cpufreq/scaling_max_freq"
    echo 5187000 > $i/cpufreq/scaling_max_freq
    cat $i/cpufreq/scaling_max_freq
    echo -ne "CUR:"
    cat $i/cpufreq/scaling_cur_freq
done
echo "NUMA balancing off"
echo 0 > /proc/sys/kernel/numa_balancing
cat /proc/sys/kernel/numa_balancing
EOF

export ROCM_PATH=${ROCM_PATH?"ROCM_PATH environment variable is not set. Please set it to the path of your ROCm installation."}
export LD_LIBRARY_PATH=${ROCM_PATH}:$LD_LIBRARY_PATH
export PATH=$ROCM_PATH/bin:$PATH
if [ -f ~/rocm/bin/activate ]; then
    source ~/rocm/bin/activate
fi
export HF_HUB_ENABLE_HF_TRANSFER=0
export HF_HUB_DISABLE_XET=1
export HF_HOME="/mnt/data/huggingface"
export HF_DATASETS_CACHE="/mnt/data/huggingface/datasets"
export HF_HUB_CACHE="/mnt/data/huggingface/hub"
export FLASH_ATTENTION_TRITON_AMD_ENABLE="TRUE"
export PYTORCH_ROCM_ARCH="gfx1151"
export HSA_OVERRIDE_GFX_VERSION=11.0.0
export PIP_BREAK_SYSTEM_PACKAGES=1
export LLVM_PATH=~/rocm/llvm
export KAGGLEHUB_CACHE=/mnt/data/kaggle-hub
export XDG_CACHE_HOME="/var/tmp/pip-cache"
export TMPDIR="/var/tmp"
#export PYTORCH_HIP_ALLOC_CONF=garbage_collection_threshold:0.6,max_split_size_mb:6144

rocm-smi --setperflevel high
rocm-smi --setperflevel auto
rocm-smi --showtoponuma
