# Peach Spirit motion frames

`peach-walk-source.png` and `peach-slash-source.png` were generated with the built-in image_gen tool on 2026-11-17 from the user-approved Peach Spirit image and the earlier branch-sword concept. The six `walk-00..05.png` and six `slash-00..05.png` files are 160×160 grounded game frames. Run `slice_animation.ps1` to regenerate them from the source strips. This script removes transparency noise and keeps the same canvas anchor for every frame.

Walk: alternating foot contact and passing poses, branch carried in both hands. The game advances frames by distance traveled and returns to idle when she stops. Slash: guard, raise, coil, half slash, full branch-sword slash with a small wind crescent, recovery. The slash animation is bound to the existing sweep state, without changing its damage timing.

`walk-in-scene-preview.png` and `slash-in-scene-preview.png` show the frames at 1:1 game resolution on the current Chapter 2 background. They are review sheets, not imported animation frames.

`walk-vector.svg` and `slash-vector.svg` are genuine SVG paths made of exact-color pixel rectangles from those twelve normalized frames; they contain no embedded bitmap. Run `vectorize_frames.ps1` after changing the PNG frames. This retains the approved character and pose details while making the sheets scalable, though per-limb editing remains easier in the source art.

`peach-hurt-source.png` was generated with the same approved character reference on 2026-11-17. Its three normalized `hurt-00..02.png` frames show impact, guarded stagger, and recovery. `hurt-vector.svg` contains those exact frames as SVG rectangles, and `hurt-in-scene-preview.png` is the native-resolution review sheet. Ordinary hits now use the stagger state for one second; the first flash and the small knockback remain brief. The final hit uses the hurt pose during the first second of the existing settling scene.

On 2026-11-18, the old one-image windup, swing, lunge, leap, and cast assets were retired. `peach-thrust-source.png`, `peach-leap-source.png`, and `peach-cast-source.png` were generated from the same approved Peach Spirit reference. Their normalized `thrust-00..05.png`, `leap-00..03.png`, and `cast-00..02.png` frames replace the old static poses in Chapter 2. `slice_animation.ps1` anchors the leap frames to a shared foot baseline, letting the game apply the actual airborne offset. Matching SVG sheets and native-scale scene previews are included. The thrust's world travel is capped to 64 pixels so the visible foot movement matches its displacement more closely.
