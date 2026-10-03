# Inside Your Computer — macOS

Native macOS 14+ screen-saver recreation.

This folder contains the Xcode project for the native `.saver` bundle and the fullscreen preview/key-press host used during development.

## Fidelity

- 8 Hz 486-style simulation
- movement every second simulation tick
- 480-line logical vertical resolution
- widescreen logical-width expansion without stretching
- nearest-neighbor rendering
- first saver sound around 6 seconds
- later sounds around every 12–18 seconds
- no overlapping audio

## Shared assets

The repository keeps one canonical copy of the renderer artwork and sounds inside the self-contained web edition at the repository root.

Run:

```bash
python3 macos/prepare_renderer_assets.py
```

That creates `macos/Shared/RendererResources` with the board, 84 sprite frames, and eight saver WAV files.

## Build

Requires Xcode and macOS 14+ SDK support.

```bash
cd macos
chmod +x BUILD-SAVER.command
./BUILD-SAVER.command
```

The resulting bundle is:

```text
macos/.DerivedData/Build/Products/Release/Inside your Computer.saver
```

Install it for the current user:

```bash
mkdir -p "$HOME/Library/Screen Savers"
ditto "macos/.DerivedData/Build/Products/Release/Inside your Computer.saver" \
  "$HOME/Library/Screen Savers/Inside your Computer.saver"
```

The GitHub Actions **Build macOS** workflow also packages a downloadable saver ZIP as an Actions artifact.

The broader macOS Plus! theme work (desktop sounds, Accessibility helper, keypress launcher, and installer experiments) lives in the project history; this folder is the clean native screensaver build suitable for the public repository.
