#!/usr/bin/env bash
# Renders every diagram source in this directory into the DocC resource
# catalog. Diagrams use a transparent background and colors that work in both
# color schemes, so the dark variant is a byte-identical copy of the light one.
set -euo pipefail
cd "$(dirname "$0")"

RESOURCES="../../Sources/TUIkit/TUIkit.docc/Resources"
PPI=288

for src in *.typ; do
  [[ "$src" == "style.typ" ]] && continue
  name="${src%.typ}"
  echo "Rendering ${name}.png"
  typst compile --format png --ppi "$PPI" "$src" "$RESOURCES/${name}.png"
  cp "$RESOURCES/${name}.png" "$RESOURCES/${name}~dark.png"
done
