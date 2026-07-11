"""Generate Tickdrant menu bar template icon (monochrome).

Simplified echo of the app icon (v8):
- Clock face outline (thin ring)
- Filled wedge 12→1 o'clock (the countdown sector)
- Small center dot; the wedge's sharp tip terminates exactly on it

Pure black on transparent so macOS can treat the image as a template
(`isTemplate = true`) and re-tint it for light/dark menu bars.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

MASTER = 512
BLACK  = (0, 0, 0, 255)

OUT_DIR = Path(__file__).resolve().parent.parent / "docs" / "icon-drafts" / "menubar"


def render_master() -> Image.Image:
    size = MASTER
    cx = cy = size // 2

    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(canvas)

    face_r      = 210
    ring_width  = 32   # ~1px at 16pt after downscale
    wedge_r     = face_r

    # 1) clock face outline (ring) — draw filled circle then punch inner hole
    d.ellipse([cx - face_r, cy - face_r, cx + face_r, cy + face_r], fill=BLACK)
    inner = face_r - ring_width
    d.ellipse([cx - inner, cy - inner, cx + inner, cy + inner], fill=(0, 0, 0, 0))

    # 2) filled wedge 12→1 o'clock inside the face
    d.pieslice(
        [cx - wedge_r, cy - wedge_r, cx + wedge_r, cy + wedge_r],
        start=-90, end=-60, fill=BLACK,
    )

    # 3) center dot — wedge apex sits exactly on it (pieslice bbox is centered here)
    dot_r = 22
    d.ellipse([cx - dot_r, cy - dot_r, cx + dot_r, cy + dot_r], fill=BLACK)

    return canvas


# macOS menu bar template — SwiftUI/AppKit standard is 18pt but 16-22pt works.
# Provide 1x and 2x for both common target sizes.
SPECS = [
    ("menubar_16.png",     16),
    ("menubar_16@2x.png",  32),
    ("menubar_22.png",     22),
    ("menubar_22@2x.png",  44),
    ("menubar_master.png", 512),
]


def main():
    master = render_master()
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for name, px in SPECS:
        out = master if px == 512 else master.resize((px, px), Image.LANCZOS)
        out.save(OUT_DIR / name, "PNG", optimize=True)
        print(f"wrote {name} ({px}x{px})")


if __name__ == "__main__":
    main()
