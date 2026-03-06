#!/bin/bash
set -euo pipefail

# deskpals Release Build Script
# Builds, signs (ad-hoc), and packages deskpals.app for distribution

VERSION="${1:-$(date +%Y%m%d)}"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="deskpals"
SCHEME="deskpals"

echo "==> Building $APP_NAME v$VERSION..."

# Clean previous builds
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Build release archive
xcodebuild \
  -project "$PROJECT_DIR/$APP_NAME.xcodeproj" \
  -scheme "$SCHEME" \
  -configuration Release \
  -archivePath "$BUILD_DIR/$APP_NAME.xcarchive" \
  archive \
  ONLY_ACTIVE_ARCH=NO \
  | tail -5

echo "==> Exporting app from archive..."

# Create export options plist for ad-hoc distribution
cat > "$BUILD_DIR/ExportOptions.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>mac-application</string>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
PLIST

# Export the archive
xcodebuild \
  -exportArchive \
  -archivePath "$BUILD_DIR/$APP_NAME.xcarchive" \
  -exportPath "$BUILD_DIR/export" \
  -exportOptionsPlist "$BUILD_DIR/ExportOptions.plist" \
  2>/dev/null || true

# If export fails (no signing identity), extract directly from archive
if [ ! -d "$BUILD_DIR/export/$APP_NAME.app" ]; then
  echo "==> Direct export failed, extracting from archive..."
  cp -R "$BUILD_DIR/$APP_NAME.xcarchive/Products/Applications/$APP_NAME.app" "$BUILD_DIR/"
else
  cp -R "$BUILD_DIR/export/$APP_NAME.app" "$BUILD_DIR/"
fi

echo "==> Ad-hoc signing..."
codesign --force --deep --sign - "$BUILD_DIR/$APP_NAME.app"

echo "==> Creating ZIP archive..."
cd "$BUILD_DIR"
ditto -c -k --keepParent "$APP_NAME.app" "$APP_NAME-$VERSION.zip"

echo "==> Creating DMG..."
if command -v create-dmg &> /dev/null; then
  create-dmg \
    --volname "$APP_NAME" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "$APP_NAME.app" 150 190 \
    --app-drop-link 450 190 \
    "$APP_NAME-$VERSION.dmg" \
    "$APP_NAME.app" \
    2>/dev/null || echo "  (DMG creation failed — install create-dmg via 'brew install create-dmg' for DMG support)"
else
  echo "  Skipping DMG (install create-dmg via 'brew install create-dmg')"
fi

echo ""
echo "==> Build complete!"
echo "    App:  $BUILD_DIR/$APP_NAME.app"
echo "    ZIP:  $BUILD_DIR/$APP_NAME-$VERSION.zip"
[ -f "$BUILD_DIR/$APP_NAME-$VERSION.dmg" ] && echo "    DMG:  $BUILD_DIR/$APP_NAME-$VERSION.dmg"
echo ""
echo "Note: This build is ad-hoc signed. Users will need to right-click -> Open"
echo "on first launch to bypass Gatekeeper. For notarized builds, use an Apple"
echo "Developer ID certificate and run 'xcrun notarytool submit'."
