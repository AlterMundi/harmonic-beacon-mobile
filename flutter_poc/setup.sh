#!/bin/bash
# Setup script for the Flutter PoC
# Run this once after cloning to generate the Flutter scaffolding and resolve dependencies.
#
# Usage:
#   cd flutter_poc
#   bash setup.sh
#
# Prerequisites:
#   - Flutter SDK installed and in PATH (or set FLUTTER_BIN below)

set -e

FLUTTER_BIN="${FLUTTER_BIN:-flutter}"

echo "=== Harmonic Beacon Flutter PoC Setup ==="
echo ""

# Check Flutter
if ! command -v "$FLUTTER_BIN" &>/dev/null; then
  # Try common paths
  for candidate in /home/fede/flutter/bin/flutter "$HOME/flutter/bin/flutter"; do
    if [ -x "$candidate" ]; then
      FLUTTER_BIN="$candidate"
      break
    fi
  done
fi

echo "Using Flutter: $FLUTTER_BIN"
$FLUTTER_BIN --version
echo ""

# Run flutter create to generate native scaffolding (--overwrite preserves our custom files)
echo ">>> Generating native scaffolding with flutter create..."
$FLUTTER_BIN create --org com.altermundi --platforms android,ios . --overwrite
echo ""

# Restore our custom pubspec.yaml in case flutter create overwrote it
# (it shouldn't with --overwrite, but just in case)

# Resolve dependencies
echo ">>> Resolving dependencies with flutter pub get..."
$FLUTTER_BIN pub get
echo ""

echo "=== Setup complete! ==="
echo ""
echo "To run on Android:"
echo "  $FLUTTER_BIN run --dart-define=LIVEKIT_URL=wss://live.altermundi.net --dart-define=LIVEKIT_TOKEN=<your-token>"
echo ""
echo "To run on iOS:"
echo "  cd ios && pod install && cd .."
echo "  $FLUTTER_BIN run --dart-define=LIVEKIT_URL=wss://live.altermundi.net --dart-define=LIVEKIT_TOKEN=<your-token>"
