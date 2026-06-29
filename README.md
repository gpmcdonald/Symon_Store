# Custom Local AI Workflow

A copy/paste-friendly setup guide for getting a local AI environment running on **Debian 13 (trixie)** with an **NVIDIA GeForce RTX 5070 Ti**.

## Goal

Follow this guide top to bottom. Each step includes exact commands and a clear outcome so you can move through the setup without guessing.

## What you will set up

- NVIDIA CUDA drivers and toolkit
- NVIDIA AIStore
- `llama.cpp`
- A local `llama-server` endpoint
- OpenCode connected to the local model
- Environment verification

## Before you begin

Make sure you have:

- Debian 13 installed
- Internet access
- Sudo access
- Enough disk space for CUDA, AIStore, and model files

---

## 1) Install required system packages

Run this first:

```bash
sudo apt-get update
sudo apt-get install -y \
  g++ \
  freeglut3-dev \
  build-essential \
  libx11-dev \
  libxmu-dev \
  libxi-dev \
  libglu1-mesa-dev \
  libfreeimage-dev \
  libglfw3-dev
```

### If this fails

- Run `sudo apt-get update` again
- Check your network connection
- Make sure your Debian repositories are enabled

---

## 2) Install NVIDIA CUDA

Official installation guide:
https://docs.nvidia.com/cuda/archive/12.8.0/cuda-installation-guide-linux

### Step 2.1 — Confirm your hardware and OS

Run these commands:

```bash
lspci | grep -i nvidia
uname -m
cat /etc/*release
gcc --version
```

### Expected result

- `lspci` should show your NVIDIA GPU
- `uname -m` should return `x86_64`
- Your OS should be a supported Debian version
- `gcc --version` should work

### If this fails

- If `lspci` shows nothing, check that the GPU is installed and enabled in BIOS
- If `uname -m` is not `x86_64`, this guide may not apply
- If `gcc` is missing, install it with the package step above

### Step 2.2 — Download CUDA

Choose the installer from:

https://developer.nvidia.com/cuda-downloads

If you downloaded a file manually, verify it:

```bash
md5sum <downloaded-file>
```

### Step 2.3 — Install the CUDA keyring

```bash
wget https://developer.download.nvidia.com/compute/cuda/repos/debian13/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
```

### If this fails

- Re-run the command with `sudo apt-get update` after installing the keyring
- Confirm the download URL still exists
- Make sure you are using the Debian 13 package

### Step 2.4 — Install the CUDA toolkit

```bash
sudo apt-get update
sudo apt-get install -y cuda-toolkit
sudo reboot
```

### If this fails

- Re-run `sudo apt-get update`
- Check for broken packages:

```bash
sudo apt --fix-broken install
```

- Make sure the NVIDIA repositories were added successfully

### Step 2.5 — Set environment variables

After reboot, add CUDA to your shell profile.

For Bash:

```bash
echo 'export PATH=/usr/local/cuda-12.6/bin${PATH:+:${PATH}}' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH=/usr/local/cuda-12.6/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}' >> ~/.bashrc
source ~/.bashrc
```

### Step 2.6 — Verify CUDA

```bash
nvidia-smi
```

Optional test samples:

- https://github.com/nvidia/cuda-samples

### If this fails

- Reboot again
- Check whether the NVIDIA driver loaded correctly
- Confirm `nvidia-smi` is available in your PATH
- If the command is missing, review the CUDA install step

---

## 3) Set up NVIDIA AIStore

Official getting started guide:
https://docs.nvidia.com/aistore/getting_started

CLI docs:
https://docs.nvidia.com/aistore/cli

### Step 3.1 — Plan disk usage

Before installing AIStore, decide:

- which disk to use
- how much space to allocate
- how to partition it

If needed, configure `custom.service` and/or `/etc/fstab` before continuing.

### Step 3.2 — Clone AIStore

```bash
mkdir -p "$GOPATH/src/github.com/NVIDIA"
cd "$GOPATH/src/github.com/NVIDIA"
git clone https://github.com/NVIDIA/aistore.git
cd aistore
```

### Step 3.3 — Build and deploy a minimal cluster

```bash
make kill clean cli aisloader deploy <<< $'1\n1'
```

### Step 3.4 — Verify the cluster

```bash
ais show cluster
```

### Expected result

The cluster should report as running.

### If this fails

- Make sure `GOPATH` is set correctly:

```bash
echo "$GOPATH"
```

- Re-run the deploy command
- Check that your disk/service setup is complete
- Review the AIStore documentation above

---

## 4) Set up `llama.cpp`

### Step 4.1 — Clone the repository

```bash
git clone --depth=1 https://github.com/ggerganov/llama.cpp
cd llama.cpp
```

### Step 4.2 — Configure and build

```bash
cmake -B build
cmake --build build -j"$(nproc)"
```

### Step 4.3 — Install any local `.deb` packages if needed

```bash
sudo dpkg -i *.deb
```

### Step 4.4 — Choose a VRAM-safe model

