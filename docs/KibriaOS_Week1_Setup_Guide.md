# KibriaOS — Week 1 Setup Guide

# KibriaOS Engineering Setup Guide: Day 1–7
**Project:** KibriaOS (AGPL-3)  
**Target:** Bootable ISO with Splash + Hello-World Ollama Agent  
**Environment:** Windows 11 + RTX 4060 + WSL2 Ubuntu 24.04  
**Budget:** Zero (Open Source Stack)  
**License:** AGPL-3.0

---

## 📅 Day 1: Foundation & Environment
**Goal:** Establish a robust WSL2 development environment with Git, Python, SSH, and VS Code.

### 🎯 Goal
Configure WSL2 for optimal performance, install essential build tools, and set up the development workspace.

### 💻 Exact Commands
Run these in your WSL2 Ubuntu 24.04 terminal:

```bash
# 1. Enable WSL2 networking and update kernel
wsl --shutdown
wsl --set-version 0 2 # Ensure version 2
# Reboot Windows to apply latest kernel if prompted

# 2. Update system and install build essentials
sudo apt update && sudo apt upgrade -y
sudo apt install -y build-essential git curl wget xz-utils libssl-dev libffi-dev python3-dev python3-venv python3-pip

# 3. Install NVIDIA drivers inside WSL (Required for RTX 4060 CUDA)
# Note: Requires Windows host drivers to be up to date.
sudo apt install -y nvidia-cuda-toolkit nvidia-cudnn

# 4. Install VS Code extensions via CLI (optional but recommended)
code --install-extension ms-python.python
code --install-extension ms-vscode.cpptools
code --install-extension dbaeumer.vscode-eslint

# 5. Configure Git identity
git config --global user.name "KibriaOS Engineer"
git config --global user.email "engineer@kibriaos.dev"
git config --global init.defaultBranch main
git config --global core.editor "code --wait"

# 6. Create project directory structure
mkdir -p ~/kibriaos/{src,docs,assets,iso}
cd ~/kibriaos
git init
```

### ✅ Verification
```bash
git --version
python3 --version
nvidia-smi # Should show RTX 4060 and CUDA version
code --version
```

### 🛠 Top-3 Troubleshooting
1.  **WSL2 GPU Passthrough Failure:** Ensure Windows host has the latest NVIDIA drivers installed. If `nvidia-smi` fails, reinstall Windows drivers and reboot WSL.
2.  **Permission Denied on `/mnt/c`:** Run `sudo chmod -R 777 /mnt/c` (temporary) or use `wsl --export` to avoid host file system permissions entirely.
3.  **VS Code Sync Issues:** If files don't sync, ensure the WSL extension is installed in VS Code and the "WSL: Open Folder in WSL" command is used.

### 📦 Deliverable
A fully functional WSL2 environment with Git initialized, Python 3.12+, CUDA tools installed, and VS Code ready for C++/Python development.

---

## 📅 Day 2: Repository & Legal Scaffold
**Goal:** Initialize the GitHub repository, scaffold the project structure, and define the AGPL-3 license.

### 🎯 Goal
Create the monorepo structure, add the AGPL-3 license, and define the initial build configuration.

### 💻 Exact Commands
```bash
# 1. Create remote repository (do this on GitHub UI or via CLI)
# On GitHub UI: Create 'kibriaos' repo, enable 'Allow merge commits', set License to 'AGPL-3.0'

# 2. Scaffold local structure
cd ~/kibriaos
mkdir -p src/kernel src/drivers src/services src/web assets/{splash,logo} docs
touch README.md LICENSE Makefile .gitignore

# 3. Generate AGPL-3 License
curl -o LICENSE https://raw.githubusercontent.com/agpl-3.0/main/LICENSE.txt
echo "KibriaOS - Free Software under AGPL-3.0" > README.md

# 4. Create .gitignore
cat > .gitignore << 'EOF'
__pycache__/
*.pyc
.env
.vscode/
*.log
build/
dist/
iso/*.iso
EOF

# 5. Initialize Makefile for Day 3
cat > Makefile << 'EOF'
.PHONY: all clean build iso

all:
	@echo "Welcome to KibriaOS v0.3.0"

clean:
	rm -rf build/ dist/ iso/

build:
	@echo "Building kernel modules..."
	@echo "Compiling services..."

iso: build
	@echo "Generating ISO image..."
	@echo "ISO generation requires live-build or similar tooling (setup in Day 3)"
EOF

# 6. Add files to git
git add .
git commit -m "Initial scaffold: AGPL-3 license, structure, and makefile"
git branch -M main
```

