# Inside Your Computer — Android

Native Android version of the Inside Your Computer screensaver recreation.

This is a regular Android app, not a DreamService. Launch it like any other app and it immediately enters an immersive landscape animation.

## Controls

- **STOP** in the upper-right stops the animation and sound, then exits.
- The STOP button fades after a few seconds.
- Tap anywhere to make the STOP button visible again.
- Android **Back** also stops and exits.
- Leaving the app stops animation and audio.

## Fidelity

- 8 Hz simulation clock
- movement advances every second simulation tick
- 480-line logical vertical resolution
- width expands to match the Android display
- nearest-neighbor rendering
- first saver sound around 6 seconds
- subsequent sounds around every 12–18 seconds
- 4-second minimum sound gap
- 6-second same-sound repeat gap
- no overlapping audio

## Shared assets

To avoid storing a second copy of all PNG/WAV resources in Git, the Android project reconstructs them from the self-contained web edition at the repository root:

`../index.html`

`prepare_assets.py` extracts:

- Board image
- 84 animation frames
- 8 saver WAV files

Gradle runs that script automatically before `preBuild`.

## Requirements

- Android Studio / Android SDK 35
- JDK 17
- Python 3
- Android 8.0+ (minSdk 26)

## Build on macOS

```bash
cd android
chmod +x gradlew BUILD-APK.command
./BUILD-APK.command
```

APK output:

```text
android/app/build/outputs/apk/debug/app-debug.apk
```

## Install with ADB

```bash
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

A GitHub Actions workflow also builds the debug APK automatically. Open the repository's **Actions** tab and download the **InsideYourComputer-Android-APK** artifact from a successful Android build.
