#!/usr/bin/env bash
set -euo pipefail

# Install Dart SDK if not present
if ! command -v dart &>/dev/null; then
  echo "Installing Dart SDK..."
  curl -sS "https://storage.googleapis.com/dart-archive/channels/stable/release/3.11.5/sdk/dartsdk-linux-x64-release.zip" -o /tmp/dart-sdk.zip
  unzip -qo /tmp/dart-sdk.zip -d /tmp
  export PATH="/tmp/dart-sdk/bin:$PATH"
fi

echo "Dart version: $(dart --version)"

# Activate jaspr CLI globally
dart pub global activate jaspr 2>&1

# Find where jaspr was installed and add to PATH
JASPR_BIN=$(find / -name "jaspr" -type f 2>/dev/null | head -1)
echo "Found jaspr at: $JASPR_BIN"
JASPR_DIR=$(dirname "$JASPR_BIN")
export PATH="$JASPR_DIR:$PATH"

echo "jaspr in PATH: $(which jaspr)"

# Build the site
cd website-jaspr
dart pub get
dart run tool/build.dart

echo "Build complete."
