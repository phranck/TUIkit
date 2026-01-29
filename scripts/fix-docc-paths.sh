#!/bin/bash
# Convert absolute paths to relative paths in DocC HTML files
# This allows the documentation to work independently of the hosting path

DOCS_API_DIR="${1:-.}"

echo "Converting absolute paths to relative in $DOCS_API_DIR..."

# Process all HTML files
find "$DOCS_API_DIR" -name "*.html" -type f | while read file; do
    # Get the depth of the file relative to DOCS_API_DIR
    relative_path="${file#$DOCS_API_DIR/}"
    depth=$(echo "$relative_path" | tr -cd '/' | wc -c)

    # Build the relative path prefix based on depth
    # For depth 0 (root index.html): .
    # For depth 1 (dir/index.html): ..
    # For depth 2 (dir/subdir/index.html): ../..
    if [ "$depth" -eq 0 ]; then
        prefix="."
    else
        prefix=$(printf '../%.0s' $(seq 1 $depth))
    fi

    # Replace absolute paths with relative paths
    sed -i '' \
        -e "s|=\"/js/|=\"$prefix/js/|g" \
        -e "s|=\"/css/|=\"$prefix/css/|g" \
        -e "s|=\"/img/|=\"$prefix/img/|g" \
        -e "s|=\"/favicon|=\"$prefix/favicon|g" \
        -e "s|src=\"/js/|src=\"$prefix/js/|g" \
        -e "s|href=\"/css/|href=\"$prefix/css/|g" \
        "$file"
done

echo "✅ Paths converted successfully"
