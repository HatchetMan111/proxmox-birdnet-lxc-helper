#!/usr/bin/env bash

# Copyright (c) 2025 HatchetMan111
# Author: HatchetMan111
# License: MIT
# https://github.com/HatchetMan111/proxmox-birdnet-lxc-helper

# Lade die Community Scripts Build-Funktionen
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)

function header_info {
clear
cat <<"EOF"
    ____  _          ______   ____________     ______      
   / __ )(_)_________/ / | / / ____/_  __/    / ____/___   
  / __  / / ___/ __  /  |/ / __/   / /______/ / __/ __ \  
 / /_/ / / /  / /_/ / /|  / /___  / /_/_____/ /_/ / /_/ /  
/_____/_/_/   \__,_/_/ |_/_____/ /_/        \____/\____/   
                                                            
EOF
}

header_info
echo -e "Loading..."

APP="BirdNET-Go"
var_disk="4"
var_cpu="2"
var_ram="1024"
var_os="debian"
var_version="12"

variables
color
catch_errors

function default_settings() {
  CT_TYPE="1"
  PW=""
  CT_ID=$NEXTID
  HN=$NSAPP
  DISK_SIZE="$var_disk"
  CORE_COUNT="$var_cpu"
  RAM_SIZE="$var_ram"
  BRG="vmbr0"
  NET="dhcp"
  GATE=""
  APT_CACHER=""
  APT_CACHER_IP=""
  DISABLEIP6="no"
  MTU=""
  SD=""
  NS=""
  MAC=""
  VLAN=""
  SSH="no"
  VERB="no"
  echo_default
}

function update_script() {
header_info
if [[ ! -d /opt/birdnet-go ]]; then 
  msg_error "Keine ${APP} Installation gefunden!"
  echo "Bitte führe dieses Update im Container aus oder verwende:"
  echo "bash <(curl -s https://raw.githubusercontent.com/HatchetMan111/proxmox-birdnet-lxc-helper/main/update.sh)"
  exit 1
fi

msg_info "Updating ${APP}"
cd /opt/birdnet-go
systemctl stop birdnet-go

RELEASE=$(curl -s https://api.github.com/repos/tphakala/birdnet-go/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4)}')

if [[ -f "birdnet-go" ]]; then
  CURRENT_VERSION=$(./birdnet-go --version 2>&1 | grep -oP 'version \K[0-9.]+' || echo "unknown")
  msg_info "Aktuelle Version: ${CURRENT_VERSION}"
  msg_info "Neueste Version: ${RELEASE}"
fi

# Backup der Config
if [[ -f "config.yaml" ]]; then
  cp config.yaml config.yaml.backup
fi

wget -q "https://github.com/tphakala/birdnet-go/releases/download/v${RELEASE}/birdnet-go_Linux_x86_64.tar.gz"
tar -xzf "birdnet-go_Linux_x86_64.tar.gz"
rm "birdnet-go_Linux_x86_64.tar.gz"
chmod +x birdnet-go

systemctl start birdnet-go
msg_ok "Updated ${APP} to ${RELEASE}"
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} sollte unter folgender Adresse erreichbar sein:
         ${BL}http://${IP}:8080${CL} \n"
