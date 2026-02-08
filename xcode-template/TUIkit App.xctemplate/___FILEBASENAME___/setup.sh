#!/bin/bash
#
# Setup Script for ___VARIABLE_productName___
# Run this once after creating the project to configure Xcode for macOS development
#

set -e

echo "🔧 Setting up ___VARIABLE_productName___ for Xcode..."

# Ensure we're in the project directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Open the project in Xcode with My Mac as destination
echo "📦 Opening project in Xcode..."
open -a Xcode .

# Wait a moment for Xcode to initialize
sleep 2

echo ""
echo "✅ Setup complete!"
echo ""
echo "⚠️  IMPORTANT: Please verify in Xcode that 'My Mac' is selected"
echo "   as the run destination (top toolbar, next to the scheme selector)."
echo ""
echo "📝 To build and run:"
echo "   • In Xcode: Cmd+R"
echo "   • Command line: swift run"
echo ""
