"""Normalize the approved ImageGen walk strip: shared scale, palette and soles.

The sprite-pipeline skill's referenced helper scripts are not installed here.
This project-local normalizer uses the existing pixel-art conversion functions.
"""
from pathlib import Path
import json
import numpy as np
from PIL import Image
from pixelize_sprites import downscale, build_palette, finish

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "assets/characters/source/girl_walk_v2_raw.png"
OUT = ROOT / "assets/chapter1/pixel/girl/walk_v2"
REVIEW = ROOT / "art_review/walk_v2"
OUT.mkdir(parents=True, exist_ok=True)
REVIEW.mkdir(parents=True, exist_ok=True)
source = np.array(Image.open(RAW).convert("RGBA"))
source[source[:, :, 3] < 129] = 0
occupied = (source[:, :, 3] > 128).sum(axis=0) > 2
edges = np.diff(np.r_[False, occupied, False].astype(int))
ranges = list(zip(np.where(edges == 1)[0], np.where(edges == -1)[0]))
ranges = [(a, b) for a, b in ranges if b - a > 50]
assert len(ranges) == 8, f"Expected eight separate characters, found {ranges}"

poses = []
for left, right in ranges:
    crop = Image.fromarray(source[:, left:right], "RGBA")
    bounds = crop.getbbox()
    crop = crop.crop(bounds)
    rgba = np.asarray(crop)
    mask = rgba[:, :, 3] > 128
    head_y, head_x = np.where(mask[:round(crop.height * .35)])
    anchor_x = (int(head_x.min()) + int(head_x.max()) + 1) / 2
    # The lowest warm skin pixels above the knees locate the near gripping hand.
    rgb = rgba[:, :, :3].astype(int)
    skin = mask & (rgb[:, :, 0] > 145) & (rgb[:, :, 0] - rgb[:, :, 1] > 27) & (rgb[:, :, 1] - rgb[:, :, 2] > 14)
    skin[:round(crop.height * .48)] = False
    skin[round(crop.height * .74):] = False
    sy, sx = np.where(skin)
    assert len(sy), "Cannot identify the near hand"
    near = sy >= np.quantile(sy, .8)
    grip = np.array([np.median(sx[near]), np.median(sy[near])])
    poses.append((crop, anchor_x, grip))

scale = 65 / max(p[0].height for p in poses)
reduced = [downscale(crop, (round(crop.width * scale), round(crop.height * scale))) for crop, _, _ in poses]
palette = build_palette(reduced, 32)
frames = []
manifest = {"frames": [], "frame_size": [64, 80], "anchor": [32, 72], "scale": scale, "source": str(RAW.relative_to(ROOT))}
for index, ((crop, anchor_x, grip), (rgb, mask)) in enumerate(zip(poses, reduced)):
    art = finish(rgb, mask, palette, outline=True)
    frame = Image.new("RGBA", (64, 80))
    offset_x = 32 - round(anchor_x * scale)
    offset_y = 72 - art.height
    frame.paste(art, (offset_x, offset_y))
    path = OUT / f"walk_{index:02d}.png"
    frame.save(path)
    hand = [round(grip[0] * scale) + offset_x - 32,
            round(grip[1] * scale) + offset_y - 72]
    manifest["frames"].append({"path": str(path.relative_to(ROOT)).replace("\\", "/"), "grip": hand})
    frames.append(frame)
    print(path.name, "body", art.size, "grip", hand, "sole", frame.getbbox()[3])

(OUT / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
sheet = Image.new("RGBA", (64 * 8, 80))
for index, frame in enumerate(frames):
    sheet.paste(frame, (64 * index, 0))
sheet.resize((2048, 320), Image.Resampling.NEAREST).save(REVIEW / "walk_strip.png")
preview = []
for frame in frames:
    stage = Image.new("RGBA", (96, 88), "#8e819e")
    stage.alpha_composite(frame, (16, 4))
    preview.append(stage.convert("RGB").resize((384, 352), Image.Resampling.NEAREST))
preview[0].save(REVIEW / "walk_loop.gif", save_all=True, append_images=preview[1:], duration=60, loop=0, disposal=2)
