"""Compose menu bar dropdown screenshot for App Store.

Extracts the Tickdrant menu dropdown from the raw capture and places it
on a clean purple gradient background matching the app icon.

Output: docs/screenshots/05-menu-bar.png (2880x1800)
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "docs" / "screenshots" / "05-menu-bar-dropdown.png"
OUT = ROOT / "docs" / "screenshots" / "05-menu-bar.png"

# SRC is already a clean, isolated dropdown PNG (no cropping needed).
DROPDOWN_BBOX = None

# App icon gradient colours (v9)
GRAD_TOP_LEFT  = (106, 121, 227)
GRAD_BOT_RIGHT = (118, 75, 162)

CANVAS_W, CANVAS_H = 2880, 1800


def gradient(size, tl, br):
    img = Image.new("RGB", size)
    px = img.load()
    w, h = size
    denom = max(w + h - 2, 1)
    for y in range(h):
        for x in range(w):
            t = (x + y) / denom
            px[x, y] = (
                int(tl[0] * (1 - t) + br[0] * t),
                int(tl[1] * (1 - t) + br[1] * t),
                int(tl[2] * (1 - t) + br[2] * t),
            )
    return img


def drop_shadow(size, radius=30, offset=(0, 12), color=(0, 0, 0, 90)):
    w, h = size
    pad = radius * 2
    layer = Image.new("RGBA", (w + pad * 2, h + pad * 2), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.rounded_rectangle(
        (pad + offset[0], pad + offset[1], pad + offset[0] + w, pad + offset[1] + h),
        radius=40, fill=color,
    )
    return layer.filter(ImageFilter.GaussianBlur(radius=radius))


def main():
    if not SRC.exists():
        raise SystemExit(f"missing raw capture: {SRC}")

    src = Image.open(SRC).convert("RGBA")
    dropdown = src if DROPDOWN_BBOX is None else src.crop(DROPDOWN_BBOX)

    # Scale up to about 2/3 of canvas width
    target_w = int(CANVAS_W * 0.55)
    dw, dh = dropdown.size
    scale = target_w / dw
    new_size = (int(dw * scale), int(dh * scale))
    dropdown_rgba = dropdown.resize(new_size, Image.LANCZOS)

    # Build canvas
    canvas = gradient((CANVAS_W, CANVAS_H), GRAD_TOP_LEFT, GRAD_BOT_RIGHT).convert("RGBA")

    # Drop shadow behind the popup
    shadow = drop_shadow(new_size)
    paste_x = (CANVAS_W - new_size[0]) // 2
    paste_y = (CANVAS_H - new_size[1]) // 2
    sh_w, sh_h = shadow.size
    canvas.alpha_composite(
        shadow,
        (paste_x - (sh_w - new_size[0]) // 2,
         paste_y - (sh_h - new_size[1]) // 2),
    )
    canvas.alpha_composite(dropdown_rgba, (paste_x, paste_y))

    canvas.convert("RGB").save(OUT, "PNG", optimize=True)
    print(f"wrote {OUT} ({CANVAS_W}x{CANVAS_H})")


if __name__ == "__main__":
    main()
