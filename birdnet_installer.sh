#!/bin/bash
# BirdNET Installer Helper Script for Proxmox (LXC) - RTSP Focus
# Erstellt von [Dein Name oder Handle]
# Installiert BirdNET-Go als Docker-Container

# --- Variablen ---
LXC_ID="905"
LXC_NAME="birdnet"
LXC_PASSWORD="HA_Password" # SICHERES PASSWORT VERWENDEN
LXC_MEMORY="1536" # 1.5GB RAM (etwas mehr für Docker/FFmpeg-Pufferung)
LXC_SWAP="512"
LXC_DISK="10" # 10GB Disk (Mehr Platz für Aufzeichnungen)
LXC_CORES="2"
LXC_BRIDGE="vmbr0"
LXC_IP="dhcp" 
LXC_GW="" 

# Ubuntu 22.04 LTS Cloud-Init Template (Jammy Jellyfish)
TEMPLATE_URL="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.tar.gz"
TEMPLATE_FILENAME="jammy-server-cloudimg-amd64.tar.gz"
TEMPLATE_STORAGE="local"
LXC_STORAGE="local-lvm" 

# --- Funktionen ---

# Funktion für Statusmeldungen
log() {
    echo -e "\n\e[1m\e[34m---> $1\e[0m\n"
}

# Funktion für Fehlermeldungen
error() {
    echo -e "\n\e[1m\e[31m!!! FEHLER: $1 !!!\e[0m\n"
    exit 1
}

# Funktion für die Installation
install_birdnet() {
    log "Überprüfe Proxmox Umgebung und Cloud-Init Template"
    
    if [ ! -f "/var/lib/vz/template/cache/${TEMPLATE_FILENAME}" ]; then
        log "Lade Ubuntu 22.04 Cloud-Init Template herunter..."
        wget -q -O /var/lib/vz/template/cache/${TEMPLATE_FILENAME} ${TEMPLATE_URL} || error "Template Download fehlgeschlagen"
    else
        log "Template bereits vorhanden."
    fi

    log "Erstelle LXC Container (ID: $LXC_ID) für BirdNET..."
    
    pvesh create /nodes/$(hostname)/lxc --vmid ${LXC_ID} \
        --hostname ${LXC_NAME} \
        --ostemplate ${TEMPLATE_STORAGE}:vztmpl/${TEMPLATE_FILENAME} \
        --net0 name=eth0,bridge=${LXC_BRIDGE},ip=${LXC_IP},gw=${LXC_GW},type=veth \
        --memory ${LXC_MEMORY} --swap ${LXC_SWAP} --cores ${LXC_CORES} \
        --rootfs ${LXC_STORAGE}:${LXC_DISK} \
        --unprivileged 1 \
        --password ${LXC_PASSWORD} \
        --storage ${LXC_STORAGE} \
        --description "BirdNET-Go mit Docker für RTSP" \
        || error "LXC Container Erstellung fehlgeschlagen"

    log "Starte BirdNET LXC Container und warte auf Netzwerk-Initialisierung..."
    
    pct start ${LXC_ID} || error "LXC Container Start fehlgeschlagen"
    sleep 30

    log "Installiere Docker und starte BirdNET-Go Container..."

    # Docker Installations- und Startbefehle (als root im Container)
    pct exec ${LXC_ID} -- bash -c "
        apt update && apt upgrade -y
        apt install -y curl git
        
        # Installiere Docker
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        usermod -aG docker root
        
        # Erstelle Verzeichnisse für persistente Daten
        mkdir -p /home/birdnet/config /home/birdnet/data
        
        # Starte den BirdNET-Go Container
        # Port 8080 ist der Standardport für BirdNET-Go Web-UI
        docker run -d \
            --name birdnet-go \
            --restart unless-stopped \
            -p 8080:8080 \
            -v /home/birdnet/config:/config \
            -v /home/birdnet/data:/data \
            ghcr.io/tphakala/birdnet-go:latest \
            || error 'BirdNET Docker Container Start fehlgeschlagen'
        
        log 'BirdNET Docker Container gestartet! Web-UI auf Port 8080.'
    " || error "Installation im Container fehlgeschlagen"

    log "--- Installation abgeschlossen ---"
    
    LXC_IP_ADDR=$(pct exec ${LXC_ID} ip a show eth0 | grep -oP 'inet \K[\d.]+')
    
    log "BirdNET-Go ist nun im LXC Container ID ${LXC_ID} installiert."
    
    log "Zugriff auf das BirdNET Web-Interface über: http://${LXC_IP_ADDR}:8080"
    
    log "!!! Wichtige Nächste Schritte: RTSP-Stream Konfiguration !!!"
    log "1. Öffne das BirdNET Web-Interface unter der oben genannten Adresse."
    log "2. Navigiere zu **Settings** (Einstellungen) -> **Audio Capture**."
    log "3. Gib dort die vollständige **RTSP Stream URL** deiner Überwachungskamera ein (z.B. rtsp://user:password@192.168.1.100:554/live)."
    log "4. Speichere die Einstellungen und starte den BirdNET Service über das UI neu."
    
    log "Viel Erfolg beim Vogelbeobachten!"
}

# --- Skript Start ---

if [ "$EUID" -ne 0 ]; then
    error "Dieses Skript muss als root oder mit 'sudo' ausgeführt werden."
fi

install_birdnet
