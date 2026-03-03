#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ASSETS_DIR="$ROOT_DIR/assets"
SOURCE_PNG="$ASSETS_DIR/AppIcon-1024.png"
ICONSET_DIR="$ASSETS_DIR/AppIcon.iconset"
OUTPUT_ICNS="$ASSETS_DIR/AppIcon.icns"

MODULE_CACHE_DIR="${MODULE_CACHE_DIR:-$ROOT_DIR/.build/ModuleCache}"
CLANG_CACHE_DIR="${CLANG_CACHE_DIR:-$ROOT_DIR/.build/ModuleCache.noindex}"

if [[ -z "${DEVELOPER_DIR:-}" ]] && [[ -d "/Applications/Xcode.app/Contents/Developer" ]]; then
  export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
fi

mkdir -p "$ASSETS_DIR" "$MODULE_CACHE_DIR" "$CLANG_CACHE_DIR"
export SWIFTPM_MODULECACHE_OVERRIDE="${SWIFTPM_MODULECACHE_OVERRIDE:-$MODULE_CACHE_DIR}"
export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-$CLANG_CACHE_DIR}"

echo "Generating base icon PNG..."
swift "$ROOT_DIR/scripts/generate-icon.swift" "$SOURCE_PNG"

rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

create_icon() {
  local size="$1"
  local target="$2"
  sips -z "$size" "$size" "$SOURCE_PNG" --out "$ICONSET_DIR/$target" >/dev/null
}

create_icon 16   "icon_16x16.png"
create_icon 32   "icon_16x16@2x.png"
create_icon 32   "icon_32x32.png"
create_icon 64   "icon_32x32@2x.png"
create_icon 128  "icon_128x128.png"
create_icon 256  "icon_128x128@2x.png"
create_icon 256  "icon_256x256.png"
create_icon 512  "icon_256x256@2x.png"
create_icon 512  "icon_512x512.png"
create_icon 1024 "icon_512x512@2x.png"

echo "Packaging .icns..."
iconutil -c icns "$ICONSET_DIR" -o "$OUTPUT_ICNS"

echo "Done."
echo "Icon: $OUTPUT_ICNS"