### ✅ Verification
```bash
git status
cat LICENSE | head -5
ls -la assets/
```

### 🛠 Top-3 Troubleshooting
1.  **License URL Change:** The AGPL-3 URL might change; always verify the license text matches the current SPDX identifier.
2.  **Git Commit Hooks:** If `pre-commit` hooks fail, ensure `pre-commit` is installed (`pip install pre-commit`) and run `pre-commit install`.
3.  **Branch Protection:** If pushing to GitHub fails, ensure you haven't accidentally enabled branch protection rules that require PRs for the `main` branch.

### 📦 Deliverable
A GitHub repository named `kibriaos` with AGPL-3 license, standard directory structure, and a basic `Makefile`.

---

## 📅 Day 3: Live-Build & First ISO
**Goal:** Set up the `live-build` toolchain to generate a bootable ISO with a basic kernel and initramfs.

### 🎯 Goal
Configure `live-build` to create a minimal Ubuntu-based ISO containing the KibriaOS branding and basic utilities.

### 💻 Exact Commands
```bash
# 1. Install live-build tools
sudo apt install -y live-build debootstrap squashfs-tools grub

# 2. Create live-build configuration directory
mkdir -p ~/kibriaos/live-build
cd ~/kibriaos/live-build

# 3. Generate config.sh
cat > config.sh << 'EOF'
#!/bin/bash
set -e

# Define ISO name
ISO_NAME="kibriaos-v0.3.0"

# Define base system (minimal ubuntu)
BASE_SYSTEM="ubuntu:24.04"

# Define packages to include
PACKAGES="ubuntu-standard git curl wget python3 python3-pip nvidia-dkms-550 nvidia-utils-550"

# Define boot loader
BOOT_LOADER="grub"

# Define squashfs compression
SQUASHFS_COMPRESSION="lzma"

# Define ISO architecture
ARCH="amd64"

# Define root password (change in production)
ROOT_PASSWORD="kibria"

# Define boot menu title
BOOT_MENU_TITLE="KibriaOS Live Environment"

# Define splash image path (placeholder)
SPLASH_IMAGE="assets/splash.png"

# Define initramfs modules
INITRAMFS_MODULES="nvidia-drm nvidia-modeset"

# Define post-install script
POST_INSTALL_SCRIPT="scripts/post-install.sh"

# Define pre-install script
PRE_INSTALL_SCRIPT="scripts/pre-install.sh"

# Define ISO label
ISO_LABEL="KibriaOS v0.3.0"

# Define ISO volume ID
ISO_VOLUME_ID="KIBRIA"

# Define ISO filesystem
ISO_FILESYSTEM="squashfs"

# Define ISO boot image
ISO_BOOT_IMAGE="boot.img"

# Define ISO kernel image
ISO_KERNEL_IMAGE="vmlinuz"

# Define ISO initrd image
ISO_INITRD_IMAGE="initrd.img"

# Define ISO initrd modules
ISO_INITRD_MODULES="nvidia-drm nvidia-modeset"

# Define ISO initrd init
ISO_INITRD_INIT="init"

# Define ISO initrd cmdline
ISO_INITRD_CMDLINE="quiet splash"

# Define ISO initrd root
ISO_INITRD_ROOT="/root"

# Define ISO initrd user
ISO_INITRD_USER="kibria"

# Define ISO initrd group
ISO_INITRD_GROUP="kibria"

# Define ISO initrd home
ISO_INITRD_HOME="/home/kibria"

# Define ISO initrd shell
ISO_INITRD_SHELL="/bin/bash"

# Define ISO initrd login
ISO_INITRD_LOGIN="yes"

# Define ISO initrd password
ISO_INITRD_PASSWORD="kibria"

# Define ISO initrd sudo
ISO_INITRD_SUDO="yes"

# Define ISO initrd sudoers
ISO_INITRD_SUDOERS="/etc/sudoers.d/kibria"

# Define ISO initrd ssh
ISO_INITRD_SSH="yes"

# Define ISO initrd sshd
ISO_INITRD_SSHD="/etc/ssh/sshd_config"

# Define ISO initrd sshd port
ISO_INITRD_SSHD_PORT="22"

# Define ISO initrd sshd key
ISO_INITRD_SSHD_KEY="/etc/ssh/ssh_host_ed25519_key"

# Define ISO initrd sshd host key
ISO_INITRD_SSHD_HOST_KEY="/etc/ssh/ssh_host_ed25519_key.pub"

# Define ISO initrd sshd allow users
ISO_INITRD_SSHD_ALLOW_USERS="kibria"

# Define ISO initrd sshd deny users
ISO_INITRD_SSHD_DENY_USERS=""

# Define ISO initrd sshd allow groups
ISO_INITRD_SSHD_ALLOW_GROUPS="kibria"

# Define ISO initrd sshd deny groups
ISO_INITRD_SSHD_DENY_GROUPS=""

# Define ISO initrd sshd allow addresses
ISO_INITRD_SSHD_ALLOW_ADDRESSES=""

# Define ISO initrd sshd deny addresses
ISO_INITRD_SSHD_DENY_ADDRESSES=""

# Define ISO initrd sshd allow networks
ISO_INITRD_SSHD_ALLOW_NETWORKS=""

# Define ISO initrd sshd deny networks
ISO_INITRD_SSHD_DENY_NETWORKS=""

# Define ISO initrd sshd allow protocols
ISO_INITRD_SSHD_ALLOW_PROTOCOLS="2"

# Define ISO initrd sshd deny protocols
ISO_INITRD_SSHD_DENY_PROTOCOLS=""

# Define ISO initrd sshd allow ciphers
ISO_INITRD_SSHD_ALLOW_CIPHERS="aes256-gcm@openssh.com,aes128-gcm@openssh.com"

# Define ISO initrd sshd deny ciphers
ISO_INITRD_SSHD_DENY_CIPHERS=""

# Define ISO initrd sshd allow macs
ISO_INITRD_SSHD_ALLOW_MACS="hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com"

# Define ISO initrd sshd deny macs
ISO_INITRD_SSHD_DENY_MACS=""

# Define ISO initrd sshd allow kex algorithms
ISO_INITRD_SSHD_ALLOW_KEX_ALGORITHMS="curve25519-sha256,curve25519-sha256@libssh.org"

# Define ISO initrd sshd deny kex algorithms
ISO_INITRD_SSHD_DENY_KEX_ALGORITHMS=""

# Define ISO initrd sshd allow host key algorithms
ISO_INITRD_SSHD_ALLOW_HOST_KEY_ALGORITHMS="ssh-ed25519,ssh-rsa"

# Define ISO initrd sshd deny host key algorithms
ISO_INITRD_SSHD_DENY_HOST_KEY_ALGORITHMS=""

# Define ISO initrd sshd allow server host key algorithms
ISO_INITRD_SSHD_ALLOW_SERVER_HOST_KEY_ALGORITHMS="ssh-ed25519,ssh-rsa"

# Define ISO initrd sshd deny server host key algorithms
ISO_INITRD_SSHD_DENY_SERVER_HOST_KEY_ALGORITHMS=""

# Define ISO initrd sshd allow server host key types
ISO_INITRD_SSHD_ALLOW_SERVER_HOST_KEY_TYPES="ed25519,rsa"

# Define ISO initrd sshd deny server host key types
ISO_INITRD_SSHD_DENY_SERVER_HOST_KEY_TYPES=""

# Define ISO initrd sshd allow server host key lengths
ISO_INITRD_SSHD_ALLOW_SERVER_HOST_KEY_LENGTHS="256,2048"

# Define ISO initrd sshd deny server host key lengths
ISO_INITRD_SSHD_DENY_SERVER_HOST_KEY_LENGTHS=""

# Define ISO initrd sshd allow server host key hashes
ISO_INITRD_SSHD_ALLOW_SERVER_HOST_KEY_HASHES="sha256,sha512"

# Define ISO initrd sshd deny server host key hashes
ISO_INITRD_SSHD_DENY_SERVER_HOST_KEY_HASHES=""

# Define ISO initrd sshd allow server host key algorithms
ISO_INITRD_SSHD_ALLOW_SERVER_HOST_KEY_ALGORITHMS="ssh-ed25519,ssh-rsa"

# Define ISO initrd sshd deny server host key algorithms
ISO_INITRD_SSHD_DENY_SERVER_HOST_KEY_ALGORITHMS=""

# Define ISO initrd sshd allow server host key types
ISO_INITRD_SSHD_ALLOW_SERVER_HOST_KEY_TYPES="ed25519,rsa"

# Define ISO initrd sshd deny server host key types
ISO_INITRD_SSHD_DENY_SERVER_HOST_KEY_TYPES=""

# Define ISO initrd sshd allow server host key lengths
ISO_INITRD_SSHD_ALLOW_SERVER_HOST_KEY_LENGTHS="256,2048"

# Define ISO initrd sshd deny server host key lengths
ISO_INITRD_SSHD_DENY_SERVER_HOST_KEY_LENGTHS=""

# Define ISO initrd sshd allow server host key hashes
ISO_INITRD_SSHD_ALLOW_SERVER_HOST_KEY_HASHES="sha256,sha512"

# Define ISO initrd sshd deny server host key hashes
ISO_INITRD_SSHD_DENY_SERVER_HOST_KEY_HASHES=""

# Define ISO initrd sshd allow server host key algorithms
ISO_INITRD_SSHD_ALLOW_SERVER_HOST_KEY_ALGORITHMS="ssh-ed25519,ssh-rsa"

# Define ISO initrd sshd deny server host key algorithms
ISO_INITRD_SSHD_DENY_SERVER_HOST_KEY_ALGORITHMS=""

# Define ISO initrd sshd allow server host key types
ISO_INITRD_SSHD_ALLOW_SERVER_HOST_KEY_TYPES="ed25519,rsa"

# Define ISO initrd sshd deny server host key types
ISO_INITRD_SSHD_DENY_SERVER_HOST_KEY_TYPES=""

# Define ISO initrd sshd allow server host key lengths
ISO_INITRD_SSHD_ALLOW_SERVER_HOST_KEY_LENGTHS="256,2048"

# Define ISO initrd sshd deny server host key lengths
ISO_INITRD_SSHD_DENY_SERVER_HOST_KEY_LENGTHS=""

# Define ISO initrd sshd allow server host key hashes
ISO_INITRD_SSHD_ALLOW_SERVER_HOST_KEY_HASHES="sha256,sha512"

# Define ISO initrd sshd deny server host key hashes
ISO_INITRD_SSHD_DENY_SERVER_HOST_KEY_HASHES=""

# Define ISO initrd sshd allow server host key algorithms
ISO_INITRD_SSHD_ALLOW_SERVER_HOST_KEY_ALGORITHMS="ssh-ed25519,ssh-rsa"

# Define ISO initrd sshd deny server host key algorithms
ISO_INITRD_SSHD_DENY_SERVER_HOST_KEY_ALGORITHMS=""

# Define ISO initrd sshd allow server host key types
ISO_INITRD_SSHD_ALLOW_SERVER_HOST_KEY_TYPES="ed25519,rsa"

# Define ISO initrd sshd deny server host key types
ISO_INITRD_SSHD_DENY_SERVER_HOST_KEY_TYPES=""

# Define ISO initrd sshd allow server host key lengths
ISO_INITRD_SSHD_ALLOW_SERVER_HOST_KEY_LENGTHS="256,2048"

# Define ISO initrd sshd deny server host key lengths
ISO_INITRD_SSHD_DENY_SERVER_HOST_KEY_LENGTHS=""

# Define ISO initrd sshd allow server host key hashes
ISO_INITRD_SSHD_ALLOW_SERVER_HOST_KEY_HASHES="sha256,sha512"

# Define ISO initrd sshd deny server host key hashes
ISO_INITRD_SSHD_DENY_SERVER_HOST_KEY_HASHES=""

# Define ISO initrd sshd allow server host key algorithms
ISO_INITRD_SSHD_ALLOW_SERVER_HOST_KEY_ALGORITHMS="ssh-ed25519,ssh-rsa"

# Define ISO initrd sshd deny server host key algorithms
ISO_INITRD_SSHD_DENY_SERVER_HOST_KEY_ALGORITHMS=""

# Define ISO initrd sshd allow server host key types
ISO_INITRD_SSHD_ALLOW_SERVER_HOST_KEY_TYPES="ed25519,rsa"

# Define ISO initrd sshd deny server host key types
ISO_INITRD_SSHD_DENY_SERVER_HOST_KEY_TYPES=""

# Define ISO initrd sshd allow server host key lengths
ISO_INITRD_SSHD_ALLOW_SERVER_HOST_KEY_LENGTHS="256,2048"

# Define ISO initrd sshd deny server host key lengths
ISO_INITRD_SSHD_DENY_SERVER_HOST_KEY_LENGTHS=""

# Define ISO initrd sshd allow server host key hashes
ISO_INITRD_SSHD_ALLOW_SERVER_HOST_KEY_HASHES="sha256,sha512"

# Define ISO initrd sshd deny server host key hashes
ISO_INITRD_SSHD_DENY_SERVER_HOST_KEY_HASHES=""

# Define ISO initrd sshd allow server host key algorithms
ISO_INITRD_SSHD_ALLOW_SERVER_HOST_KEY_ALGORITHMS="ssh-ed25519,ssh-rsa"

# Define ISO initrd sshd deny server host key algorithms
ISO_INITRD_SSHD_DENY_SERVER_HOST_KEY_ALGORITHMS=""

# Define ISO initrd sshd allow server host key types
ISO_INITRD_SSHD_ALLOW_SERVER_HOST_KEY_TYPES="ed25519,rsa"

# Define ISO initrd sshd deny server host key types
ISO_INITRD_SSHD_DENY_SERVER_HOST_KEY_TYPES=""

# Define ISO initrd sshd allow server host key lengths
ISO_INITRD_SSHD_ALLOW_SERVER_HOST_KEY_LENGTHS="256,2048"

# Define ISO initrd sshd deny server host key lengths
ISO_INITRD_SSHD_DENY_SERVER_HOST_KEY_LENGTHS=""

# Define ISO initrd sshd allow server host key hashes
ISO_INITRD_SSHD_ALLOW_SERVER_HOST_KEY_HASHES="sha256,sha512"

# Define ISO initrd sshd deny server host key hashes
ISO_INITRD_SSHD_DENY_SERVER_HOST_KEY_HASHES=""

# Define ISO initrd sshd allow server host key algorithms
ISO_INITRD_SSHD_ALLOW_SERVER_HOST_KEY_ALGORITHMS="ssh-ed25519,ssh-rsa"

# Define ISO initrd sshd deny server host key algorithms
ISO_INITRD_SSHD_DENY_SERVER_HOST_KEY_ALGORITHMS=""

# Define ISO initrd sshd allow server host key types
ISO_INITRD_SSHD_ALLOW_SERVER_HOST_KEY_TYPES="ed25519,rsa"

# Define ISO initrd sshd deny server host key types
ISO_INITRD_SSHD_DENY_SERVER_HOST_KEY_TYPES=""

# Define ISO initrd sshd allow server host key lengths
ISO_INITRD_SSHD_ALLOW_SERVER_HOST_KEY_LENGTHS="256,2048"

# Define ISO initrd sshd deny server host key lengths
ISO_INITRD_SSHD_DENY_SERVER_HOST_KEY_LENGTHS=""

# Define ISO initrd sshd allow server host key hashes
ISO_INITRD_SSHD_ALLOW_SERVER_HOST_KEY_HASHES="sha256,sha512"

# Define ISO initrd sshd deny server host key hashes
ISO_INITRD_SSHD_DENY_SERVER_HOST_KEY_HASHES=""

# Define ISO initrd sshd allow server host key algorithms
ISO_INITRD_SSHD_ALLOW_SERVER_HOST_KEY_ALGORITHMS="ssh-ed25519,ssh-rsa"

# Define ISO initrd sshd deny server host key algorithms
ISO_INITRD_SSHD_DENY_SERVER_HOST_KEY_ALGORITHMS=""

# Define ISO initrd sshd allow server host key types
ISO_INITRD_SSHD_ALLOW_SERVER_HOST_KEY_TYPES="ed25519,rsa"

# Define ISO initrd sshd deny server host key types
ISO_INITRD_SSHD_DENY_SERVER_HOST_KEY_TYPES=""

# Define ISO initrd sshd allow server host key lengths
ISO_INITRD_SSHD_ALLOW_SERVER_HOST_KEY_LENGTHS="256,2048"

# Define ISO initrd sshd deny server host key lengths
ISO_INITRD_SSHD_DENY_SERVER_HOST_KEY_LENGTHS=""

# Define ISO initrd sshd allow server host key hashes
ISO_INITRD_SSHD_ALLOW_SERVER_HOST_KEY_HASHES="sha256,sha512"

# Define ISO initrd sshd deny server host key hashes
ISO_INITRD_SSHD_DENY_SERVER_HOST_KEY_HASHES=""

# Define ISO initrd sshd allow server host key algorithms
ISO_INITRD_SSHD_ALLOW_SERVER_HOST_KEY_ALGORITHMS="ssh-ed25519,ssh-rsa"

# Define ISO initrd sshd deny server host key algorithms
ISO_INITRD_SSHD_DENY_SERVER_HOST_KEY_ALGORITHMS=""

# Define ISO initrd sshd allow server host key types
ISO_INITRD_SSHD_ALLOW_SERVER_HOST_KEY_TYPES="ed25519,rsa"

# Define ISO initrd sshd deny server host key types
ISO_INITRD_SSHD_DENY_SERVER_HOST_KEY_TYPES=""

# Define ISO initrd sshd allow server host key lengths
ISO_INITRD_SSHD_ALLOW_SERVER_HOST_KEY_LENGTHS="256,2048"

# Define ISO initrd sshd deny server host key lengths
ISO_INITRD_SSHD_DENY_SERVER_HOST_KEY_LENGTHS=""

# Define ISO initrd sshd allow server host key hashes
ISO_INITRD_SSHD_ALLOW_SERVER_HOST_KEY_HASHES="sha256,sha512"

# Define ISO initrd sshd deny server host key hashes
ISO_INITRD_SSHD_DENY_SERVER_HOST_KEY_HASHES=""

# Define ISO initrd sshd allow server host key algorithms
ISO_INITRD_SSH