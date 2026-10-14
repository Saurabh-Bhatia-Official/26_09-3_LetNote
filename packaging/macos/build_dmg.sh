#!/bin/bash
set -e

echo "Packaging LetNote for macOS (.dmg)..."
APP_PATH="build/macos/Build/Products/Release/let_note.app"
DMG_STAGING="build/macos/dmg_staging"
OUTPUT_DIR="build/macos_packages"
OUTPUT_DMG="${OUTPUT_DIR}/LetNote-macOS.dmg"

if [ ! -d "$APP_PATH" ]; then
    echo "Error: macOS application bundle not found at $APP_PATH"
    exit 1
fi

rm -rf "$DMG_STAGING" "$OUTPUT_DMG"
mkdir -p "$DMG_STAGING" "$OUTPUT_DIR"

# Copy App to staging
cp -r "$APP_PATH" "${DMG_STAGING}/LetNote.app"

# Create symlink to /Applications for easy drag-and-drop install
ln -s /Applications "${DMG_STAGING}/Applications"

# Create disk image
hdiutil create -volname "LetNote" -srcfolder "$DMG_STAGING" -ov -format UDZO "$OUTPUT_DMG"

echo "Successfully created $OUTPUT_DMG"
