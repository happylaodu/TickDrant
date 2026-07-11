"""Generate Tickdrant app icon set.

Renders the master 1024x1024 icon then downsamples to every size Xcode wants.

Design (v4 — v2 base + full-edge countdown sector, no hand):
- Purple gradient squircle background, inset ~10% per macOS HIG.
- White clock face (same size as v2).
- Four quadrant tints (crimson / forest / orange / gray) on the white face.
- Subtle crosshair dividers between quadrants.
- One white ring outline at the clock face rim.
- Gray countdown sector from 12 → 2 o'clock extends past the face to the
  icon edge (squircle mask clips it).
- No hand.
"""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

MASTER = 1024
INSET = 100    # macOS HIG: ~10% inset
CORNER_R = 185

Q1 = (220, 20, 60)    # crimson - Important & Urgent   (top-right, 12→3)
Q2 = (34, 139, 34)    # forest  - Important, Not Urgent (top-left,  9→12)
Q3 = (255, 140, 0)    # orange  - Urgent, Not Important (bottom-right, 3→6)
Q4 = (128, 128, 128)  # gray    - neither               (bottom-left, 6→9)

GRAD_TOP_LEFT  = (106, 121, 227)
GRAD_BOT_RIGHT = (118, 75, 162)

FACE_COLOR          = (250, 250, 252, 255)
QUADRANT_TINT_ALPHA = 100
COUNTDOWN_GRAY      = (155, 155, 160)
COUNTDOWN_ALPHA     = 150
HAND_OUTLINE        = (65, 35, 105, 255)  # deep purple
HAND_FILL           = (65, 35, 105, 255)  # solid deep purple (matches outline)

OUT_DIR = Path(__file__).resolve().parent.parent / "docs" / "icon-drafts" / "v9"


def rounded_rect_mask(size: int, inset: int, radius: int) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle(
        (inset, inset, size - inset, size - inset),
        radius=radius,
        fill=255,
    )
    return mask


def gradient_layer(size: int, top_left: tuple, bot_right: tuple) -> Image.Image:
    layer = Image.new("RGB", (size, size), top_left)
    px = layer.load()
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * (size - 1))
            r = int(top_left[0] * (1 - t) + bot_right[0] * t)
            g = int(top_left[1] * (1 - t) + bot_right[1] * t)
            b = int(top_left[2] * (1 - t) + bot_right[2] * t)
            px[x, y] = (r, g, b)
    return layer


