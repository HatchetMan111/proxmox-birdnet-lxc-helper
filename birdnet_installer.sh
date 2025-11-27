#!/bin/bash

# ----------------------------------------------------------------------------------
# Script: birdnet-installer.sh
# Repository: https://github.com/HatchetMan111/proxmox-birdnet-lxc
# Description: Installs BirdNET-Go in a Proxmox LXC Container (Docker-based)
#              Optimized for RTSP Streams (No USB Passthrough needed)
# ----------------------------------------------------------------------------------

set -e

# --- Configuration ---
CT_ID="905"                   # Container ID (Change if needed)
CT_NAME="birdnet-go"          # Container Hostname
CT_PASSWORD="ChangeMe123!"    # Root Password for the Container
DISK_SIZE="10G"               # Disk Size
RAM_SIZE="2048"               # RAM in MB (2GB recommended for AI analysis)
CORES="2"                     # CPU Cores
OS_TEMPLATE="local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst" # Standard Proxmox Template Path
STORAGE="local-lvm"           # Proxmox Storage for the Container Disk

# --- Colors for Output ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# --- Helper Functions ---
function msg_info() { echo -e "${BLUE}[INFO] ${1}${NC}"; }
function msg_ok() { echo -e "${GREEN}[OK] ${1}${NC}"; }
function msg_err() { echo -e "${RED}[ERROR] ${1}${NC}"; }

# --- Main Script ---

# 1. Check Root
if [ "$EUID" -ne 0 ]; then 
  msg_err "Please run as root."
  exit 1
fi

msg_info "Starting BirdNET-Go Installation on Proxmox..."

# 2. Check if ID is free
if pct status $CT_ID &>/dev/null; then
    msg_err "ID $CT_ID is already in use. Please change CT_ID in the script or remove the old container."
    exit 1
fi

# 3. Download Template (if using standard pveam templates)
msg_info "Checking for Ubuntu 22.04 Template..."
pveam update >/dev/null
# Note: Usually Proxmox has this template available via 'pveam'. 
# If not present, you might need to download it manually or use 'pveam download local ubuntu-22.04-standard_22.04-1_amd64.tar.zst'
# Assuming standard setup:
if ! pveam available | grep -q "ubuntu-22.04"; then
    msg_info "Downloading Ubuntu 22.04 Template..."
    pveam download local ubuntu-22.04-standard_22.04-1_amd64.tar.zst >/dev/null || true
fi

# 4. Create LXC Container
msg_info "Creating LXC Container (ID: $CT_ID)..."
pct create $CT_ID $OS_TEMPLATE \
    --hostname $CT_NAME \
    --cores $CORES \
    --memory $RAM_SIZE \
    --swap 512 \
    --storage $STORAGE \
    --rootfs $DISK_SIZE \
    --net0 name=eth0,bridge=vmbr0,ip=dhcp,type=veth \
    --features nesting=1,keyctl=1 \
    --unprivileged 1 \
    --password $CT_PASSWORD \
    --start 1 \
    --onboot 1

msg_ok "Container created and started."

# 5. Wait for Network
msg_info "Waiting for container network..."
sleep 10

# 6. Install Docker & BirdNET inside Container
msg_info "Installing Docker and BirdNET-Go inside the container..."

pct exec $CT_ID -- bash -c "
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get upgrade -y
    apt-get install -y curl git tzdata

    # Install Docker
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh

    # Setup directories
    mkdir -p /var/lib/birdnet-go/config
    mkdir -p /var/lib/birdnet-go/data

    # Run BirdNET-Go Docker Container
    # -p 8080:8080 : Maps the WebUI
    # Uses ghcr.io/tphakala/birdnet-go (Great for RTSP)
    echo 'Starting BirdNET-Go Docker container...'
    docker run -d \\
      --name birdnet-go \\
      --restart unless-stopped \\
      -p 8080:8080 \\
      -v /var/lib/birdnet-go/config:/config \\
      -v /var/lib/birdnet-go/data:/data \\
      -e TZ=Europe/Berlin \\
      ghcr.io/tphakala/birdnet-go:latest
"

# 7. Get IP Address
IP=$(pct exec $CT_ID ip a s dev eth0 | awk '/inet / {print $2}' | cut -d/ -f1)

# 8. Finished
echo -e "\n${GREEN}--------------------------------------------------${NC}"
echo -e "${GREEN} Installation Finished Successfully! ${NC}"
echo -e "${GREEN}--------------------------------------------------${NC}"
echo -e "BirdNET-Go is running."
echo -e "Web Interface: ${BLUE}http://${IP}:8080${NC}"
echo -e ""
echo -e "NEXT STEPS:"
echo -e "1. Open the Web Interface."
echo -e "2. Go to 'Settings' -> 'Audio'."
echo -e "3. Enter your Camera RTSP URL (e.g., rtsp://user:pass@IP:554/stream)."
echo -e "4. Configure MQTT for Home Assistant integration."
echo -e "--------------------------------------------------"