For a **16GB RTX 5070 Ti**, use:

- `Qwen2.5-Coder-14B-Instruct-Q4_K_M`

This keeps the model small enough to fully fit in VRAM when you also cap the context window.

### Step 4.5 — Download the model into AIStore

Use an existing AIStore bucket for this step. The example below uses `symon_store`, so replace that bucket name if your cluster uses a different one.

Start the download job:

```bash
ais job start download "https://huggingface.co/bartowski/Qwen2.5-Coder-14B-Instruct-GGUF/resolve/main/Qwen2.5-Coder-14B-Instruct-Q4_K_M.gguf" ais://symon_store/Qwen2.5-Coder-14B-Instruct-Q4_K_M.gguf
```

The command returns a `JOB_ID`. Replace `JOB_ID` below with the actual identifier returned by the previous command:

```bash
ais job show download JOB_ID
```

### Step 4.6 — Stage the model on a local filesystem path

AIStore is a good place to store the model, but `llama.cpp` expects a normal local file path for the model file.

Use one of these approaches before starting the server:

- copy the GGUF file from AIStore to a local directory
- mount or otherwise expose the GGUF file on a local filesystem path

Example local path used below:

```text
/models/Qwen2.5-Coder-14B-Instruct-Q4_K_M.gguf
```

### Step 4.7 — Start `llama-server`

Launch the server with full GPU offload and a hard context cap:

```bash
./build/bin/llama-server \
  --model /models/Qwen2.5-Coder-14B-Instruct-Q4_K_M.gguf \
  --host 127.0.0.1 \
  --port 8080 \
  --ctx-size 16384 \
  --n-gpu-layers 999 \
  --parallel 1 \
  --flash-attn
```

### Why this configuration

- `--ctx-size 16384` is the safe default for keeping the model and working context inside 16GB VRAM
- `--n-gpu-layers 999` pushes the full model to the GPU when supported
- `--parallel 1` keeps memory usage predictable during initial setup

Do not raise the context size above `16384` until you verify that your system still stays fully inside VRAM.

### Step 4.8 — Connect OpenCode

In OpenCode, add a custom **OpenAI-compatible** provider with:

- Base URL: `http://127.0.0.1:8080/v1`
- API key: `local-model` if OpenCode requires one
- Model: the model name exposed by your local `llama-server`; you can check it with `curl http://127.0.0.1:8080/v1/models`

Recommended starting values:

- low temperature
- moderate max output tokens
- one chat at a time during initial testing

### Step 4.9 — Validate the serving setup

Check the setup in this order:

1. Confirm `llama-server` starts without errors
2. Send a short prompt from OpenCode
3. Send a larger prompt with code, logs, or documentation
4. If token generation slows down badly, reduce concurrency before changing models

### If this fails

- Install missing build dependencies from Step 1
- Make sure CMake is installed
- Confirm the GGUF file exists at the local path passed to `--model`
- Check that port `8080` is free before starting `llama-server`
- Re-run the build command after resolving errors

---

## 5) Verify the full setup

Run these checks:

```bash
lspci | grep -i nvidia
nvidia-smi
ais show cluster
curl http://127.0.0.1:8080/v1/models
```

### Expected result

- Your NVIDIA GPU should be visible
- CUDA should report successfully
- AIStore should show a running cluster
- The local `llama-server` should return model metadata

---

## Reference links

- CUDA downloads: https://developer.nvidia.com/cuda-downloads
- CUDA GPUs list: https://developer.nvidia.com/cuda/gpus
- CUDA install guide: https://docs.nvidia.com/cuda/archive/12.8.0/cuda-installation-guide-linux
- CUDA samples: https://github.com/nvidia/cuda-samples
- AIStore getting started: https://docs.nvidia.com/aistore/getting_started
- AIStore CLI docs: https://docs.nvidia.com/aistore/cli
- Hugging Face models: https://huggingface.co/models
- AIStore main site: https://docs.nvidia.com/aistore/
- Qwen2.5 Coder GGUF: https://huggingface.co/bartowski/Qwen2.5-Coder-14B-Instruct-GGUF

---

## Notes from system checks

### Detected GPU

```text
01:00.0 VGA compatible controller: NVIDIA Corporation GB203 [GeForce RTX 5070 Ti] (rev a1)
01:00.1 Audio device: NVIDIA Corporation GB203 High Definition Audio Controller (rev a1)
```

### Detected OS

```text
x86_64
PRETTY_NAME="Debian GNU/Linux 13 (trixie)"
NAME="Debian GNU/Linux"
VERSION_ID="13"
VERSION="13 (trixie)"
VERSION_CODENAME=trixie
DEBIAN_VERSION_FULL=13.5
ID=debian
HOME_URL="https://www.debian.org/"
SUPPORT_URL="https://www.debian.org/support"
BUG_REPORT_URL="https://bugs.debian.org/"
```

### CUDA package checksums / downloads