def render_master() -> Image.Image:
    size = MASTER
    cx = cy = size // 2

    # Build on full canvas; squircle mask applied at the end.
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))

    # 1) purple gradient background
    grad = gradient_layer(size, GRAD_TOP_LEFT, GRAD_BOT_RIGHT).convert("RGBA")
    canvas.paste(grad)

    # inner edge highlight
    hl = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    hld = ImageDraw.Draw(hl)
    hld.rounded_rectangle(
        (INSET + 6, INSET + 6, size - INSET - 6, size - INSET - 6),
        radius=CORNER_R - 6, outline=(255, 255, 255, 45), width=4,
    )
    hl = hl.filter(ImageFilter.GaussianBlur(radius=2))
    canvas.alpha_composite(hl)

    # 2) white clock face
    face_r = 325
    face = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    fd = ImageDraw.Draw(face)
    fd.ellipse([cx - face_r, cy - face_r, cx + face_r, cy + face_r], fill=FACE_COLOR)
    canvas.alpha_composite(face)

    # 3) four quadrant tints on white face
    tint = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    td = ImageDraw.Draw(tint)
    inner_r = face_r - 12
    bbox = [cx - inner_r, cy - inner_r, cx + inner_r, cy + inner_r]
    for start, end, color in [
        (-90,   0, Q1),
        (  0,  90, Q3),
        ( 90, 180, Q4),
        (180, 270, Q2),
    ]:
        td.pieslice(bbox, start=start, end=end, fill=color + (QUADRANT_TINT_ALPHA,))
    canvas.alpha_composite(tint)

    # 4) crosshair quadrant dividers (subtle, same as v2)
    cross = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    cd = ImageDraw.Draw(cross)
    cd.line([(cx - inner_r, cy), (cx + inner_r, cy)], fill=(80, 80, 80, 60), width=3)
    cd.line([(cx, cy - inner_r), (cx, cy + inner_r)], fill=(80, 80, 80, 60), width=3)
    canvas.alpha_composite(cross)

    # 5) rings first — countdown sector goes on top of them (semi-transparent).
    #    Use L-mode mask + paste to punch a clean hole — reliable in PIL.
    white = Image.new("RGBA", (size, size), (255, 255, 255, 255))

    def draw_ring(canvas, center_r, half_w):
        mask = Image.new("L", (size, size), 0)
        md = ImageDraw.Draw(mask)
        r_out, r_in = center_r + half_w, center_r - half_w
        md.ellipse([cx - r_out, cy - r_out, cx + r_out, cy + r_out], fill=255)
        md.ellipse([cx - r_in,  cy - r_in,  cx + r_in,  cy + r_in],  fill=0)
        canvas.paste(white, (0, 0), mask)

    draw_ring(canvas, face_r, 3)          # inner ring: 6px wide, centred on face_r
    outer_r = face_r + 28
    draw_ring(canvas, outer_r, 5)         # outer ring: 10px wide, centred at face_r+28

    # 6) gray countdown sector 12→1 o'clock drawn ON TOP of rings, semi-transparent.
    countdown = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ctd = ImageDraw.Draw(countdown)
    big = size  # oversized; squircle mask clips it
    ctd.pieslice(
        [cx - big, cy - big, cx + big, cy + big],
        start=-90, end=-60,
        fill=COUNTDOWN_GRAY + (COUNTDOWN_ALPHA,),
    )
    canvas.alpha_composite(countdown)

    # 7) tapered arrow hand pointing to 1 o'clock (right edge of countdown sector).
    #    Shape widens from thin at center to arrow wings at the tip.
    hand_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    hd = ImageDraw.Draw(hand_layer)
    angle_rad = math.radians(30)  # 30° clockwise from 12 o'clock = 1 o'clock
    dx, dy = math.sin(angle_rad), -math.cos(angle_rad)
    px, py = math.cos(angle_rad), math.sin(angle_rad)  # perpendicular (CW)

    shaft_len   = face_r - 65   # where shaft meets arrowhead wings
    base_half_w = 5             # very thin at center pivot
    neck_half_w = 17            # shaft width at arrowhead base
    wing_half_w = 42            # arrowhead wing extent
    arrow_len   = 55            # arrowhead tip extends this far past shaft end

    neck_x, neck_y = cx + dx * shaft_len, cy + dy * shaft_len
    apex_x, apex_y = neck_x + dx * arrow_len, neck_y + dy * arrow_len

    hand_shape = [
        (cx + px * base_half_w, cy + py * base_half_w),
        (neck_x + px * neck_half_w, neck_y + py * neck_half_w),
        (neck_x + px * wing_half_w, neck_y + py * wing_half_w),
        (apex_x, apex_y),
        (neck_x - px * wing_half_w, neck_y - py * wing_half_w),
        (neck_x - px * neck_half_w, neck_y - py * neck_half_w),
        (cx - px * base_half_w, cy - py * base_half_w),
    ]
    # Fill first, then draw the outline as a closed line with rounded joints —
    # PIL's polygon(outline=...) can drop pixels at sharp corners (wing base).
    hd.polygon(hand_shape, fill=HAND_FILL)
    hd.line(hand_shape + [hand_shape[0]], fill=HAND_OUTLINE, width=7, joint="curve")
    # small pivot dot to round off the base
    pivot_r = 14
    hd.ellipse(
        [cx - pivot_r, cy - pivot_r, cx + pivot_r, cy + pivot_r],
        fill=HAND_FILL, outline=HAND_OUTLINE, width=7,
    )
    canvas.alpha_composite(hand_layer)

    # 7) clip to squircle shape
    sq_mask = rounded_rect_mask(size, INSET, CORNER_R)
    clipped = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    clipped.paste(canvas, (0, 0), sq_mask)

    return clipped


ICON_SPECS = [
    ("icon_16x16.png",      16),
    ("icon_16x16@2x.png",   32),
    ("icon_32x32.png",      32),
    ("icon_32x32@2x.png",   64),
    ("icon_128x128.png",    128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png",    256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png",    512),
    ("icon_512x512@2x.png", 1024),
]


def main():
    master = render_master()
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for name, px in ICON_SPECS:
        out = master.resize((px, px), Image.LANCZOS)
        out.save(OUT_DIR / name, "PNG", optimize=True)
        print(f"wrote {name} ({px}x{px})")


if __name__ == "__main__":
    main()
