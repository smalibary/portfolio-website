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

# Set PUB_CACHE so we know exactly where pub global installs
export PUB_CACHE="/tmp/pub-cache"
mkdir -p "$PUB_CACHE"

# Activate jaspr CLI globally
dart pub global activate jaspr 2>&1

# List what was installed
echo "--- PUB_CACHE bin contents ---"
ls -la "$PUB_CACHE/bin/" 2>/dev/null || echo "No bin dir at $PUB_CACHE/bin"
echo "--- XDG_DATA_HOME ---"
ls -la "${XDG_DATA_HOME:-unset}/pub-cache/bin/" 2>/dev/null || echo "No XDG_DATA_HOME pub-cache"
echo "--- HOME pub-cache ---"
ls -la "${HOME:-unset}/.pub-cache/bin/" 2>/dev/null || echo "No HOME/.pub-cache/bin"
echo "--- Searching for jaspr binary ---"
find /tmp -name "jaspr" -type f 2>/dev/null | head -5
find /opt -name "jaspr" -type f 2>/dev/null | head -5
find "$HOME" -name "jaspr" -type f 2>/dev/null | head -5

# Add all possible pub-cache locations to PATH
export PATH="$PUB_CACHE/bin:${HOME:-/opt/buildhome}/.pub-cache/bin:$PATH"
echo "jaspr in PATH: $(which jaspr 2>/dev/null || echo 'NOT FOUND')"

# Build the site
cd website-jaspr
dart pub get
dart run tool/build.dart

echo "Build complete."
