#!/bin/bash
set -e

echo "Packaging LetNote for macOS (.dmg)..."
WORKSPACE_DIR="$(pwd)"
APP_PATH="${WORKSPACE_DIR}/build/macos/Build/Products/Release/let_note.app"
OUTPUT_DIR="${WORKSPACE_DIR}/build/macos_packages"
OUTPUT_DMG="${OUTPUT_DIR}/LetNote-macOS.dmg"

if [ ! -d "$APP_PATH" ]; then
    echo "Error: macOS application bundle not found at $APP_PATH"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_DMG"

# Create standard macOS DMG directly from the application bundle
hdiutil create -volname "LetNote" -srcfolder "$APP_PATH" -ov -format UDZO "$OUTPUT_DMG"

# Also create portable zip
cd "${WORKSPACE_DIR}/build/macos/Build/Products/Release"
zip -r -q "${OUTPUT_DIR}/LetNote-macOS.zip" let_note.app
cd "$WORKSPACE_DIR"

echo "Successfully created:"
echo "- $OUTPUT_DMG"
echo "- ${OUTPUT_DIR}/LetNote-macOS.zip"
