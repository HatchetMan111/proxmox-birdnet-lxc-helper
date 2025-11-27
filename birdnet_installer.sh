#!/usr/bin/env bash

# Copyright (c) 2025 HatchetMan111
# Author: HatchetMan111
# License: MIT
# https://github.com/HatchetMan111/proxmox-birdnet-lxc-helper

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y curl
$STD apt-get install -y sudo
$STD apt-get install -y mc
$STD apt-get install -y git
$STD apt-get install -y alsa-utils
$STD apt-get install -y ffmpeg
msg_ok "Installed Dependencies"

msg_info "Installing BirdNET-Go"
RELEASE=$(curl -s https://api.github.com/repos/tphakala/birdnet-go/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3)}')
cd /opt
$STD git clone https://github.com/tphakala/birdnet-go.git
cd birdnet-go
$STD wget -q "https://github.com/tphakala/birdnet-go/releases/download/${RELEASE}/birdnet-go_Linux_x86_64.tar.gz"
$STD tar -xzf "birdnet-go_Linux_x86_64.tar.gz"
$STD rm "birdnet-go_Linux_x86_64.tar.gz"
$STD chmod +x birdnet-go
msg_ok "Installed BirdNET-Go"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/birdnet-go.service
[Unit]
Description=BirdNET-Go Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/birdnet-go
ExecStart=/opt/birdnet-go/birdnet-go --config /opt/birdnet-go/config.yaml
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable -q --now birdnet-go.service
msg_ok "Created Service"

msg_info "Creating Initial Configuration"
cat <<EOF >/opt/birdnet-go/config.yaml
# BirdNET-Go Configuration
# Bearbeite diese Datei nach deinen Bedürfnissen

main:
  name: BirdNET-Go
  timeas24h: true
  log:
    enabled: true
    level: info
    rotation: daily
    maxsize: 10

webserver:
  enabled: true
  port: 8080
  host: 0.0.0.0
  autotls: false

birdnet:
  sensitivity: 1.0
  threshold: 0.7
  overlap: 0.0
  latitude: 48.8
  longitude: 9.8
  threads: 0
  locale: de

realtime:
  enabled: true
  interval: 15
  processingtime: false

audio:
  source: sysdefault
  export:
    enabled: false
    path: /opt/birdnet-go/clips
    type: wav
EOF
msg_ok "Created Initial Configuration"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get autoremove
$STD apt-get autoclean
msg_ok "Cleaned"

msg_info "BirdNET-Go Installation erfolgreich!"
echo ""
echo "==================================================================="
echo "BirdNET-Go wurde erfolgreich installiert!"
echo "==================================================================="
echo ""
echo "Web-Interface erreichbar unter: http://$(hostname -I | awk '{print $1}'):8080"
echo ""
echo "Wichtige Befehle:"
echo "  - Konfiguration bearbeiten: nano /opt/birdnet-go/config.yaml"
echo "  - Service neustarten:       systemctl restart birdnet-go"
echo "  - Service Status:           systemctl status birdnet-go"
echo "  - Logs anzeigen:            journalctl -u birdnet-go -f"
echo ""
echo "Audio-Geräte testen:"
echo "  - Geräte auflisten:         arecord -L"
echo "  - Aufnahme testen:          arecord -D sysdefault -d 5 test.wav"
echo ""
echo "==================================================================="
echo ""
