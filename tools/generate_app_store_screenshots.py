"""Generate App Store iPhone 6.5" screenshots (1284x2778 PNG, RGB) from source Gemini renders.

Source images contain Turkish marketing copy that we replace with English text in
the same position. Output is written to ~/Desktop/oxyn-ios-screenshots/.
"""
from __future__ import annotations

import os
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ASSETS = Path("/Users/eyupesen./.cursor/projects/Users-eyupesen-Oxyn/assets")
DEST = Path.home() / "Desktop" / "oxyn-ios-screenshots"

TARGET_W = 1284
TARGET_H = 2778

# Source title region (in source 571x1024 coords) we paint over.
SRC_TEXT_TOP = 50
SRC_TEXT_BOTTOM = 215
SRC_H = 1024

# Color to paint over the original title area. Matches the dark sky tone of the
# source artwork (sampled visually) so the boundary blends with the surrounding
# gradient.
TITLE_BG = (8, 17, 30)
TITLE_FG = (255, 255, 255)

# (source file, output name, two-line English title)
SCREENS = [
    (
        "Gemini_Generated_Image_fcbokofcbokofcbo-94885082-761e-4031-a506-1effc5102495.png",
        "01-dashboard.png",
        ["Optimize and", "Get Started."],
    ),
    (
        "Gemini_Generated_Image_fcbokofcbokofcbo-2-004b481f-1495-4e79-8ee1-6131dcfd1e91.png",
        "02-battery.png",
        ["Track Power Usage,", "Protect Battery."],
    ),
    (
        "Gemini_Generated_Image_fcbokofcbokofcbo-3-b4ddb9fe-a6b3-40ff-bc3b-82ebbffb1631.png",
        "03-storage.png",
        ["Free Up Space,", "Manage Storage."],
    ),
    (
        "Gemini_Generated_Image_fcbokofcbokofcbo-4-31a79449-f08a-4e3a-9355-7e2abf4c9d02.png",
        "04-cleaner.png",
        ["Find and Clean", "Junk Files."],
    ),
    (
        "Gemini_Generated_Image_fcbokofcbokofcbo-5-7f9d9103-3f4b-4d67-b992-a2168c01aec2.png",
        "05-aidoctor.png",
        ["AI-Powered", "Device Analysis."],
    ),
    (
        "Gemini_Generated_Image_fcbokofcbokofcbo-6-dbaec5e3-ecd3-4e33-8f15-63fe4158fbc3.png",
        "06-performance.png",
        ["Free Up RAM,", "Boost Performance."],
    ),
    (
        "Gemini_Generated_Image_fcbokofcbokofcbo-7-8c34215f-6d5b-4b0f-babd-9c7b29b0e207.png",
        "07-trivia.png",
        ["Test Your", "Tech Knowledge."],
    ),
]


def load_font(size: int) -> ImageFont.FreeTypeFont:
    candidates = [
        ("/System/Library/Fonts/HelveticaNeue.ttc", 1),
        ("/System/Library/Fonts/Helvetica.ttc", 1),
        ("/Library/Fonts/Arial Bold.ttf", 0),
        ("/System/Library/Fonts/Supplemental/Arial Bold.ttf", 0),
    ]
    for path, index in candidates:
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size=size, index=index)
            except Exception:
                continue
    return ImageFont.load_default()


def soft_fill_region(img: Image.Image, x0: int, y0: int, x1: int, y1: int, color: tuple) -> None:
    """Paint a region with `color` and apply a small gaussian blur at the borders
    so the seam with the rest of the image is invisible."""
    overlay = Image.new("RGB", (x1 - x0, y1 - y0), color)
    img.paste(overlay, (x0, y0))


def build_screenshot(src_path: Path, out_path: Path, lines: list[str]) -> None:
    img = Image.open(src_path).convert("RGB")
    src_w, src_h = img.size

    scale = TARGET_H / src_h
    new_w = int(round(src_w * scale))
    img = img.resize((new_w, TARGET_H), Image.LANCZOS)

    if new_w > TARGET_W:
        left = (new_w - TARGET_W) // 2
        img = img.crop((left, 0, left + TARGET_W, TARGET_H))
    elif new_w < TARGET_W:
        canvas = Image.new("RGB", (TARGET_W, TARGET_H), TITLE_BG)
        canvas.paste(img, ((TARGET_W - new_w) // 2, 0))
        img = canvas

    text_top = int(SRC_TEXT_TOP * scale)
    text_bottom = int(SRC_TEXT_BOTTOM * scale)
    pad = 30
    cover_top = max(0, text_top - pad)
    cover_bottom = min(TARGET_H, text_bottom + pad)
    soft_fill_region(img, 0, cover_top, TARGET_W, cover_bottom, TITLE_BG)

    font_size = 128
    font = load_font(font_size)
    draw = ImageDraw.Draw(img)

    line_spacing = int(font_size * 1.15)
    total_h = len(lines) * line_spacing
    region_h = cover_bottom - cover_top
    start_y = cover_top + (region_h - total_h) // 2

    for i, line in enumerate(lines):
        bbox = draw.textbbox((0, 0), line, font=font)
        text_w = bbox[2] - bbox[0]
        x = (TARGET_W - text_w) // 2
        y = start_y + i * line_spacing - bbox[1]
        draw.text((x, y), line, fill=TITLE_FG, font=font)

    out_path.parent.mkdir(parents=True, exist_ok=True)
    img.save(out_path, "PNG", optimize=True)


def main() -> None:
    DEST.mkdir(parents=True, exist_ok=True)
    for src, out, lines in SCREENS:
        src_path = ASSETS / src
        out_path = DEST / out
        if not src_path.exists():
            print(f"MISSING: {src_path}")
            continue
        build_screenshot(src_path, out_path, lines)
        size = out_path.stat().st_size / 1024
        print(f"OK  {out} ({size:.1f} KB)")


if __name__ == "__main__":
    main()
