# Symon_Store

This repository contains shell scripts used to automate local AI workflow and store/system setup tasks.

## Prerequisites

- Linux/macOS shell environment
- `bash` in your PATH
- Execute permissions on scripts (`chmod +x <script>.sh`)
- Git installed

## Script Integration

Use this structure to keep scripts organized and easy to run:

- `scripts/setup.sh` — system/bootstrap setup
- `scripts/cuda_install.sh` — CUDA/keyring/toolkit install helpers
- `scripts/aistore_setup.sh` — AIStore bootstrap/verify
- `scripts/model_select.sh` — VRAM-based model chooser
- `scripts/llama_server.sh` — starts local llama-server
- `scripts/verify.sh` — end-to-end verification checks

> If your current script names/locations differ, either rename them to this layout or update commands below to match your existing files.

## Quick Start

```bash
git clone https://github.com/gpmcdonald/Symon_Store.git
cd Symon_Store
chmod +x scripts/*.sh
./scripts/setup.sh
```

## Usage

### 1) System/setup

```bash
./scripts/setup.sh
```

### 2) CUDA install flow

```bash
./scripts/cuda_install.sh
```

### 3) AIStore setup

```bash
./scripts/aistore_setup.sh
```

### 4) Select model by VRAM

```bash
source ./scripts/model_select.sh
# Expects MODEL_FILE, MODEL_REPO, CTX_SIZE exported
```

### 5) Start llama server

```bash
./scripts/llama_server.sh
```

### 6) Verify full stack

```bash
./scripts/verify.sh
```

## Suggested Script Template

```bash
#!/usr/bin/env bash
set -euo pipefail

main() {
  echo "Running: $0"
}

main "$@"
```

## Example `scripts/verify.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

lspci | grep -i nvidia
nvidia-smi
ais show cluster
curl http://127.0.0.1:8080/v1/models

echo "Verification complete."
```

## Common Workflows

### First-time setup

```bash
chmod +x scripts/*.sh
./scripts/setup.sh
./scripts/cuda_install.sh
./scripts/aistore_setup.sh
```

### Start serving locally

```bash
source ./scripts/model_select.sh
./scripts/llama_server.sh
```

### Validate environment

```bash
./scripts/verify.sh
```

## Troubleshooting

- **Permission denied**: `chmod +x scripts/*.sh`
- **Command not found**: install dependencies and verify PATH
- **CUDA issues**: reboot and retry `nvidia-smi`
- **Server start issues**: ensure model path exists and port `8080` is free
- **Debug script execution**:

```bash
bash -x ./scripts/setup.sh
```

## Contributing

- Keep scripts idempotent when possible
- Validate input parameters
- Print actionable errors
- Update this README whenever script behavior changes
