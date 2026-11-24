"""Normalize the approved six-pose guard strip using the existing sprite pipeline.

The optional skill helper scripts are not installed. This uses the project's
shared pixel conversion functions, one common scale and one fixed foot anchor.
"""
from pathlib import Path
import json
import numpy as np
from PIL import Image
from pixelize_sprites import downscale, build_palette, finish

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'assets/characters/source/girl_guard_v1_raw.png'
OUT = ROOT / 'assets/chapter1/pixel/girl/guard_v1'
REVIEW = ROOT / 'art_review/silk_guard'
OUT.mkdir(parents=True, exist_ok=True)
REVIEW.mkdir(parents=True, exist_ok=True)
rgba = np.array(Image.open(SOURCE).convert('RGBA'))
# Remove isolated saturated generation flecks, never costume or skin colors.
r, g, b = (rgba[:, :, i].astype(int) for i in range(3))
flecks = (r > 190) & (b < 70) & ((g < 100) | (g > 180))
rgba[flecks | (rgba[:, :, 3] < 129)] = 0
occupied = (rgba[:, :, 3] > 128).sum(axis=0) > 3
edges = np.diff(np.r_[False, occupied, False].astype(int))
ranges = [(int(a), int(b)) for a, b in zip(np.where(edges == 1)[0], np.where(edges == -1)[0]) if b - a > 80]
assert len(ranges) == 6, f'Expected six isolated frames, found {ranges}'

poses = []
heights = []
for left, right in ranges:
    image = Image.fromarray(rgba[:, left:right], 'RGBA')
    bounds = image.getbbox()
    image = image.crop(bounds)
    pixels = np.array(image)
    mask = pixels[:, :, 3] > 128
    # All faces are on the left of their canopy. Avoid umbrella ribs in the head anchor.
    top = max(1, round(image.height * .30))
    dark = mask[:top, :205] & (pixels[:top, :205, :3].max(axis=2) < 125)
    hy, hx = np.where(dark)
    assert len(hx), 'Missing head anchor'
    head_x = (int(hx.min()) + int(hx.max()) + 1) / 2
    poses.append((image, head_x))
    heights.append(image.height)

scale = 65.0 / float(np.median(heights))
sizes = [(max(1, round(image.width * scale)), max(1, round(image.height * scale))) for image, _ in poses]
samples = [downscale(image, size) for (image, _), size in zip(poses, sizes)]
palette = build_palette(samples, 32)
preview = Image.new('RGBA', (128 * 3, 96 * 2))
manifest = {'frame_size': [128, 96], 'foot_anchor': [40, 88], 'scale': scale, 'frames': []}
for i, ((image, head_x), size, (rgb, mask)) in enumerate(zip(poses, sizes, samples)):
    sprite = finish(rgb, mask, palette)
    canvas = Image.new('RGBA', (128, 96))
    offset = (40 - round(head_x * scale), 88 - size[1])
    assert offset[0] >= 0 and offset[0] + size[0] <= 128 and offset[1] >= 0
    canvas.alpha_composite(sprite, offset)
    path = OUT / f'guard_{i:02d}.png'
    canvas.save(path)
    manifest['frames'].append({'path': path.relative_to(ROOT).as_posix(), 'foot_anchor': [40, 88]})
    preview.alpha_composite(canvas, ((i % 3) * 128, (i // 3) * 96))
(OUT / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
preview.resize((1152, 576), Image.Resampling.NEAREST).save(REVIEW / 'guard_preview.png')
print(f'Prepared six guard frames with common scale {scale:.4f}, anchor (40, 88).')
