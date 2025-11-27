#!/bin/bash

# ----------------------------------------------------------------------------------
# Script: birdnet-installer.sh
# Repository: https://github.com/HatchetMan111/proxmox-birdnet-lxc-helper
# Description: Installs BirdNET-Go in a Proxmox LXC Container (Docker-based)
#              Optimiert für RTSP Streams (IP-Kameras, kein USB Passthrough nötig)
# ----------------------------------------------------------------------------------

set -euo pipefail

# --- Configuration Variables ---
CT_ID="905"                   # Container ID (Standard für Helper)
CT_NAME="birdnet-go"          # Container Hostname
CT_PASSWORD="ChangeMe123!"    # Root Password for the Container (WICHTIG: Ändern!)
DISK_SIZE="10G"               # Disk Size (10GB empfohlen)
RAM_SIZE="2048"               # RAM in MB (2GB empfohlen)
CORES="2"                     # CPU Cores
OS_TEMPLATE="local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst" # Ubuntu 22.04
STORAGE="local-lvm"           # Proxmox Storage für die Container Disk (Anpassen!)

# --- Colors for Output ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# --- Helper Functions ---
function msg_info() { echo -e "${BLUE}[INFO] ${1}${NC}"; }
function msg_ok() { echo -e "${GREEN}[OK] ${1}${NC}"; }
function msg_warn() { echo -e "${YELLOW}[WARN] ${1}${NC}"; }
function msg_err() { echo -e "${RED}[ERROR] ${1}${NC}"; }

# --- Main Script ---

# 1. Check Root
if [ "$EUID" -ne 0 ]; then 
  msg_err "Dieses Skript muss als root oder mit 'sudo' ausgeführt werden."
  exit 1
fi

msg_info "Starte BirdNET-Go Installation auf Proxmox VE (LXC)..."

# 2. Check if ID is free
if pct status $CT_ID &>/dev/null; then
    msg_err "Container ID $CT_ID ist bereits belegt. Bitte ändern Sie die Variable CT_ID im Skript."
    exit 1
fi

# 3. Check for Template
msg_info "Überprüfe Ubuntu 22.04 Template..."
if ! pveam available | grep -q "ubuntu-22.04"; then
    msg_warn "Template nicht lokal gefunden. Lade 'ubuntu-22.04-standard' herunter (Kann einige Minuten dauern)..."
    pveam download local ubuntu-22.04-standard_22.04-1_amd64.tar.zst || msg_err "Template Download fehlgeschlagen."
fi

# 4. Create LXC Container
msg_info "Erstelle unprivilegierten LXC Container (ID: $CT_ID)..."
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
    --onboot 1 \
    --description "BirdNET-Go LXC Helper Script (RTSP)"

msg_ok "Container erstellt und gestartet."

# 5. Wait for Network
msg_info "Warte auf Container Boot und Netzwerkkonfiguration (15s)..."
sleep 15

# 6. Install Docker & BirdNET inside Container
msg_info "Installiere Docker und starte BirdNET-Go Container..."

pct exec $CT_ID -- bash -c "
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y curl git tzdata 

    # Install Docker
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh

    # Setup persistent directories
    mkdir -p /var/lib/birdnet-go/config
    mkdir -p /var/lib/birdnet-go/data
    
    # Run BirdNET-Go Docker Container
    msg_info 'Starte BirdNET-Go Docker Container...'
    docker run -d \
      --name birdnet-go \
      --restart unless-stopped \
      -p 8080:8080 \
      -v /var/lib/birdnet-go/config:/config \
      -v /var/lib/birdnet-go/data:/data \
      -e TZ=Europe/Berlin \
      ghcr.io/tphakala/birdnet-go:latest
"

# 7. Get IP Address
IP=$(pct exec $CT_ID ip a s dev eth0 | awk '/inet / {print $2}' | cut -d/ -f1)

# 8. Finished
echo -e "\n${GREEN}------------------------------------------------------------${NC}"
echo -e "${GREEN} Installation erfolgreich abgeschlossen! ${NC}"
echo -e "${GREEN}------------------------------------------------------------${NC}"
echo -e "BirdNET-Go ist im Container ID ${CT_ID} gestartet."
echo -e "Web Interface: ${BLUE}http://${IP}:8080${NC}"
echo -e ""
echo -e "${YELLOW}Wichtige Nächste Schritte (RTSP/Home Assistant):${NC}"
echo -e "1. Öffnen Sie die Web-Oberfläche (${IP}:8080)."
echo -e "2. Navigieren Sie zu 'Settings' -> 'Audio' und geben Sie die vollständige **RTSP Stream URL** Ihrer Kamera ein."
echo -e "3. Konfigurieren Sie unter 'Settings' -> 'MQTT' die Verbindung zu Home Assistant."
echo -e "------------------------------------------------------------"
