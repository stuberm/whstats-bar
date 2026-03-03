#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

APP_NAME="${APP_NAME:-WHStatsBar}"
BUNDLE_ID="${BUNDLE_ID:-com.michael.whstatsbar}"
VERSION="${VERSION:-1.0}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"
OUTPUT_DIR="${OUTPUT_DIR:-$ROOT_DIR/dist}"
BINARY_NAME="${BINARY_NAME:-whstats-bar}"
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:--}"
ICON_PATH="${ICON_PATH:-$ROOT_DIR/assets/AppIcon.icns}"
MODULE_CACHE_DIR="${MODULE_CACHE_DIR:-$ROOT_DIR/.build/ModuleCache}"
CLANG_CACHE_DIR="${CLANG_CACHE_DIR:-$ROOT_DIR/.build/ModuleCache.noindex}"

if [[ -z "${DEVELOPER_DIR:-}" ]] && [[ -d "/Applications/Xcode.app/Contents/Developer" ]]; then
  export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
fi

mkdir -p "$MODULE_CACHE_DIR" "$CLANG_CACHE_DIR"
export SWIFTPM_MODULECACHE_OVERRIDE="${SWIFTPM_MODULECACHE_OVERRIDE:-$MODULE_CACHE_DIR}"
export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-$CLANG_CACHE_DIR}"

echo "Building release binary..."
swift build -c release --package-path "$ROOT_DIR"

BINARY_PATH="$ROOT_DIR/.build/release/$BINARY_NAME"
if [[ ! -x "$BINARY_PATH" ]]; then
  echo "Error: expected binary not found at $BINARY_PATH" >&2
  exit 1
fi

APP_DIR="$OUTPUT_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "Packaging app bundle at $APP_DIR"
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$BINARY_PATH" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"

ICON_PLIST_LINES=""
if [[ -f "$ICON_PATH" ]]; then
  cp "$ICON_PATH" "$RESOURCES_DIR/AppIcon.icns"
  ICON_PLIST_LINES=$'  <key>CFBundleIconFile</key><string>AppIcon</string>\n  <key>CFBundleIconName</key><string>AppIcon</string>'
else
  echo "Warning: icon file not found at $ICON_PATH (building without custom app icon)." >&2
fi

cat > "$CONTENTS_DIR/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>$APP_NAME</string>
  <key>CFBundleDisplayName</key><string>$APP_NAME</string>
  <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
  <key>CFBundleVersion</key><string>$BUILD_NUMBER</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>CFBundleExecutable</key><string>$APP_NAME</string>
  <key>CFBundlePackageType</key><string>APPL</string>
$ICON_PLIST_LINES
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
</dict>
</plist>
EOF

echo "Codesigning app bundle (identity: $CODESIGN_IDENTITY)..."
codesign --force --deep --sign "$CODESIGN_IDENTITY" "$APP_DIR"

echo
echo "Done."
echo "App bundle: $APP_DIR"
echo "Install manually with: cp -R \"$APP_DIR\" /Applications/"
