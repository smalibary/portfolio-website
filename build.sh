#!/usr/bin/env bash
set -euo pipefail

# Install Dart SDK if not present
if ! command -v dart &>/dev/null; then
  echo "Installing Dart SDK..."
  DART_SDK_URL=$(curl -sS https://storage.googleapis.com/dart-archive/channels/stable/release/latest/sdk/linux/x64/dart-sdk-linux-x64-release.zip)
  curl -sS "$DART_SDK_URL" -o /tmp/dart-sdk.zip
  unzip -qo /tmp/dart-sdk.zip -d /tmp/dart
  export PATH="/tmp/dart-sdk/bin:$PATH"
fi

echo "Dart version: $(dart --version)"

# Build the site
cd website-jaspr
dart pub get
dart run tool/build.dart

echo "Build complete. Output:"
ls -la build/jaspr/
