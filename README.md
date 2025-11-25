# proxmox-birdnet-lxc-helper
Dieses Bash-Helper-Script automatisiert die Einrichtung von **BirdNET-Go** in einem **Unprivilegierten LXC Container** auf Proxmox. Es nutzt Docker und ist **speziell für die Integration von RTSP-Streams** (z.B. von Überwachungskameras mit Audio) optimiert, wodurch kein USB-Passthrough erforderlich ist.
## 🚀 Installation

Führe diese Befehle in der Proxmox Shell (SSH) aus:

1. **Script herunterladen:**
   ```bash
   wget -O birdnet-installer.sh [https://raw.githubusercontent.com/DEIN_USERNAME/DEIN_REPO/main/birdnet-installer.sh](https://raw.githubusercontent.com/DEIN_USERNAME/DEIN_REPO/main/birdnet-installer.sh)
### ✨ Features
* Erstellt einen unprivilegierten Ubuntu 22.04 LXC Container.
* Installiert Docker und Docker Compose.
* Startet den **BirdNET-Go** Container (`ghcr.io/tphakala/birdnet-go`) automatisch.
* Optimiert für Audio-Input via RTSP-Stream.

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
