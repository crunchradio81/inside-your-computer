# Inside Your Computer

Cross-platform recreation of the classic Microsoft Plus! 95 **Inside Your Computer** screensaver.

This repository now contains three versions:

| Version | Location | What it is |
|---|---|---|
| Web | repository root | Self-contained HTML/JavaScript version for GitHub Pages |
| macOS | [`macos/`](./macos/) | Native macOS 14+ `.saver` project |
| Android | [`android/`](./android/) | Native fullscreen Android app with STOP control |

## Play the web version

**GitHub Pages:** https://crunchradio81.github.io/inside-your-computer/

The web edition is a single self-contained `index.html`. Its PNG artwork and eight saver WAV files are embedded directly into the page.

The macOS and Android source trees reuse those same embedded assets during their builds, so the repository does not need to store three duplicate copies of the artwork and audio.

## Fidelity profile

All three versions use the same tuned behavior:

- 8 Hz 486-style simulation
- movement every second simulation tick
- 480-line logical height
- widescreen logical-width expansion
- nearest-neighbor/pixel rendering
- first sound around 6 seconds
- later sounds around every 12–18 seconds
- 4-second minimum sound gap
- 6-second same-sound repeat gap
- no overlapping audio

## Web controls

- Tap/click once to enable browser audio.
- **SOUND ON/OFF** toggles sound.
- **STOP** stops animation and audio.
- Controls fade after a few seconds and reappear on touch/click.

## macOS native version

See [`macos/README.md`](./macos/README.md).

The project builds the native:

```text
Inside your Computer.saver
```

Local build:

```bash
cd macos
chmod +x BUILD-SAVER.command
./BUILD-SAVER.command
```

A GitHub Actions workflow also builds and packages the saver automatically.

## Android native version

See [`android/README.md`](./android/README.md).

It is a normal Android application rather than a DreamService. It runs fullscreen in landscape and has a fading **STOP** button.

Local build:

```bash
cd android
chmod +x gradlew BUILD-APK.command
./BUILD-APK.command
```

A GitHub Actions workflow builds the debug APK automatically.

## Download automated builds

Open the repository's **Actions** tab:

https://github.com/crunchradio81/inside-your-computer/actions

Successful workflow runs provide downloadable artifacts:

- **InsideYourComputer-macOS-Saver**
- **InsideYourComputer-Android-APK**

## Shared asset generation

The native projects recreate their resource folders from the embedded assets in root `index.html`:

```bash
python3 macos/prepare_renderer_assets.py
python3 android/prepare_assets.py
```

This keeps the renderer data synchronized between the web, macOS, and Android editions.

## Repository structure

```text
.
├── index.html
├── macos/
│   ├── InsideYourComputer.xcodeproj
│   ├── ScreenSaver/
│   ├── Shared/
│   ├── PreviewApp/
│   └── prepare_renderer_assets.py
├── android/
│   ├── app/
│   ├── prepare_assets.py
│   └── gradlew
└── .github/workflows/
    ├── pages.yml
    ├── macos.yml
    └── android.yml
```
