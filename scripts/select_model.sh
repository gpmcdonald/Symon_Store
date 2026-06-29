#!/usr/bin/env bash
set -euo pipefail

detect_vram_mb() {
  local vram=""

  # Preferred on modern NVIDIA container stacks
  if command -v nvidia-container-cli >/dev/null 2>&1; then
    # Example line contains: "FB Memory Usage ... Total : 24564 MiB"
    vram="$(nvidia-container-cli info 2>/dev/null \
      | awk '/Total[[:space:]]*:[[:space:]]*[0-9]+[[:space:]]*MiB/ {print $(NF-1); exit}')"
  fi

  # Optional legacy fallback
  if ! [[ "${vram:-}" =~ ^[0-9]+$ ]] && command -v nvidia-smi >/dev/null 2>&1; then
    vram="$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | head -n1)"
  fi

  # Final validation
  if [[ "${vram:-}" =~ ^[0-9]+$ ]]; then
    echo "$vram"
  else
    echo ""
  fi
}

VRAM_MB="$(detect_vram_mb)"

# Safe defaults
MODEL_FILE="Qwen2.5-Coder-0.5B-Instruct-Q4_K_M.gguf"
CTX_SIZE=32768

if [[ -n "$VRAM_MB" ]]; then
  if (( VRAM_MB >= 20000 )); then
    MODEL_FILE="Qwen2.5-Coder-14B-Instruct-Q4_K_M.gguf"
    CTX_SIZE=16384
  elif (( VRAM_MB >= 14000 )); then
    MODEL_FILE="Qwen2.5-Coder-7B-Instruct-Q4_K_M.gguf"
    CTX_SIZE=16384
  elif (( VRAM_MB >= 10000 )); then
    MODEL_FILE="Qwen2.5-Coder-3B-Instruct-Q4_K_M.gguf"
    CTX_SIZE=24576
  elif (( VRAM_MB >= 7000 )); then
    MODEL_FILE="Qwen2.5-Coder-1.5B-Instruct-Q4_K_M.gguf"
    CTX_SIZE=32768
  fi
else
  echo "GPU VRAM probe unavailable; using safe default: ${MODEL_FILE}" >&2
fi

MODEL_REPO="https://huggingface.co/bartowski/${MODEL_FILE%-Q4_K_M.gguf}-GGUF/resolve/main/${MODEL_FILE}"
MODEL_AIS_URI="ais://symon_store/${MODEL_FILE}"
MODEL_PATH="$HOME/models/${MODEL_FILE}"

cat <<EOF
MODEL_FILE=${MODEL_FILE}
CTX_SIZE=${CTX_SIZE}
MODEL_REPO=${MODEL_REPO}
MODEL_AIS_URI=${MODEL_AIS_URI}
MODEL_PATH=${MODEL_PATH}
EOF
