#!/usr/bin/env bash
# Renders Gource animation of the complete repo and exports as MP4.
# If .gource/background.mp3 (or .m4a/.wav/.ogg) exists, it's mixed in as audio.
#
# Output: .gource/tuikit-history.mp4
#
# Usage: ./gource-swift.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AVATAR_DIR="$SCRIPT_DIR/.gource/avatars"
OUTPUT=".gource/tuikit-history.mp4"
SILENT=".gource/tuikit-history-silent.mp4"

# --- Detect background audio ---
AUDIO=""
for ext in mp3 m4a wav ogg; do
  if [[ -f ".gource/background.$ext" ]]; then
    AUDIO=".gource/background.$ext"
    break
  fi
done

# --- Render video ---
echo "Rendering repo history..."
gource --load-config .gource.conf \
  --user-image-dir "$AVATAR_DIR" \
  --stop-at-end --disable-input \
  -o - \
| ffmpeg -y -r 60 -f image2pipe -vcodec ppm -i - \
    -vcodec libx264 -preset medium -pix_fmt yuv420p -crf 18 \
    "$SILENT"

# --- Mux audio if available ---
if [[ -n "$AUDIO" ]]; then
  echo "Mixing audio: $AUDIO"
  FADE_DURATION=3
  VIDEO_DURATION=$(ffprobe -v error -show_entries format=duration \
    -of csv=p=0 "$SILENT")
  FADE_START=$(echo "$VIDEO_DURATION - $FADE_DURATION" | bc)
  ffmpeg -y -i "$SILENT" -i "$AUDIO" \
    -c:v copy -c:a aac -b:a 192k \
    -af "volume=0.4,afade=t=in:d=$FADE_DURATION,afade=t=out:st=$FADE_START:d=$FADE_DURATION" \
    -shortest -movflags +faststart \
    "$OUTPUT"
  rm "$SILENT"
else
  mv "$SILENT" "$OUTPUT"
fi

echo "Done → $OUTPUT"