```text
ca4d11a6afcd021ba52d807373e6076f cuda-repo-amzn2023-12-6-local-12.6.2_560.35.03-1.x86_64.rpm
508181fae90cf390ad070cfc1c24b7e1 cuda-repo-cm2-12-6-local-12.6.2_560.35.03-1.x86_64.rpm
7b032f0534c2193de8ff25af1e5ce468 cuda-repo-debian11-12-6-local_12.6.2-560.35.03-1_amd64.deb
298d2332d4a2379cc19865db45419835 cuda-repo-debian12-12-6-local_12.6.2-560.35.03-1_amd64.deb
7c5ea477fd7827cb89de92f4017e40a8 cuda-repo-fedora39-12-6-local-12.6.2_560.35.03-1.x86_64.rpm
879f62415d13e2fd664e66532d501435 cuda-repo-kylin10-12-6-local-12.6.2_560.35.03-1.aarch64.rpm
b131604bc309434870e46346cc6cf834 cuda-repo-cross-sbsa-kylin10-12-6-local-12.6.2-1.noarch.rpm
a4b32f3eff73cc516e668a29f2af1482 cuda-repo-kylin10-12-6-local-12.6.2_560.35.03-1.x86_64.rpm
23127ce1c831b9861377811fb8a6401e cuda-repo-opensuse15-12-6-local-12.6.2_560.35.03-1.x86_64.rpm
c1b5511fd51bf06c38cd2ec53f5ecb5d cuda-repo-cross-sbsa-rhel8-12-6-local-12.6.2-1.noarch.rpm
6f58dc271784c661441e5bf84aba219b cuda-repo-rhel8-12-6-local-12.6.2_560.35.03-1.aarch64.rpm
d468046363bc51580c18c8b9c539848e cuda-repo-rhel8-12-6-local-12.6.2_560.35.03-1.x86_64.rpm
120d3d59559d4e4eb789498816e76b3c cuda-repo-rhel9-12-6-local-12.6.2_560.35.03-1.aarch64.rpm
7061f8fbb7a0f09d914bf95db05a0769 cuda-repo-cross-sbsa-rhel9-12-6-local-12.6.2-1.noarch.rpm
3b63053ff5905e70ed5247fe01fe1261 cuda-repo-rhel9-12-6-local-12.6.2_560.35.03-1.x86_64.rpm
f629ad91a760919b8ae67187600bd6b4 cuda_12.6.2_560.35.03_linux_sbsa.run
dcba85e2d49d7e6d93d8626f708276a4 cuda_12.6.2_560.35.03_linux.run
03f399c4dd02329b645acccae24337bd cuda-repo-cross-sbsa-sles15-12-6-local-12.6.2-1.noarch.rpm
cfda3628f6bc25178387dd2651a1d752 cuda-repo-sles15-12-6-local-12.6.2_560.35.03-1.aarch64.rpm
c50849bf3a1eeabfcbf98252cbc1db4e cuda-repo-sles15-12-6-local-12.6.2_560.35.03-1.x86_64.rpm
d09b02b8333298e8135558318931a77a cuda-repo-cross-sbsa-ubuntu2004-12-6-local_12.6.2-1_all.deb
70f10e62f9140926fe78013076c414aa cuda-repo-ubuntu2004-12-6-local_12.6.2-560.35.03-1_arm64.deb
8ed674880493ee3167c4eb93e10c820d cuda-repo-ubuntu2004-12-6-local_12.6.2-560.35.03-1_amd64.deb
c4f264963151cd81ed460a946a068237 cuda-tegra-repo-ubuntu2204-12-6-local_12.6.2-1_arm64.deb
d848c252740e1b09f1b0efed2df6dde0 cuda-repo-cross-aarch64-ubuntu2204-12-6-local_12.6.2-1_all.deb
1002203d7b7b977f177e2c9d12f171c6 cuda-repo-ubuntu2204-12-6-local_12.6.2-560.35.03-1_arm64.deb
6eac00a145f61377c57410b67898d208 cuda-repo-cross-sbsa-ubuntu2204-12-6-local_12.6.2-1_all.deb
081bce9e80ff0609b54c55dbaaea778d cuda-repo-ubuntu2204-12-6-local_12.6.2-560.35.03-1_amd64.deb
189919d2e0ef9cbfb86365542b3e3ff4 cuda-repo-ubuntu2404-12-6-local_12.6.2-560.35.03-1_arm64.deb
9c0a38536b4eb20cc581bf37ab917389 cuda-repo-cross-sbsa-ubuntu2404-12-6-local_12.6.2-1_all.deb
89a0de97a30e1832f98e99a867926228 cuda-repo-ubuntu2404-12-6-local_12.6.2-560.35.03-1_amd64.deb
d109e3e1720d33f9ea75379c619e22a6 cuda_12.6.2_windows_network.exe
05eccc6034d99da4cf80558e6a80fbdc cuda_12.6.2_560.94_windows.exe
e9bac16ee5f45e343f625068445da3b1 cuda-repo-wsl-ubuntu-12-6-local_12.6.2-1_amd64.deb
```
