# Wisteria battle integration

`garden.png` is the clean 960 × 540 backdrop based on the approved wisteria garden preview. The baked character and her vine were removed before import. No background character is used as a combat actor. The original peach backdrop and original character frames are retained in their source folders.

The current character is a one-handed redraw in `single_hand/`: six casting poses, four small walking steps and four jump / landing poses. The free hand stays at the side, apart from the attacking hand. All runtime cells are 192 × 192 RGBA, using a shared scale and foot anchor (source y = 182), nearest-neighbor filtering and binary alpha. The earlier 160px SVG variants remain as source references but are no longer loaded by ChapterTwo. See `single_hand/GENERATION.md` for the built-in image-generation prompts and normalization settings.

The unarmed `dance/` frames keep both hands empty before combat and after the ending. In exploration the spirit stands beneath the left tree, slightly right of its trunk, with the same subtle breathing and wind-swaying idle motion used after the final hit. Approaching her triggers the opening dialogue automatically. She draws the vine only when combat begins. See `dance/GENERATION.md` for source, prompt and frame normalization.

The procedural vine remains separate from the backdrop and character sprite. Its palm Marker2D is matched per pose, including the frozen pose when a hit interrupts the attack. The 6px → 2px stem retains fixed-length segments. Wisteria assets in `../vine/` are: 32 × 6 tiled stem, 14 × 10 / 10 × 7 leaves, 7 × 15 hanging raceme, 10 × 6 pointed bud, 12 × 10 grip collar. `tools/make_peach_vine_sprites.gd` generates these authored placeholder pixels; no downloaded plant art is used.

During battle she keeps a short, curled wisteria vine in the same palm through idle, walking, leaps, casting, and hit feedback. Starting a whip replaces that held drawing with the attack vine: it uncoils into the windup, cracks, then reels back to a hand-sized coil. The held drawing has no hit area; only the attack vine's tip can deal damage during its existing contact window.

## Timing and combat

- Default 0.35s windup; 0.15s root flick; 0.014s delay per segment; 16 links.
- The hand whip is slightly longer: long reach 340px, short reach 220px, airborne reach 285px. She normally starts attacking from around 280px instead of walking all the way to 250px. Per-attack length still follows the locked target, so nearby attacks do not overshoot arbitrarily.
- Only the last half of the tip flick and 0.05s crack can hurt; mid-stem and retract are harmless.
- The last 0.035s before the crack passes through the locked aim point, then consumes slack for 12% overreach. A balanced bend prevents the overshoot from simply missing a stationary player. Length does not stretch.
- Crack freeze: 0.035s. Existing actual hit feedback remains 0.065s freeze, white flash, knockback and 1.0s player immunity.
- Air attack commits its aim and destination at takeoff, cracks at the planned apex, then lands. It cannot turn around to track a dodging player. Landing retains the existing 2.5–3.5s punish window.
- Corner vault is now movement only. The former ground-rooted vine spawn and its orphaned attack sound were removed; opening retreat cannot trigger that surprise ground attack. All encounter vines originate at the attacking palm.
- Existing opening grace, Shift pass-through, body separation, rain damage and ending dialogue flow remain active. Rain and flower visuals are now lavender; the existing save key and chapter path are preserved.

Recommended `VineAttack` tuning: warning 0.35–0.45s, held length 70–90px, coil-to-windup 0.10–0.16s, link delay 0.012–0.018s, contact lead 0.025–0.045s, overreach 0.10–0.15, relax 0.25–0.35s, retract 0.25–0.35s. Increasing delay also delays the contact window.

`scenes/vine_attack_lab.tscn` provides stationary looping review (Space: quarter speed, P: pause, R: restart). `scripts/capture_wisteria_battle.gd` exports five whip phases plus airborne, rain and impact frames using a graphical Godot renderer. `verify_vine_attack.gd`, `verify_chapter2.gd` and `verify_wisteria_combat.gd` cover segment lengths, contact windows, interruption, encounter flow, stationary hit / dodge behavior and both facings. The rendered captures are local review files under `art_review/chapter2/wisteria_battle/`.
