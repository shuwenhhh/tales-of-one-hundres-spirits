# One-handed Wisteria Spirit redraw

Generated with the built-in `image_gen` tool, in two coherent six-frame sheets, then normalized with `tools/normalize_wisteria_single_hand.gd`. No CLI/API fallback was used.

## Files and invariants

- `cast_source.png`: original 1536 × 1024 transparent sheet; six poses in 3 × 2 cells.
- `move_source.png`: matching six-frame locomotion source, same dimensions and layout.
- `cast-00.png`–`cast-05.png`: ready, lift, overhead windup, forward sweep, extension, follow-through.
- `walk-00.png`–`walk-03.png`: small alternating footsteps.
- `leap-00.png`–`leap-03.png`: takeoff, ascent, descent, landing (source cells 0, 4, 5, 1).
- `idle.png`: casting frame 00.

All output cells are 192 × 192 with binary transparency and nearest sampling. Each 512px source cell uses the same 164px scale. Cast padding is (0,25); locomotion padding is (10,28) to align the source sheet's pelvis and foot baseline. There is no per-frame resizing, squash, or stretch. The shoe baseline is y=182. Palm markers are configured per frame in `chapter2.gd`.

Only the near hand holds a short green flexible grip. The long vine is entirely procedural, so the sprite does not contain a second whip, staff or rigid wooden weapon. The character's grey-lavender bun, profile, ivory sleeves, pink-lavender skirt and sage sash remain recognizable.

## Prompt set

### Casting sheet

Use case: identity-preserve. Production animation sprite sheet for an existing 2D pixel art game. Redraw the same adult female Wisteria Spirit as a coherent six-frame one-handed whip animation. Use the shipped sprite for face, head size and sprite style, and the selected portrait for costume details. Remove the wooden branch. Preserve grey-lavender low bun, side-swept hair, left-facing soft profile, tiny lavender floral hair ornament, ivory flowing sleeves, muted lavender-pink layered skirt, sage sash and white shoes. Not chibi. Only the near/right hand wields the vine; the free hand stays at the right hip, clearly apart, never a two-handed staff stance.

Exactly six full-body poses in three columns by two rows, transparent 1536x1024, equal square cells, consistent height, pelvis and shoe baseline; no labels or scenery. Poses in order: relaxed ready; elbow bent and hand drawn back; raised arm with elbow flexed; forward overhead sweep with trailing sleeve; near arm extended left at shoulder height; downward follow-through with relaxing wrist. Small planted weight shift, no large steps. Only a very short sage organic vine grip extends beyond the fist; no staff, sword, wooden handle or baked long vine. The game attaches the long procedural vine. Preserve crisp pixel clusters, restrained shade ramps and muted purple outlines; no blur or smooth vector treatment. Generate the entire strip in one pass to preserve identity. True transparent alpha.

### Locomotion sheet

Use case: identity-preserve. Create the companion movement sprite sheet using the casting sheet as identity and technique reference. Keep exactly the same face, swept lavender-grey low bun, floral ornaments, ivory robe, pink-lavender layered skirt, green sash, white shoes, head size and non-chibi proportions. Six full-body frames, three columns by two rows in 512px cells, transparent 1536x1024, consistent scale and baseline, all facing left, no text, ground, shadow or scenery.

The near/right hand holds a short green vine grip in front of the waist. The free hand stays on the right at hip level, clearly separate. No branch, staff, sword, long vine or two-handed grip. First four cells: four successive modest walking steps with visible alternating feet, level head and trailing hem. Fifth: jump ascent, knees slightly tucked beneath billowing skirt, toes down, free hand out for balance. Sixth: descent/landing, one foot extending down and knees softening, trailing robe lifted slightly. Same scale and identity throughout, no squash or stretching. Crisp limited-color pixel clusters, no painted glow in the alpha background.

## Integration verification

OpenGL captures in `art_review/chapter2/wisteria_battle/` show the single-hand grip during windup, extension and air attacks. `verify_wisteria_combat.gd` checks ground/air attacks in both directions against a stationary target and a dodging target. `verify_chapter2.gd` checks that opening grace and corner vault create no ground-rooted vine.
