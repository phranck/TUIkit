#!/bin/bash
#
# Creates a ZIP archive of the TUIkit Xcode Template
# This ZIP can be committed to the repository for easy distribution
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_NAME="TUIkit App.xctemplate"
OUTPUT_ZIP="$SCRIPT_DIR/TUIkit-App-Template.zip"

echo "Creating template ZIP archive..."
echo ""

# Remove old ZIP if exists
if [ -f "$OUTPUT_ZIP" ]; then
    echo "  Removing old ZIP..."
    rm "$OUTPUT_ZIP"
fi

# Create ZIP
echo "  Packaging template..."
cd "$SCRIPT_DIR"
zip -r "$OUTPUT_ZIP" "$TEMPLATE_NAME" \
    -x "*.DS_Store" \
    -x "*/.build/*" \
    -x "*/Package.resolved" \
    -x "*/__pycache__/*" \
    -q

# Verify ZIP
if [ -f "$OUTPUT_ZIP" ]; then
    SIZE=$(du -h "$OUTPUT_ZIP" | cut -f1)
    echo ""
    echo "✅ Template ZIP created successfully!"
    echo "   Location: $OUTPUT_ZIP"
    echo "   Size: $SIZE"
    echo ""
    echo "📦 Contents:"
    unzip -l "$OUTPUT_ZIP" | grep -E "\.swift$|\.plist$|\.md$|\.xcscheme$" | head -20
    echo ""
    echo "💡 Commit this ZIP to the repository:"
    echo "   git add TUIkit-App-Template.zip"
    echo "   git commit -m 'Update Xcode template ZIP'"
else
    echo "❌ Failed to create ZIP"
    exit 1
fi
