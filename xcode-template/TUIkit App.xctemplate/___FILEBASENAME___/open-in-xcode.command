#!/bin/bash
#
# Quick launcher for ___VARIABLE_productName___
# Double-click this file to open the project in Xcode
#

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "Opening ___VARIABLE_productName___ in Xcode..."
echo ""
echo "⚠️  REMINDER: Check that 'My Mac' is selected as the destination"
echo "   (in the Xcode toolbar, next to the scheme name)"
echo ""

open -a Xcode "$SCRIPT_DIR"

# Give user a moment to read the message
sleep 3
