#!/usr/bin/env bash
set -euo pipefail

# setup.sh — system/bootstrap setup for the Symon_Store local AI workflow.
# Installs base dependencies, creates required directories, and verifies
# that core tools are available before running other scripts.

MODELS_DIR="${MODELS_DIR:-$HOME/models}"

log()  { echo "[setup] $*"; }
warn() { echo "[setup] WARNING: $*" >&2; }
die()  { echo "[setup] ERROR: $*" >&2; exit 1; }

check_command() {
  local cmd="$1" hint="${2:-install $1}"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    warn "'$cmd' not found — $hint"
    return 1
  fi
  log "'$cmd' found: $(command -v "$cmd")"
}

install_apt_packages() {
  local pkgs=("$@")
  local missing=()
  for pkg in "${pkgs[@]}"; do
    dpkg -s "$pkg" &>/dev/null || missing+=("$pkg")
  done

  if (( ${#missing[@]} == 0 )); then
    log "All required apt packages already installed."
    return
  fi

  log "Installing missing packages: ${missing[*]}"
  sudo apt-get update -qq
  sudo apt-get install -y "${missing[@]}"
}

setup_directories() {
  log "Creating model cache directory: ${MODELS_DIR}"
  mkdir -p "${MODELS_DIR}"
}

check_gpu() {
  log "Checking GPU availability..."
  if check_command nvidia-smi "install NVIDIA drivers"; then
    nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>/dev/null \
      | while IFS=',' read -r name mem; do
          log "  GPU: ${name// /} — VRAM: ${mem// /}"
        done
  else
    warn "nvidia-smi unavailable; GPU-accelerated inference will not be possible."
  fi
}

main() {
  log "Starting Symon_Store bootstrap setup..."

  # Base system packages
  if command -v apt-get >/dev/null 2>&1; then
    install_apt_packages curl git pciutils
  else
    log "apt-get not available; skipping package installation."
    for cmd in curl git; do
      check_command "$cmd" || true
    done
  fi

  setup_directories
  check_gpu

  log "Bootstrap setup complete."
  log "Next steps:"
  log "  ./scripts/cuda_install.sh   — install/verify CUDA toolkit"
  log "  ./scripts/aistore_setup.sh  — bootstrap AIStore"
  log "  source ./scripts/model_select.sh && ./scripts/llama_server.sh — start serving"
}

main "$@"
