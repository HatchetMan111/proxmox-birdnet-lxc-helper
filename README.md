# proxmox-birdnet-lxc-helper
Dieses Bash-Helper-Script automatisiert die Einrichtung von **BirdNET-Go** in einem **Unprivilegierten LXC Container** auf Proxmox. Es nutzt Docker und ist **speziell für die Integration von RTSP-Streams** (z.B. von Überwachungskameras mit Audio) optimiert, wodurch kein USB-Passthrough erforderlich ist.
## 🚀 Installation

Führe diese Befehle in der Proxmox Shell (SSH) aus:

# 🐦 BirdNET-Go Proxmox LXC Installer (RTSP Optimized)

Ein einfaches Helper-Script, um **BirdNET-Go** in einem **Proxmox LXC Container** zu installieren.

Dieses Script ist **speziell für die Nutzung von IP-Kameras (RTSP-Streams)** optimiert. Es benötigt **kein** USB-Mikrofon und kein kompliziertes USB-Passthrough. Es nutzt Docker innerhalb eines unprivilegierten LXC-Containers für maximale Effizienz.

## ✨ Features

* 🐧 **Basis:** Ubuntu 22.04 LTS LXC Container (Unprivileged).
* 🐳 **Docker:** Automatische Installation von Docker & Docker Compose.
* 🧠 **AI Engine:** Installiert [BirdNET-Go](https://github.com/tphakala/birdnet-go) (effizienter Go-Port der BirdNET-Pi Software).
* 📹 **RTSP Ready:** Vorbereitet für die Analyse von Audio aus Kamera-Streams.
* 🏠 **Home Assistant:** Volle MQTT Unterstützung für Sensoren.

## 🚀 Installation

Führe die folgenden Befehle in deiner **Proxmox Host-Konsole (Shell)** aus:

### Option 1: Schnellstart (Einzeiler)

```bash
wget -O birdnet_installer.sh https://raw.githubusercontent.com/HatchetMan111/proxmox-birdnet-lxc-helper/main/birdnet_installer.sh && chmod +x birdnet_installer.sh && ./birdnet_installer.sh
```

### ⚠️ Voraussetzungen
* Ein installierter Proxmox VE Server.
* Die Proxmox VE Shell (SSH-Zugriff).
* Eine **RTSP-Stream-URL** deiner Überwachungskamera (inkl. Audio und Zugangsdaten).

* ### D. Konfiguration und Nutzung (Der RTSP-Teil)

Hier erklärst du den RTSP-Setup-Prozess.

```markdown
## ⚙️ Konfiguration des RTSP-Streams

Nach erfolgreicher Installation ist der Container einsatzbereit. Nun musst du dem BirdNET-Service mitteilen, wo sich dein Audio-Stream befindet:

1. **Öffne das BirdNET-Webinterface:**
   Navigiere in deinem Browser zu `http://<IP-DEINES-CONTAINERS>:8080`

2. **Stream-URL eingeben:**
   * Gehe zu **Settings** (Einstellungen).
   * Wähle **Audio Capture**.
   * Gib deine vollständige RTSP-URL (z.B. `rtsp://<user>:<passwort>@<ip>:554/stream`) in das entsprechende Feld ein.

3. **Service starten:**
   Speichere die Einstellungen und starte den BirdNET Service über das Web-UI neu. Die Verarbeitung beginnt unmittelbar.

4. **Integration in Home Assistant:**
   * Aktiviere und konfiguriere **MQTT** im BirdNET-Go Web-UI.
   * BirdNET-Go sendet die erkannten Vögel automatisch als MQTT-Nachrichten an deinen Home Assistant Broker.
