# Gource — Git History Visualization

Gource visualisiert die Git-History als animierten Baum. Dateien sind Nodes, Committer fliegen als Avatare durch das Repo. Klassisch für Projekt-Timelapses.

## Installation

```bash
brew install gource
```

## Konfiguration

Config-File: `.gource.conf` im Projekt-Root.

```bash
gource --load-config .gource.conf
```

### Aktuelle Config-Einstellungen

| Setting | Wert | Zweck |
|---------|------|-------|
| `viewport` | 1920×1080 | Full HD |
| `background-colour` | `0D1117` | GitHub Dark Theme |
| `seconds-per-day` | 1.5 | Geschwindigkeit pro Tag |
| `time-scale` | 1.5 | Zusätzliche Beschleunigung |
| `highlight-colour` | `58A6FF` | GitHub Blue für aktiven User |
| `dir-name-depth` | 2 | Zeigt `Sources/TUIkit`, `Tests/TUIkitTests` |
| `file-idle-time` | 0 | Dateien verschwinden nicht |
| `camera-mode` | overview | Zeigt ganzen Baum |

### Gefilterte Pfade

- `.DS_Store`
- `.build/`
- `Packages/`

## Video Export

```bash
gource --load-config .gource.conf -o - | \
  ffmpeg -y -r 60 -f image2pipe -vcodec ppm -i - \
  -vcodec libx264 -preset medium -pix_fmt yuv420p -crf 18 \
  tui-kit-history.mp4
```

### ffmpeg-Parameter

| Flag | Bedeutung |
|------|-----------|
| `-r 60` | 60 fps Input |
| `-vcodec libx264` | H.264 Codec |
| `-preset medium` | Balance Geschwindigkeit/Qualität |
| `-pix_fmt yuv420p` | Kompatibel mit allen Playern |
| `-crf 18` | Hohe Qualität (0=lossless, 23=default, 51=worst) |

## Nützliche CLI-Flags

```bash
# Nur bestimmten Zeitraum
gource --load-config .gource.conf --start-date "2026-02-01"

# Screenshot statt Animation
gource --load-config .gource.conf --stop-at-end -o screenshot.ppm

# Bestimmten User hervorheben
gource --load-config .gource.conf --highlight-user "Frank Gregor"

# Langsamer abspielen (z.B. für längere Repos)
gource --load-config .gource.conf --seconds-per-day 3

# Mit User-Avataren (Bilder in avatars/ Ordner, Name = Dateiname)
gource --load-config .gource.conf --user-image-dir avatars/
```

## Links

- Homepage: https://gource.io
- GitHub: https://github.com/acaudwell/Gource
- Wiki: https://github.com/acaudwell/Gource/wiki
