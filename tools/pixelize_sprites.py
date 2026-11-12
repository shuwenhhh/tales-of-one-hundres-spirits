"""Convert the hand-drawn chapter 1 sprites onto one shared pixel grid.

Every sprite is reduced to the exact size it occupies on the 960x540 screen,
so one art pixel == one screen pixel for every character (the background is
already drawn 1:1). The game then draws these textures at scale 1 with NEAREST
filtering.

Per sprite:
  * premultiplied area-average downscale (no dark/bright fringes),
  * hard alpha (>= 50% coverage is solid, the rest is transparent),
  * colours snapped to one palette shared by all poses of that character,
    so colours never flicker between frames,
  * a 1px dark outline on the silhouette edge.

Originals are never modified. Run from the project root:
    python tools/pixelize_sprites.py
"""
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "assets" / "chapter1"
OUT = SRC / "pixel"

OUTLINE = (16, 15, 25)
GIRL_SCALE = 65.0 / 442.0   # was chapter1.gd draw_hero
BOSS_SCALE = 0.32           # was chapter1.gd _draw
SPIN_SCALE = 0.125          # spinning_work.gd SCALE
WHITE_HAIR = (238, 238, 242)


def downscale(img: Image.Image, size: tuple[int, int]) -> tuple[np.ndarray, np.ndarray]:
    a = np.asarray(img.convert("RGBA")).astype(np.float64) / 255.0
    a[..., :3] *= a[..., 3:4]
    small = Image.fromarray((a * 255).round().astype(np.uint8), "RGBA").resize(size, Image.BOX)
    s = np.asarray(small).astype(np.float64) / 255.0
    alpha = s[..., 3]
    rgb = np.where(alpha[..., None] > 0, s[..., :3] / np.maximum(alpha[..., None], 1e-6), 0.0)
    return np.clip(rgb * 255, 0, 255), alpha > 0.5


def scaled_size(img: Image.Image, scale: float) -> tuple[int, int]:
    return max(1, round(img.width * scale)), max(1, round(img.height * scale))


def build_palette(samples: list[tuple[np.ndarray, np.ndarray]], colors: int, keys=()) -> np.ndarray:
    px = np.concatenate([rgb[mask] for rgb, mask in samples]).astype(np.uint8)
    strip = Image.fromarray(px.reshape(1, -1, 3), "RGB")
    q = strip.quantize(colors=colors, method=Image.MEDIANCUT, kmeans=4, dither=Image.NONE)
    pal = np.array(q.getpalette()[: colors * 3], dtype=np.float64).reshape(-1, 3)
    if keys:
        pal = np.vstack([pal, np.array(keys, dtype=np.float64)])
    return pal


def finish(rgb: np.ndarray, mask: np.ndarray, pal: np.ndarray, outline: bool = True) -> Image.Image:
    h, w = mask.shape
    flat = rgb.reshape(-1, 3)
    idx = ((flat[:, None, :] - pal[None, :, :]) ** 2).sum(-1).argmin(1)
    out = pal[idx].reshape(h, w, 3).astype(np.uint8)
    if outline:
        m = Image.fromarray((mask * 255).astype(np.uint8))
        inner = np.asarray(m.filter(ImageFilter.MinFilter(3))) > 0
        out[mask & ~inner] = OUTLINE
    return Image.fromarray(np.dstack([out, (mask * 255).astype(np.uint8)]), "RGBA")


def convert_group(jobs, colors: int, keys=(), outline: bool = True):
    """jobs: list of (source path, target size, output path); one palette for all."""
    reduced = [downscale(Image.open(src), size) for src, size, _ in jobs]
    pal = build_palette(reduced, colors, keys)
    for (src, size, dst), (rgb, mask) in zip(jobs, reduced):
        dst.parent.mkdir(parents=True, exist_ok=True)
        finish(rgb, mask, pal, outline).save(dst)
        print(f"{src.relative_to(ROOT)} -> {dst.relative_to(ROOT)} {size}")


def main():
    # Heroine: six poses share one scale so the head size stays constant.
    girl = []
    for i in range(6):
        src = SRC / "girl_handdrawn" / f"pose_{i}.png"
        girl.append((src, scaled_size(Image.open(src), GIRL_SCALE), OUT / "girl" / f"pose_{i}.png"))
    convert_group(girl, 32)

    # Umbrella is drawn into a 60x11 rect (76x11 for the upward strike).
    umb = SRC / "girl_handdrawn" / "umbrella.png"
    convert_group([(umb, (60, 11), OUT / "girl" / "umbrella.png"),
                   (umb, (76, 11), OUT / "girl" / "umbrella_long.png")], 12)

    # Grandmother: battle poses, flight frames and the seated worker share a palette.
    granny = []
    for i in range(6):
        src = SRC / "boss_simple" / f"pose_{i}.png"
        granny.append((src, scaled_size(Image.open(src), BOSS_SCALE), OUT / "granny" / f"pose_{i}.png"))
    for kind in ("ascent", "landing"):
        for i in range(6):
            src = SRC / "boss_flight" / f"{kind}_{i}.png"
            granny.append((src, (256, 300), OUT / "granny" / f"{kind}_{i}.png"))
    worker = SRC / "spinning" / "worker.png"
    granny.append((worker, scaled_size(Image.open(worker), SPIN_SCALE), OUT / "spinning" / "worker.png"))
    convert_group(granny, 32, keys=(WHITE_HAIR,))

    # Spinning wheel frame and stool (props): own wood palette.
    frame = SRC / "spinning" / "frame.png"
    convert_group([(frame, scaled_size(Image.open(frame), SPIN_SCALE), OUT / "spinning" / "frame.png")], 16)


if __name__ == "__main__":
    main()
