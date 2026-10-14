#!/bin/bash
set -e

echo "Packaging LetNote for iOS (.ipa)..."
APP_PATH="build/ios/iphoneos/Runner.app"
STAGING="build/ios/ipa_staging"
OUTPUT_DIR="build/ios_packages"
OUTPUT_IPA="${OUTPUT_DIR}/LetNote-iOS-unsigned.ipa"

if [ ! -d "$APP_PATH" ]; then
    echo "Error: iOS Runner.app not found at $APP_PATH"
    exit 1
fi

rm -rf "$STAGING" "$OUTPUT_IPA"
mkdir -p "${STAGING}/Payload" "$OUTPUT_DIR"

# Copy Runner.app into Payload
cp -r "$APP_PATH" "${STAGING}/Payload/"

# Zip Payload directory into .ipa
cd "$STAGING"
zip -r -q "../../${OUTPUT_IPA}" Payload
cd ../../

echo "Successfully created $OUTPUT_IPA"
