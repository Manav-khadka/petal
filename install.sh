#!/usr/bin/env bash
set -euo pipefail

echo "🌸 Installing Petal for macOS..."

REPO="Manav-khadka/petal"
DOWNLOAD_URL="https://github.com/$REPO/releases/latest/download/Petal-v1.0.0-macOS-Universal.zip"
TMP_DIR="$(mktemp -d)"

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

echo "⬇️ Downloading latest Petal release..."
curl -fsSL "$DOWNLOAD_URL" -o "$TMP_DIR/Petal.zip"

echo "📦 Installing to /Applications..."
if [ -d "/Applications/Petal.app" ]; then
    echo "  Removing existing installation..."
    rm -rf "/Applications/Petal.app"
fi

ditto -x -k "$TMP_DIR/Petal.zip" /Applications/

echo "🛡️ Clearing macOS Gatekeeper quarantine..."
xattr -cr "/Applications/Petal.app"

echo "🌸 Petal successfully installed to /Applications/Petal.app!"
echo "🚀 Launching Petal..."
open "/Applications/Petal.app"
