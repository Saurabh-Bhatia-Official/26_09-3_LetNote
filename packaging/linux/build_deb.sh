#!/bin/bash
set -e

VERSION="1.0.0"
ARCH="amd64"
PKG_NAME="letnote"
BUILD_ROOT="build/linux/deb/${PKG_NAME}_${VERSION}_${ARCH}"

echo "Packaging LetNote for Linux (.deb)..."
rm -rf "$BUILD_ROOT"
mkdir -p "${BUILD_ROOT}/DEBIAN"
mkdir -p "${BUILD_ROOT}/usr/bin"
mkdir -p "${BUILD_ROOT}/usr/lib/${PKG_NAME}"
mkdir -p "${BUILD_ROOT}/usr/share/applications"
mkdir -p "${BUILD_ROOT}/usr/share/icons/hicolor/512x512/apps"

# Copy Linux bundle files
cp -r build/linux/x64/release/bundle/* "${BUILD_ROOT}/usr/lib/${PKG_NAME}/"

# Create symlink / launcher
cat << 'EOF' > "${BUILD_ROOT}/usr/bin/letnote"
#!/bin/bash
exec /usr/lib/letnote/let_note "$@"
EOF
chmod +x "${BUILD_ROOT}/usr/bin/letnote"

# Copy desktop entry and icon
cp packaging/linux/letnote.desktop "${BUILD_ROOT}/usr/share/applications/letnote.desktop"
cp assets/images/logo_icon.png "${BUILD_ROOT}/usr/share/icons/hicolor/512x512/apps/letnote.png"

# Control file
cat << EOF > "${BUILD_ROOT}/DEBIAN/control"
Package: ${PKG_NAME}
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: ${ARCH}
Depends: libc6, libgtk-3-0, libsecret-1-0
Maintainer: LetNote Team <contact@letnote.app>
Description: Universal Offline-First Notes Management
 LetNote is a high-performance offline-first notes application with local AES-256 encryption and SQLite FTS5 search.
EOF

# Build package
mkdir -p build/linux_packages
dpkg-deb --build --root-owner-group "$BUILD_ROOT" "build/linux_packages/LetNote-Linux-${ARCH}.deb"
echo "Successfully created build/linux_packages/LetNote-Linux-${ARCH}.deb"
