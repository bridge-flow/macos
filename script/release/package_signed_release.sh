#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "usage: $0 <version> [app-bundle]" >&2
  exit 2
fi

VERSION="$1"
APP_BUNDLE="${2:-dist/BridgeFlow.app}"
APP_NAME="BridgeFlow"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_PATH="$ROOT_DIR/$APP_BUNDLE"
ZIP_PATH="$DIST_DIR/$APP_NAME-$VERSION.zip"
DMG_PATH="$DIST_DIR/$APP_NAME-$VERSION.dmg"
NOTARY_ZIP="$DIST_DIR/$APP_NAME-$VERSION-notarization.zip"

require_env() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "$name is required" >&2
    exit 1
  fi
}

require_env "SIGNING_IDENTITY"
require_env "APPLE_ID"
require_env "APPLE_APP_PASSWORD"
require_env "APPLE_TEAM_ID"

if [[ ! -d "$APP_PATH" ]]; then
  echo "app bundle not found: $APP_PATH" >&2
  exit 1
fi

if [[ ! -x "$APP_PATH/Contents/MacOS/$APP_NAME" ]]; then
  echo "app executable not found or not executable: $APP_PATH/Contents/MacOS/$APP_NAME" >&2
  exit 1
fi

mkdir -p "$DIST_DIR"
rm -f "$ZIP_PATH" "$DMG_PATH" "$NOTARY_ZIP"

echo "Signing $APP_PATH"
codesign \
  --force \
  --options runtime \
  --timestamp \
  --sign "$SIGNING_IDENTITY" \
  "$APP_PATH/Contents/MacOS/$APP_NAME"

codesign \
  --force \
  --options runtime \
  --timestamp \
  --sign "$SIGNING_IDENTITY" \
  "$APP_PATH"

codesign --verify --strict --deep --verbose=2 "$APP_PATH"

echo "Submitting app bundle for notarization"
ditto -c -k --keepParent "$APP_PATH" "$NOTARY_ZIP"
xcrun notarytool submit "$NOTARY_ZIP" \
  --apple-id "$APPLE_ID" \
  --password "$APPLE_APP_PASSWORD" \
  --team-id "$APPLE_TEAM_ID" \
  --wait

echo "Stapling notarization ticket to app bundle"
xcrun stapler staple "$APP_PATH"
xcrun stapler validate "$APP_PATH"

echo "Creating release zip"
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

echo "Creating release DMG"
DMG_STAGING="$(mktemp -d)"
trap 'rm -rf "$DMG_STAGING"' EXIT
cp -R "$APP_PATH" "$DMG_STAGING/$APP_NAME.app"
ln -s /Applications "$DMG_STAGING/Applications"
hdiutil create \
  -volname "$APP_NAME $VERSION" \
  -srcfolder "$DMG_STAGING" \
  -fs HFS+ \
  -format UDBZ \
  "$DMG_PATH"

echo "Signing and notarizing release DMG"
codesign --force --timestamp --sign "$SIGNING_IDENTITY" "$DMG_PATH"
xcrun notarytool submit "$DMG_PATH" \
  --apple-id "$APPLE_ID" \
  --password "$APPLE_APP_PASSWORD" \
  --team-id "$APPLE_TEAM_ID" \
  --wait
xcrun stapler staple "$DMG_PATH"
xcrun stapler validate "$DMG_PATH"

echo "Release artifacts:"
echo "$ZIP_PATH"
echo "$DMG_PATH"
