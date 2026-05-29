# ROCm Install & Inference Scripts

This repo contains scripts for installing AMD ROCm drivers and building/running inference tools (llama.cpp, whisper.cpp, LiteLLM) on ROCm-enabled systems.

## Key Scripts

- `rocm_install.sh` - Installs ROCm from a specified version path
- `amdgpu.sh` - AMD GPU related setup
- `build_llama.cpp.sh`, `build_whisper.cpp.sh` - Build scripts for inference runtimes
- `litellm.sh` - LiteLLM server launcher
- `llama_bench.sh`, `llama_cli.sh`, `llama_server.sh` - llama.cpp run commands

## General Rules

- ROCm version is set via `ROCM_PATH`. Default: `/opt/rocm-7.2.0/`
- Do not commit `*.sh~` backup files or anything under `.tmp/`
