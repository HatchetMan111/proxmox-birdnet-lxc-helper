# Proxmox BirdNET-Go LXC Helper

<div align="center">
  
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Proxmox](https://img.shields.io/badge/Proxmox-VE-orange.svg)](https://www.proxmox.com/)
[![BirdNET-Go](https://img.shields.io/badge/BirdNET-Go-green.svg)](https://github.com/tphakala/birdnet-go)

Automatisierte Installation von BirdNET-Go in einem Proxmox LXC Container

</div>

## 📋 Über BirdNET-Go

BirdNET-Go ist eine Go-Implementierung des BirdNET-Modells zur Echtzeit-Vogelerkennung durch Audio-Analyse. Perfekt für Naturbeobachter und Vogelliebhaber!

### Features
- 🎵 Echtzeit-Audioanalyse zur Vogelerkennung
- 🌐 Webbasiertes Interface
- 📊 Detaillierte Statistiken und Aufzeichnungen
- 🔊 Unterstützung verschiedener Audio-Quellen
- 🗺️ GPS-basierte Artenfilterung
- 📱 Responsive Web-UI

## 🚀 Schnellstart

### Voraussetzungen
- Proxmox VE 7.0 oder höher
- Root-Zugriff auf den Proxmox Host
- Internetverbindung
- USB-Audiogerät (Mikrofon) für die Vogelerkennung (optional bei Installation)

### Installation mit einem Befehl

Führe diesen Befehl auf deinem **Proxmox Host** (nicht im Container) aus:

```bash
bash -c "$(wget -qLO - https://raw.githubusercontent.com/HatchetMan111/proxmox-birdnet-lxc-helper/main/build.sh)"
```

Das Script wird:
1. Einen neuen unprivilegierten LXC Container erstellen
2. Debian 12 als Basis-OS installieren
3. Alle notwendigen Abhängigkeiten installieren
4. BirdNET-Go automatisch einrichten
5. Einen systemd Service konfigurieren

### Standard Container-Spezifikationen

| Parameter | Wert |
|-----------|------|
| **Container Typ** | Unprivileged (sicherer) |
| **OS** | Debian 12 |
| **Disk** | 4 GB |
| **CPU Cores** | 2 |
| **RAM** | 1024 MB |
| **Netzwerk** | DHCP (vmbr0) |

## 🎯 Nach der Installation

### 1. Zugriff auf das Web-Interface

Nach erfolgreicher Installation ist BirdNET-Go unter folgender Adresse erreichbar:

```
http://[CONTAINER-IP]:8080
```

Die IP-Adresse wird am Ende der Installation angezeigt.

### 2. USB-Audiogerät einbinden (wichtig!)

Damit BirdNET-Go dein Mikrofon nutzen kann, musst du das USB-Audiogerät an den Container durchreichen:

#### Schritt 1: USB-Gerät identifizieren
Auf dem **Proxmox Host**:
```bash
lsusb
```

Beispiel-Output:
```
Bus 001 Device 005: ID 0d8c:0014 C-Media Electronics, Inc. Audio Adapter
```

#### Schritt 2: Container-ID ermitteln
```bash
pct list
```

#### Schritt 3: USB-Gerät durchreichen
Ersetze `[CT_ID]` mit deiner Container-ID und `[BUS]:[DEVICE]` mit den Werten aus `lsusb`:

```bash
pct set [CT_ID] -usb0 host=0d8c:0014
```

Beispiel:
```bash
pct set 905 -usb0 host=0d8c:0014
```

#### Schritt 4: Container neustarten
```bash
pct reboot [CT_ID]
```

### 3. Audio-Gerät im Container konfigurieren

#### In den Container einloggen:
```bash
pct enter [CT_ID]
```

#### Verfügbare Audio-Geräte auflisten:
```bash
arecord -L
```

#### Audio-Aufnahme testen:
```bash
arecord -D sysdefault -d 5 -f cd test.wav
aplay test.wav
```

### 4. BirdNET-Go konfigurieren

#### Konfigurationsdatei bearbeiten:
```bash
nano /opt/birdnet-go/config.yaml
```

#### Wichtige Einstellungen:

```yaml
# GPS-Koordinaten für regionale Artenfilterung
birdnet:
  latitude: 48.8    # Deine Latitude
  longitude: 9.8    # Deine Longitude
  locale: de        # Sprache (de, en, etc.)
  
# Audio-Quelle
audio:
  source: sysdefault  # Ändern falls nötig (siehe arecord -L)
```

#### Service nach Änderungen neustarten:
```bash
systemctl restart birdnet-go
```

## 🔧 Verwaltung

### Wichtige Befehle

```bash
# Service Status prüfen
systemctl status birdnet-go

# Service neustarten
systemctl restart birdnet-go

# Service stoppen
systemctl stop birdnet-go

# Service starten
systemctl start birdnet-go

# Logs in Echtzeit anzeigen
journalctl -u birdnet-go -f

# Konfiguration bearbeiten
nano /opt/birdnet-go/config.yaml
```

### Update auf neueste Version

Im Container ausführen:
```bash
bash -c "$(wget -qLO - https://raw.githubusercontent.com/HatchetMan111/proxmox-birdnet-lxc-helper/main/build.sh)" -s --update
```

Oder manuell:
```bash
cd /opt/birdnet-go
systemctl stop birdnet-go
wget -qO- https://github.com/tphakala/birdnet-go/releases/latest/download/birdnet-go_Linux_x86_64.tar.gz | tar xz
chmod +x birdnet-go
systemctl start birdnet-go
```

## 📁 Datei-Struktur

```
/opt/birdnet-go/
├── birdnet-go          # Hauptprogramm
├── config.yaml         # Konfigurationsdatei
├── clips/              # Audio-Aufnahmen (falls aktiviert)
└── logs/               # Log-Dateien
```

## 🐛 Troubleshooting

### Container startet nicht
```bash
# Logs prüfen
pct status [CT_ID]
pct start [CT_ID] --debug
```

### BirdNET-Go erkennt kein Audio-Gerät
```bash
# Im Container
arecord -L                    # Verfügbare Geräte anzeigen
arecord -D sysdefault -d 5 test.wav  # Test-Aufnahme
```

### Web-Interface nicht erreichbar
```bash
# Service Status prüfen
systemctl status birdnet-go

# Firewall prüfen (auf Proxmox Host)
iptables -L -n | grep 8080

# Port prüfen
ss -tlnp | grep 8080
```

### USB-Gerät wird nicht erkannt
```bash
# Auf Proxmox Host
lsusb                         # USB-Geräte anzeigen
pct config [CT_ID]           # USB-Mapping prüfen

# Im Container
ls -la /dev/snd/             # Audio-Geräte prüfen
```

## 🔐 Sicherheit

- Der Container läuft **unprivileged** für erhöhte Sicherheit
- Standard-Port 8080 (kann in `config.yaml` geändert werden)
- Keine Ports nach außen exposed (nur im lokalen Netzwerk)
- Regelmäßige Updates empfohlen

### Reverse Proxy empfohlen

Für externen Zugriff solltest du einen Reverse Proxy (z.B. Nginx Proxy Manager) verwenden:
```nginx
location / {
    proxy_pass http://[CONTAINER-IP]:8080;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
}
```

## 🤝 Beitragen

Verbesserungsvorschläge und Pull Requests sind willkommen!

1. Fork das Repository
2. Erstelle einen Feature-Branch (`git checkout -b feature/AmazingFeature`)
3. Commit deine Änderungen (`git commit -m 'Add some AmazingFeature'`)
4. Push zum Branch (`git push origin feature/AmazingFeature`)
5. Öffne einen Pull Request

## 📝 Lizenz

Dieses Projekt ist unter der MIT-Lizenz lizenziert - siehe [LICENSE](LICENSE) für Details.

## 🙏 Credits

- **BirdNET-Go**: [tphakala/birdnet-go](https://github.com/tphakala/birdnet-go)
- **Proxmox Helper Scripts**: [community-scripts/ProxmoxVE](https://github.com/community-scripts/ProxmoxVE)
- **BirdNET**: [Original BirdNET Project](https://birdnet.cornell.edu/)

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/HatchetMan111/proxmox-birdnet-lxc-helper/issues)
- **BirdNET-Go Dokumentation**: [BirdNET-Go Docs](https://github.com/tphakala/birdnet-go/wiki)
- **Proxmox Forum**: [Proxmox Community Forum](https://forum.proxmox.com/)

## ⭐ Stern geben

Wenn dir dieses Projekt gefällt, gib ihm einen Stern auf GitHub!
