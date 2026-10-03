#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"

echo "Inside Your Computer — Android APK Builder"
echo "==========================================="
echo

if [[ ! -f "$ROOT/local.properties" && -d "$HOME/Library/Android/sdk" ]]; then
  echo "sdk.dir=$HOME/Library/Android/sdk" > "$ROOT/local.properties"
fi

if [[ -z "${JAVA_HOME:-}" && -d "/Applications/Android Studio.app/Contents/jbr/Contents/Home" ]]; then
  export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
  export PATH="$JAVA_HOME/bin:$PATH"
fi

echo "Preparing assets from ../index.html..."
python3 "$ROOT/prepare_assets.py"

echo "Building debug APK..."
"$ROOT/gradlew" assembleDebug

APK="$ROOT/app/build/outputs/apk/debug/app-debug.apk"
echo
if [[ -f "$APK" ]]; then
  echo "SUCCESS:"
  echo "  $APK"
  open "$(dirname "$APK")" 2>/dev/null || true
else
  echo "Build finished but APK was not found."
  exit 1
fi
