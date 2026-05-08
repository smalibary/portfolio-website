#!/usr/bin/env bash
set -euo pipefail

# Install Dart SDK if not present
if ! command -v dart &>/dev/null; then
  echo "Installing Dart SDK..."
  curl -sS "https://storage.googleapis.com/dart-archive/channels/stable/release/3.11.5/sdk/dartsdk-linux-x64-release.zip" -o /tmp/dart-sdk.zip
  unzip -qo /tmp/dart-sdk.zip -d /tmp
  export PATH="/tmp/dart-sdk/bin:$PATH"
  echo "Dart installed at $(which dart)"
fi

echo "Dart version: $(dart --version)"

# Ensure HOME is set (Cloudflare may not set it)
export HOME="${HOME:-/opt/buildhome}"

# Activate jaspr CLI globally and add its bin to PATH
dart pub global activate jaspr 2>&1
export PATH="$HOME/.pub-cache/bin:$PATH"

# Verify jaspr is available
echo "jaspr at $(which jaspr || echo 'NOT FOUND')"
ls -la "$HOME/.pub-cache/bin/jaspr" 2>/dev/null || echo "Checking alternative paths..."
find "$HOME" -name "jaspr" -type f 2>/dev/null | head -3

# Build the site
cd website-jaspr
dart pub get
dart run tool/build.dart

echo "Build complete."
