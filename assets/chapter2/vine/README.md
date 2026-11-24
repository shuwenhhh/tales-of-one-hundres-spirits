# Wisteria Spirit vine whip

The current character uses six one-handed casting poses in `../wisteria/single_hand/`, normalized to 192px cells. The free hand remains by the hip. The palm Marker follows the displayed pose, including an interrupted pose, and the vine remains an independent ChapterTwo child. Corner escape no longer summons a grounded vine. See `../wisteria/README.md` for the matching garden, flower rain and airborne timing integration. The existing player controls and normal hurt flow are retained.

## Art

Authored with `tools/make_peach_vine_sprites.gd`; no generated-image service used. All sprites are transparent RGBA8, nearest filtered, no mipmaps. Belt region reference includes #A39B88; the vine uses cooled related shades #494451, #62636A, #858878, #A8AA93.

- `vine_core.png`: 32×6 tile. No ring bands; broken upper-edge light and a sparse scar. Runtime width 6px → 2px.
- `vine_sprig_a.png`: 14×10 forward-leaning leaf; `vine_sprig_b.png`: 10×7 leaf.
- `vine_tip.png`: 10×6 pointed closed bud.
- `vine_flower.png`: 7×15 hanging wisteria raceme, only two per vine.
- `vine_root.png`: 12×10 leaf collar covering the stem attachment.

Leaves use a fixed seed, unequal positions, sizes, sides and inclinations. Density favors the root. Their angles lag the local segment and snap to 15°. No arbitrary fractional sprite scaling is applied.

## Motion and collision

Each segment has constant length. Root-angle changes travel through the chain with a delay per segment. Root translation is also delayed and bounded to prevent a hand-pose change from making a sharp kink. The root is synchronized with the drawn hand after each update. The target is locked at cast start.

The default wrist flick is 0.15s. With 16 segments and 0.014s delay, its wave takes another 0.21s to reach the tip: crack begins at 0.71s. Tip damage is active from 0.635s to 0.76s. Only the swept tip circle is tested against the existing coordinate-based player hitbox. Warning, relaxation, retraction and cancelled attacks do not damage.

A balanced S bend makes the tip pass through the locked target 0.035s before the crack. Straightening then reaches 12% beyond nominal range; overshoot cannot simply skip the target. The per-shot length is chosen once from the locked target and the move's maximum reach; segments are never stretched in flight. Relaxation consumes reach through curvature and settles onto the floor. Retraction removes visible length from the tip without shrinking the underlying segments.

## Inspector parameters

| Parameter | Default | Recommended range |
|---|---:|---|
| origin_mode | STAFF | STAFF for hand whip; GROUND for rooted variant |
| segments | 16 | 14–18 |
| segment_length | 18px | 10–22px; ChapterTwo sets this once per cast from reach/segments |
| segment_delay | 0.014s | 0.012–0.020s |
| warning_duration | 0.35s | 0.30–0.50s |
| extend_duration | 0.15s | 0.12–0.18s, wrist flick only |
| hold_duration | 0.05s | 0.04–0.08s, crack |
| relax_duration | 0.25s | 0.20–0.40s |
| retract_duration | 0.30s | 0.20–0.45s |
| overshoot_ratio | 0.12 | 0.10–0.15 |
| tip_contact_lead | 0.035s | 0.025–0.045s before full straightening |
| droop_strength | 0.80 | 0.50–0.90 |
| residual_wave | 0.12rad | 0.05–0.18rad |
| leaf_lag | 0.04s | 0.03–0.06s |
| shape_seed | 2197 | Any fixed integer; changes leaf layout |
| leaf_count | 10 | 8–12 |
| root_width | 6px | 5–7px |
| tip_width | 2px | 1.5–2.5px |
| tip_hit_radius | 7px | 5–9px |
| player_hit_radius | 12px | Keep 12px to match the existing virtual hurtbox |

## Review

Open `scenes/vine_attack_lab.tscn` in Godot and run the current scene (F6). Boss stands still and repeats the whip. Space toggles 1×/0.25×, P pauses, R restarts. These controls exist only in the lab.

Actual OpenGL captures: `art_review/chapter2/vine_v2/01_windup.png`, `02_wave.png`, `03_crack.png`, `04_relax.png`, `05_retract.png`; `contact_sheet.png` crops them for comparison. Regenerate with `scripts/capture_vine_keyframes.gd` using a rendering driver, not `--headless`.

Checks: `scripts/verify_vine_attack.gd` measures fixed segment length, peak tip speed, 12% straightening reach, hand attachment, damage window and tip-only collision. `scripts/verify_chapter2.gd` checks encounter flow, opening grace and the absence of ground vines during corner escape. The six casting poses are synchronized to the procedural vine phases; the vine wave remains continuous.
