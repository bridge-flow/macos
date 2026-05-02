#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="BridgeFlow"
BUNDLE_ID="dev.bridgeflow.app"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

cd "$ROOT_DIR"
swift build
BUILD_DIR="$(swift build --show-bin-path)"
BUILD_BINARY="$BUILD_DIR/$APP_NAME"
RESOURCE_BUNDLE="$BUILD_DIR/BridgeFlow_BridgeFlow.bundle"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_CONTENTS/Resources"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"
cp "$ROOT_DIR/BridgeFlow/Info.plist" "$INFO_PLIST"

if [[ -d "$RESOURCE_BUNDLE" ]]; then
  cp -R "$RESOURCE_BUNDLE" "$APP_BUNDLE/BridgeFlow_BridgeFlow.bundle"
  cp -R "$RESOURCE_BUNDLE" "$APP_CONTENTS/Resources/BridgeFlow_BridgeFlow.bundle"
fi

ICON_SOURCE="$ROOT_DIR/BridgeFlow/Assets.xcassets/AppIcon.appiconset"
ICONSET="$DIST_DIR/AppIcon.iconset"
if [[ -d "$ICON_SOURCE" ]]; then
  rm -rf "$ICONSET"
  mkdir -p "$ICONSET"
  cp "$ICON_SOURCE/icon_16x16.png" "$ICONSET/icon_16x16.png"
  cp "$ICON_SOURCE/icon_32x32.png" "$ICONSET/icon_16x16@2x.png"
  cp "$ICON_SOURCE/icon_32x32.png" "$ICONSET/icon_32x32.png"
  cp "$ICON_SOURCE/icon_64x64.png" "$ICONSET/icon_32x32@2x.png"
  cp "$ICON_SOURCE/icon_128x128.png" "$ICONSET/icon_128x128.png"
  cp "$ICON_SOURCE/icon_256x256.png" "$ICONSET/icon_128x128@2x.png"
  cp "$ICON_SOURCE/icon_256x256.png" "$ICONSET/icon_256x256.png"
  cp "$ICON_SOURCE/icon_512x512.png" "$ICONSET/icon_256x256@2x.png"
  cp "$ICON_SOURCE/icon_512x512.png" "$ICONSET/icon_512x512.png"
  cp "$ICON_SOURCE/icon_1024x1024.png" "$ICONSET/icon_512x512@2x.png"
  iconutil -c icns "$ICONSET" -o "$APP_CONTENTS/Resources/AppIcon.icns"
fi

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
