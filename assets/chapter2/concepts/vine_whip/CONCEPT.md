# Peach Spirit vine-whip previews

These four transparent images are concept previews generated with the built-in image tool from the approved Peach Spirit reference. They are not game-ready animation frames and are not imported by `chapter2.gd`.

| Image | Prompt focus |
| --- | --- |
| `01_windup.png` | Same character and palette; planted feet, peach branch raised, a short living vine curls from its tip. |
| `02_whip_cast.png` | Same character; wrist flick, the vine forms a wide flexible arc to the left. |
| `03_low_sweep.png` | Same character; low, small-stance sweep with the vine just above the ground. |
| `04_long_whip.png` | Extend the cast into a roughly two-character-length S-curve for a mid-range attack. |

## Proposed automatic combat

The old physical branch thrust and sword-like slash are retired from the design. The branch is a focus; only the extended vine or falling blossoms can hurt Xiaoyu.

- **Mid range (95–280 px):** weighted choice of a waist-height long whip or a low sweep. Telegraph with a visible coiling vine for 0.45–0.55 s, lock direction before release, keep the damaging segment active for about 0.15 s, then recover for 0.45–0.6 s.
- **Far range (over 280 px):** advance a short distance or use the long whip; do not jump instantly across the arena. Limit reach to about 300 px so the player can react.
- **Close range (under 95 px):** briefly retreat or cast a short outward spiral of vine; avoid overlapping the player. Shift dash can cross the boss.
- **Airborne player:** increase the weight of a rising vine arc; aim before release, then lock the arc.
- **Phase two:** the tree releases damaging blossoms during the fight. Peach Spirit resumes the above moves while the blossoms fall.
- Reduce the immediately preceding attack's weight, vary rest time slightly, and use wall-aware movement so attack order never becomes a fixed loop.

Each hit should use Chapter 1-style short hit-stop, flash, sound, and knockback. The artwork and timings need native-scale review before replacing game assets and hitboxes.

## Selected motion direction (2026-11-18)

The five SVG files in `vector/` are self-contained vector motion previews at the game's 960×540 aspect ratio. They use one shared character drawing so her head, hair flowers, robe, and body proportions remain consistent. The PNG files beside them are review renders only.

1. Two or three small grounded steps into a long vine-whip attack.
2. At mid-to-long range, a flexible whip extends from the peach branch, with a visible windup and locked direction.
3. Occasionally jump to Xiaoyu's side-upper position and cast a downward arcing whip toward a landing position chosen before takeoff.
4. If cornered, vault past Xiaoyu and whip during the jump; resume normal AI after landing.
5. Below 50% grief, summon damaging blossoms from the tree and continue using movement and whip attacks while they fall.

The SVG images remain motion references rather than runtime sprites. The approved long, low, air, and corner whip behavior is now implemented in `scripts/chapter2.gd` with the existing pixel character frames and a code-drawn curved vine. The vine's visible path is also its collision path. The former branch thrust and slash are no longer loaded or selected in combat.
