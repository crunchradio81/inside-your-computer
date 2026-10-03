#!/usr/bin/env python3
from __future__ import annotations

import base64
import json
import re
from pathlib import Path

ANDROID_ROOT = Path(__file__).resolve().parent
REPO_ROOT = ANDROID_ROOT.parent
INDEX = REPO_ROOT / "index.html"

DRAWABLE = ANDROID_ROOT / "app/src/main/res/drawable-nodpi"
RAW = ANDROID_ROOT / "app/src/main/res/raw"


def decode_data_uri(uri: str) -> bytes:
    prefix, encoded = uri.split(",", 1)
    if ";base64" not in prefix:
        raise RuntimeError(f"Expected base64 data URI, got: {prefix}")
    return base64.b64decode(encoded)


def extract_json_object(html: str, name: str) -> dict[str, str]:
    match = re.search(
        rf"const\s+{re.escape(name)}\s*=\s*(\{{.*?\}});",
        html,
        flags=re.DOTALL,
    )
    if not match:
        raise RuntimeError(f"Could not find {name} in {INDEX}")
    return json.loads(match.group(1))


def main() -> None:
    html = INDEX.read_text(encoding="utf-8")

    board_match = re.search(
        r'board\.src="(data:image/png;base64,[^"]+)"',
        html,
    )
    if not board_match:
        raise RuntimeError("Could not find embedded board image in index.html")

    sprites = extract_json_object(html, "SPRITE_ASSETS")
    sounds = extract_json_object(html, "SOUND_ASSETS")

    DRAWABLE.mkdir(parents=True, exist_ok=True)
    RAW.mkdir(parents=True, exist_ok=True)

    (DRAWABLE / "board.png").write_bytes(decode_data_uri(board_match.group(1)))

    for name, uri in sprites.items():
        (DRAWABLE / name).write_bytes(decode_data_uri(uri))

    for name, uri in sounds.items():
        (RAW / name).write_bytes(decode_data_uri(uri))

    print(f"Prepared Android assets: 1 board, {len(sprites)} sprite frames, {len(sounds)} sounds")


if __name__ == "__main__":
    main()
