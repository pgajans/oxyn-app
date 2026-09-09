"""Play Store phone screenshots: 1080x1920 (9:16), RGB PNG, honest English captions.

Skips optimize / fake-battery / RAM frames that triggered the Deceptive Behavior rejection.
"""
from __future__ import annotations

import os
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

SRC = Path("/Users/eyupesen./Oxyn/docs/screenshots")
DEST = Path("/Users/eyupesen./Oxyn/store_listing/play_screenshots")
DESKTOP = Path.home() / "Desktop" / "oxyn-play-screenshots"

W, H = 1080, 1920
BG = (8, 14, 28)
FG = (255, 255, 255)
ACCENT = (0, 229, 255)

# Honest frames only. Do not include 01 (Optimize Et), 02 (fake health %),
# 05 (invented 94% health), 06 (Optimizasyon Tamamlandı / RAM).
SCREENS = [
    ("03-storage.jpg", "01-storage.png", "Review storage.", "You choose what to delete."),
    ("04-cleaner.jpg", "02-cleanup.png", "Scan files and photos.", "Nothing is removed without you."),
    ("07-trivia.jpg", "03-trivia.png", "Phone news and trivia.", "Stay current, learn quickly."),
]


def font(size: int) -> ImageFont.FreeTypeFont:
    for path, index in (
        ("/System/Library/Fonts/HelveticaNeue.ttc", 1),
        ("/System/Library/Fonts/Supplemental/Arial Bold.ttf", 0),
        ("/Library/Fonts/Arial Bold.ttf", 0),
    ):
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size=size, index=index)
            except Exception:
                continue
    return ImageFont.load_default()


def compose(src_name: str, out_name: str, line1: str, line2: str) -> Path:
    src = Image.open(SRC / src_name).convert("RGB")
    canvas = Image.new("RGB", (W, H), BG)

    title_h = 360
    draw = ImageDraw.Draw(canvas)
    f1, f2 = font(64), font(40)
    b1 = draw.textbbox((0, 0), line1, font=f1)
    b2 = draw.textbbox((0, 0), line2, font=f2)
    x1 = (W - (b1[2] - b1[0])) // 2
    x2 = (W - (b2[2] - b2[0])) // 2
    draw.text((x1, 88), line1, fill=FG, font=f1)
    draw.text((x2, 180), line2, fill=ACCENT, font=f2)

    avail_w, avail_h = W - 80, H - title_h - 48
    scale = min(avail_w / src.width, avail_h / src.height)
    nw, nh = int(src.width * scale), int(src.height * scale)
    phone = src.resize((nw, nh), Image.LANCZOS)
    px = (W - nw) // 2
    py = title_h + (avail_h - nh) // 2
    canvas.paste(phone, (px, py))

    DEST.mkdir(parents=True, exist_ok=True)
    DESKTOP.mkdir(parents=True, exist_ok=True)
    out = DEST / out_name
    canvas.save(out, "PNG", optimize=True)
    canvas.save(DESKTOP / out_name, "PNG", optimize=True)
    return out


def main() -> None:
    for src, out, a, b in SCREENS:
        path = compose(src, out, a, b)
        print(f"OK {path.name} {Image.open(path).size}")


if __name__ == "__main__":
    main()
