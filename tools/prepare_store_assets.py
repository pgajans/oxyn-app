"""Prepare Oxyn store icons and localized screenshots from the attached art.

Outputs:
  assets/images/app_icon.png                  1024 full-bleed (no white corners)
  assets/images/app_icon_play.png             512 Play listing icon
  assets/images/oxyn-feature-graphic-play.png 1024x500
  store_listing/icons/
  store_listing/play_screenshots/{en,tr}/
  store_listing/app_store_screenshots/{en,tr}/
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

SRC = Path("/Users/eyupesen./.cursor/projects/Users-eyupesen-Oxyn/assets")
ROOT = Path("/Users/eyupesen./Oxyn")
IMAGES = ROOT / "assets" / "images"
PLAY = ROOT / "store_listing" / "play_screenshots"
ASC = ROOT / "store_listing" / "app_store_screenshots"
ICONS = ROOT / "store_listing" / "icons"

LOGO = SRC / "oxyn-logo-96d10ea8-2381-4d49-a819-0432b0ef955a.jpg"

# Prefer the tighter TR storage frame (oxyn-3). oxyn-1 is a duplicate layout.
SCREENS = {
    "en": [
        ("oxyn-6-326a25c6-3060-498b-8200-dc0d6df6972d.jpg", "01-storage.png"),
        ("oxyn-4-4f59ea0b-67f8-45b2-ab6b-fed8306342e9.jpg", "02-cleanup.png"),
        ("oxyn-5-21b4a6b5-e537-4a3d-ae26-6326a6cb9e14.jpg", "03-trivia.png"),
    ],
    "tr": [
        ("oxyn-3-de68e697-de6d-4b5d-848a-49195aad596d.jpg", "01-storage.png"),
        ("oxyn-2-64b9d6ef-1b12-474d-8dc5-0100d2cf42fb.jpg", "02-trivia.png"),
    ],
}

PLAY_SIZE = (1080, 1920)
ASC_SIZE = (1290, 2796)


def sample_brand_orange(im: Image.Image) -> tuple[int, int, int]:
    px = im.convert("RGB")
    w, h = px.size
    samples = [
        px.getpixel((w // 2, 8)),
        px.getpixel((8, h // 2)),
        px.getpixel((w - 9, h // 2)),
        px.getpixel((w // 2, h - 9)),
    ]
    # Median-ish average of edge orange, skip near-white leftovers.
    oranges = [c for c in samples if c[0] > 180 and c[1] > 60]
    if not oranges:
        oranges = samples
    r = sum(c[0] for c in oranges) // len(oranges)
    g = sum(c[1] for c in oranges) // len(oranges)
    b = sum(c[2] for c in oranges) // len(oranges)
    return (r, g, b)


def full_bleed_icon(src: Path) -> tuple[Image.Image, tuple[int, int, int]]:
    im = Image.open(src).convert("RGBA")
    orange = sample_brand_orange(im)
    canvas = Image.new("RGBA", im.size, orange + (255,))
    canvas.paste(im, (0, 0), im)
    # Paint any leftover pale corners with brand orange so stores don't show
    # a white halo after they apply their own rounded mask.
    px = canvas.load()
    w, h = canvas.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if r > 245 and g > 245 and b > 245:
                px[x, y] = orange + (255,)
    return canvas.convert("RGB"), orange


def fit_on_canvas(src: Image.Image, size: tuple[int, int], bg: tuple[int, int, int]) -> Image.Image:
    canvas = Image.new("RGB", size, bg)
    scale = min(size[0] / src.width, size[1] / src.height)
    nw, nh = max(1, int(src.width * scale)), max(1, int(src.height * scale))
    fitted = src.resize((nw, nh), Image.LANCZOS)
    canvas.paste(fitted, ((size[0] - nw) // 2, (size[1] - nh) // 2))
    return canvas


def feature_graphic(icon: Image.Image, orange: tuple[int, int, int]) -> Image.Image:
    w, h = 1024, 500
    canvas = Image.new("RGB", (w, h), orange)
    mark = icon.resize((360, 360), Image.LANCZOS)
    canvas.paste(mark, (80, (h - 360) // 2))
    draw = ImageDraw.Draw(canvas)
    font_path = "/System/Library/Fonts/SFNS.ttf"
    if not Path(font_path).exists():
        font_path = "/System/Library/Fonts/Helvetica.ttc"
    try:
        title = ImageFont.truetype(font_path, 72)
        sub = ImageFont.truetype(font_path, 28)
    except OSError:
        title = ImageFont.load_default()
        sub = title
    draw.text((480, 170), "Oxyn", fill=(255, 255, 255), font=title)
    draw.text(
        (480, 260),
        "Battery & Storage Care",
        fill=(255, 255, 255),
        font=sub,
    )
    return canvas.filter(ImageFilter.SMOOTH_MORE)


def save_png(im: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    im.save(path, "PNG", optimize=True)
    print(f"OK {path.relative_to(ROOT)} {im.size}")


def main() -> None:
    icon, orange = full_bleed_icon(LOGO)
    print(f"brand orange {orange}")
    save_png(icon, IMAGES / "app_icon.png")
    play_icon = icon.resize((512, 512), Image.LANCZOS)
    save_png(play_icon, IMAGES / "app_icon_play.png")
    save_png(icon, ICONS / "appstore-1024.png")
    save_png(play_icon, ICONS / "play-512.png")
    save_png(feature_graphic(icon, orange), IMAGES / "oxyn-feature-graphic-play.png")

    for lang, items in SCREENS.items():
        for src_name, out_name in items:
            src = Image.open(SRC / src_name).convert("RGB")
            play = fit_on_canvas(src, PLAY_SIZE, (0, 0, 0))
            asc = fit_on_canvas(src, ASC_SIZE, (0, 0, 0))
            save_png(play, PLAY / lang / out_name)
            save_png(asc, ASC / lang / out_name)
            if lang == "en":
                save_png(play, PLAY / out_name)

    print("done")


if __name__ == "__main__":
    main()
