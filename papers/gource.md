# Gource — Git History Visualization

Gource visualizes Git history as an animated tree. Files are nodes, committers fly through the repo as avatars. A classic for project timelapses.

## Installation

```bash
brew install gource
```

## Configuration

Config file: `.gource.conf` in the project root.

```bash
gource --load-config .gource.conf
```

### Current Config Settings

| Setting | Value | Purpose |
|---------|-------|---------|
| `viewport` | 1920×1080 | Full HD |
| `background-colour` | `0D1117` | GitHub Dark Theme |
| `seconds-per-day` | 1.5 | Speed per day |
| `time-scale` | 1.5 | Additional acceleration |
| `highlight-colour` | `58A6FF` | GitHub Blue for active user |
| `dir-name-depth` | 2 | Shows `Sources/TUIkit`, `Tests/TUIkitTests` |
| `file-idle-time` | 0 | Files don't disappear |
| `camera-mode` | overview | Shows entire tree |

### Filtered Paths

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

### ffmpeg Parameters

| Flag | Meaning |
|------|---------|
| `-r 60` | 60 fps Input |
| `-vcodec libx264` | H.264 Codec |
| `-preset medium` | Balance speed/quality |
| `-pix_fmt yuv420p` | Compatible with all players |
| `-crf 18` | High quality (0=lossless, 23=default, 51=worst) |

## Useful CLI Flags

```bash
# Only specific time range
gource --load-config .gource.conf --start-date "2026-02-01"

# Screenshot instead of animation
gource --load-config .gource.conf --stop-at-end -o screenshot.ppm

# Highlight specific user
gource --load-config .gource.conf --highlight-user "Frank Gregor"

# Play slower (e.g. for longer repos)
gource --load-config .gource.conf --seconds-per-day 3

# With user avatars (images in avatars/ folder, name = filename)
gource --load-config .gource.conf --user-image-dir avatars/
```

## Links

- Homepage: https://gource.io
- GitHub: https://github.com/acaudwell/Gource
- Wiki: https://github.com/acaudwell/Gource/wiki
