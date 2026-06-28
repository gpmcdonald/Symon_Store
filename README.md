# Custom Local AI Workflow

A practical, copy-and-paste friendly setup guide for building a local AI environment on **Debian 13 (trixie)** with an **NVIDIA GeForce RTX 5070 Ti**.

## What this guide covers

1. Install system dependencies
2. Install NVIDIA CUDA
3. Set up NVIDIA AIStore
4. Build `llama.cpp`
5. Verify the environment

---

## 1) Install system dependencies

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

---

## 2) Install NVIDIA CUDA

Official guide: https://docs.nvidia.com/cuda/archive/12.8.0/cuda-installation-guide-linux

### 2.1 Check your system

```bash
lspci | grep -i nvidia
uname -m
cat /etc/*release
gcc --version
```

You should confirm:

- your GPU is detected
- your OS is supported
- your architecture is `x86_64`

### 2.2 Download CUDA

Choose your installer here:

- https://developer.nvidia.com/cuda-downloads

If you download a package manually, verify it with:

```bash
md5sum <downloaded-file>
```

### 2.3 Install the CUDA keyring

```bash
wget https://developer.download.nvidia.com/compute/cuda/repos/debian13/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
```

### 2.4 Install the toolkit

```bash
sudo apt-get update
sudo apt-get install -y cuda-toolkit
sudo reboot
```

### 2.5 Add CUDA to your shell environment

After reboot, add the following to `~/.bashrc` or your shell profile:

```bash
export PATH=/usr/local/cuda-12.6/bin${PATH:+:${PATH}}
export LD_LIBRARY_PATH=/usr/local/cuda-12.6/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
```

Reload your shell:

```bash
source ~/.bashrc
```

### 2.6 Verify CUDA

```bash
nvidia-smi
```

If you want to test with CUDA samples:

- https://github.com/nvidia/cuda-samples

---

## 3) Set up NVIDIA AIStore

Official guide: https://docs.nvidia.com/aistore/getting_started

### 3.1 Decide your disk layout

Before installing AIStore, decide:

- which disk to use
- how large it should be
- how it should be partitioned

If needed, configure a custom service and/or `/etc/fstab` first.

### 3.2 Clone and deploy AIStore

```bash
mkdir -p "$GOPATH/src/github.com/NVIDIA"
cd "$GOPATH/src/github.com/NVIDIA"
git clone https://github.com/NVIDIA/aistore.git
cd aistore
make kill clean cli aisloader deploy <<< $'1\n1'
```

### 3.3 Verify the cluster

```bash
ais show cluster
```

CLI reference:

- https://docs.nvidia.com/aistore/cli

---

## 4) Build and set up `llama.cpp`

```bash
git clone --depth=1 https://github.com/ggerganov/llama.cpp
cd llama.cpp
cmake -B build
sudo dpkg -i *.deb
```

If you prefer a clean build directory layout, use:

```bash
cmake -B build -S .
cmake --build build -j"$(nproc)"
```

---

## 5) Verify everything works

Run this after setup:

```bash
ais show cluster
```

You can also confirm the GPU is visible:

```bash
lspci | grep -i nvidia
nvidia-smi
```

---

## Reference links

- CUDA downloads: https://developer.nvidia.com/cuda-downloads
- CUDA GPUs: https://developer.nvidia.com/cuda/gpus
- CUDA install guide: https://docs.nvidia.com/cuda/archive/12.8.0/cuda-installation-guide-linux
- CUDA samples: https://github.com/nvidia/cuda-samples
- AIStore getting started: https://docs.nvidia.com/aistore/getting_started
- AIStore CLI docs: https://docs.nvidia.com/aistore/cli
- Hugging Face models: https://huggingface.co/models
- AIStore main site: https://docs.nvidia.com/aistore/

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
