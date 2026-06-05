"""Generate App Store iPad 13" screenshots (2064x2752 PNG, RGB) from source Gemini renders.

iPad 13" displays require 2064 x 2752 px screenshots. Since the source artwork is
portrait-oriented for phones, we paste the resized phone composition centered on a
dark canvas matching the source background gradient. The English title text is
rendered in the title region (same approach as the iPhone generator).

Output is written to ~/Desktop/oxyn-ios-screenshots-ipad/.
"""
from __future__ import annotations

import os
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ASSETS = Path("/Users/eyupesen./.cursor/projects/Users-eyupesen-Oxyn/assets")
DEST = Path.home() / "Desktop" / "oxyn-ios-screenshots-ipad"

TARGET_W = 2064
TARGET_H = 2752

PHONE_H = 2640
PHONE_W_FRACTION_OF_TARGET = 0.62

SRC_TEXT_TOP = 50
SRC_TEXT_BOTTOM = 215
SRC_H = 1024

TITLE_BG = (8, 17, 30)
TITLE_FG = (255, 255, 255)

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
        ["Track Your", "Device Health."],
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


def build_ipad_screenshot(src_path: Path, out_path: Path, lines: list[str]) -> None:
    src = Image.open(src_path).convert("RGB")
    src_w, src_h = src.size

    scale = PHONE_H / src_h
    phone_h = PHONE_H
    phone_w = int(round(src_w * scale))

    src_resized = src.resize((phone_w, phone_h), Image.LANCZOS)

    max_phone_w = int(TARGET_W * PHONE_W_FRACTION_OF_TARGET)
    if phone_w > max_phone_w:
        left = (phone_w - max_phone_w) // 2
        src_resized = src_resized.crop((left, 0, left + max_phone_w, phone_h))
        phone_w = max_phone_w

    canvas = Image.new("RGB", (TARGET_W, TARGET_H), TITLE_BG)
    paste_x = (TARGET_W - phone_w) // 2
    paste_y = (TARGET_H - phone_h) // 2
    canvas.paste(src_resized, (paste_x, paste_y))

    text_top_src = int(SRC_TEXT_TOP * scale)
    text_bottom_src = int(SRC_TEXT_BOTTOM * scale)
    pad = 40
    cover_top = max(0, paste_y + text_top_src - pad)
    cover_bottom = min(TARGET_H, paste_y + text_bottom_src + pad)

    overlay = Image.new("RGB", (TARGET_W, cover_bottom - cover_top), TITLE_BG)
    canvas.paste(overlay, (0, cover_top))

    font_size = 140
    font = load_font(font_size)
    draw = ImageDraw.Draw(canvas)

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
    canvas.save(out_path, "PNG", optimize=True)


def main() -> None:
    DEST.mkdir(parents=True, exist_ok=True)
    for src, out, lines in SCREENS:
        src_path = ASSETS / src
        out_path = DEST / out
        if not src_path.exists():
            print(f"MISSING: {src_path}")
            continue
        build_ipad_screenshot(src_path, out_path, lines)
        size = out_path.stat().st_size / 1024
        print(f"OK  {out} ({size:.1f} KB)  {TARGET_W}x{TARGET_H}")


if __name__ == "__main__":
    main()
