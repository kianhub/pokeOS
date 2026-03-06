#!/bin/bash
set -euo pipefail

# deskpals Release Build Script
# Builds, signs, notarizes, and packages deskpals.app for distribution
#
# Usage:
#   ./scripts/build-release.sh <version>
#   ./scripts/build-release.sh 1.0.0
#
# Environment variables (required for notarization):
#   DEVELOPER_ID_APPLICATION  - Signing identity (e.g., "Developer ID Application: Your Name (TEAMID)")
#   NOTARY_PROFILE            - Notarytool keychain profile name (default: "deskpals-notary")
#
# To store notarization credentials:
#   xcrun notarytool store-credentials "deskpals-notary" \
#     --apple-id "your@email.com" --team-id "TEAMID" --password "app-specific-password"

VERSION="${1:?Usage: $0 <version>}"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="deskpals"
SCHEME="deskpals"
SIGNING_IDENTITY="${DEVELOPER_ID_APPLICATION:-}"
NOTARY_PROFILE="${NOTARY_PROFILE:-deskpals-notary}"

if [ -z "$SIGNING_IDENTITY" ]; then
  echo "ERROR: DEVELOPER_ID_APPLICATION is not set."
  echo "  Export it before running, e.g.:"
  echo "  export DEVELOPER_ID_APPLICATION=\"Developer ID Application: Your Name (TEAMID)\""
  exit 1
fi

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
  CODE_SIGN_IDENTITY="$SIGNING_IDENTITY" \
  | tail -20

echo "==> Exporting app from archive..."

# Create export options plist for Developer ID distribution
cat > "$BUILD_DIR/ExportOptions.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
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
  -exportOptionsPlist "$BUILD_DIR/ExportOptions.plist"

cp -R "$BUILD_DIR/export/$APP_NAME.app" "$BUILD_DIR/"

echo "==> Verifying code signature..."
codesign --verify --deep --strict "$BUILD_DIR/$APP_NAME.app"
codesign -dv --verbose=2 "$BUILD_DIR/$APP_NAME.app"

echo "==> Creating DMG..."
if command -v create-dmg &> /dev/null; then
  create-dmg \
    --volname "$APP_NAME $VERSION" \
    --volicon "$BUILD_DIR/$APP_NAME.app/Contents/Resources/AppIcon.icns" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "$APP_NAME.app" 150 190 \
    --app-drop-link 450 190 \
    --no-internet-enable \
    "$BUILD_DIR/$APP_NAME-$VERSION.dmg" \
    "$BUILD_DIR/$APP_NAME.app"
else
  echo "  create-dmg not found, creating DMG with hdiutil..."
  hdiutil create -volname "$APP_NAME $VERSION" \
    -srcfolder "$BUILD_DIR/$APP_NAME.app" \
    -ov -format UDZO \
    "$BUILD_DIR/$APP_NAME-$VERSION.dmg"
fi

echo "==> Notarizing DMG..."
xcrun notarytool submit "$BUILD_DIR/$APP_NAME-$VERSION.dmg" \
  --keychain-profile "$NOTARY_PROFILE" \
  --wait

echo "==> Stapling notarization ticket..."
xcrun stapler staple "$BUILD_DIR/$APP_NAME-$VERSION.dmg"

echo "==> Verifying notarization..."
spctl --assess --type open --context context:primary-signature "$BUILD_DIR/$APP_NAME-$VERSION.dmg"

echo ""
echo "==> Build complete!"
echo "    DMG: $BUILD_DIR/$APP_NAME-$VERSION.dmg"
echo ""
echo "This build is signed with Developer ID and notarized."
echo "Users can open it without Gatekeeper warnings."
