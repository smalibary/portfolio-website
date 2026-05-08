#!/usr/bin/env bash
set -euo pipefail

# Install Dart SDK if not present
if ! command -v dart &>/dev/null; then
  echo "Installing Dart SDK..."
  curl -sS "https://storage.googleapis.com/dart-archive/channels/stable/release/3.11.5/sdk/dartsdk-linux-x64-release.zip" -o /tmp/dart-sdk.zip
  unzip -qo /tmp/dart-sdk.zip -d /tmp/dart
  export PATH="/tmp/dart-sdk/bin:$PATH"
fi

echo "Dart version: $(dart --version)"

# Build the site
cd website-jaspr
dart pub get
dart run tool/build.dart

echo "Build complete."
