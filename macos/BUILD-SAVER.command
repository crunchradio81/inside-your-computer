#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
DERIVED="$ROOT/.DerivedData"

echo "Inside Your Computer — macOS Saver Builder"
echo "==========================================="
echo

echo "Preparing shared renderer assets from ../index.html..."
python3 "$ROOT/prepare_renderer_assets.py"

echo "Building native macOS screen saver..."
rm -rf "$DERIVED"

xcodebuild   -project "$ROOT/InsideYourComputer.xcodeproj"   -scheme "Inside Your Computer Saver"   -configuration Release   -derivedDataPath "$DERIVED"   CODE_SIGNING_ALLOWED=NO   build

SAVER="$DERIVED/Build/Products/Release/Inside your Computer.saver"

if [[ ! -d "$SAVER" ]]; then
  echo "Build finished but saver bundle was not found."
  exit 1
fi

echo
echo "SUCCESS:"
echo "  $SAVER"
echo
echo "Install for this user with:"
echo "  mkdir -p \"$HOME/Library/Screen Savers\""
echo "  ditto \"$SAVER\" \"$HOME/Library/Screen Savers/Inside your Computer.saver\""
