#!/bin/bash
set -euo pipefail

echo "HireCloud macOS Installer"

LATEST_URL=$(curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/hirenovatalent/hirenova_website/releases/latest")
LATEST_TAG="${LATEST_URL##*/}"
VERSION="${LATEST_TAG#v}"

if [[ -z "$VERSION" || "$LATEST_TAG" == "releases" || "$LATEST_TAG" == "latest" ]]; then
  echo "Error: Could not fetch latest release."
  exit 1
fi

DMG_URL="https://github.com/hirenovatalent/hirenova_website/releases/download/${LATEST_TAG}/HireCloud-${VERSION}-mac-universal.dmg"
echo "Downloading HireCloud v${VERSION}..."

TMP_DIR=$(mktemp -d)
MOUNT_DIR="$TMP_DIR/mnt"
mkdir -p "$MOUNT_DIR"

cleanup() {
  hdiutil detach "$MOUNT_DIR" -quiet 2>/dev/null || true
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

curl -fL# "$DMG_URL" -o "$TMP_DIR/HireCloud.dmg"

echo "Mounting installer..."
hdiutil attach "$TMP_DIR/HireCloud.dmg" -nobrowse -quiet -mountpoint "$MOUNT_DIR"

if [ ! -d "$MOUNT_DIR/HireCloud.app" ]; then
  echo "Error: HireCloud.app not found in DMG."
  exit 1
fi

DEST_DIR="/Applications"
if [ ! -w "$DEST_DIR" ]; then
  DEST_DIR="$HOME/Applications"
  mkdir -p "$DEST_DIR"
fi

pkill -x "HireCloud" 2>/dev/null || true
rm -rf "$DEST_DIR/HireCloud.app"

echo "Installing to $DEST_DIR/HireCloud.app..."
ditto "$MOUNT_DIR/HireCloud.app" "$DEST_DIR/HireCloud.app"

xattr -cr "$DEST_DIR/HireCloud.app"
codesign --force --deep --sign - "$DEST_DIR/HireCloud.app" 2>/dev/null || true

echo "HireCloud v${VERSION} installed. Launching..."
open "$DEST_DIR/HireCloud.app"