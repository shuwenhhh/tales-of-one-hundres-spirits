extends RefCounted

# Procedural liveliness for the heroine, layered over her existing pose art:
# squash and stretch that springs back, a lean and red flash when hurt, and
# fading afterimages while dashing. Purely visual.

const GHOST_LIFE := 0.22
const GHOST_EVERY := 0.028
const HURT_TIME := 0.3

var squash := Vector2.ONE
var hurt := 0.0
var ghosts: Array[Dictionary] = []
var swings := 0
var airborne := false
var dashing := false
var ghost_clock := 0.0

# Push the body out of shape; it springs back on its own.
func kick(shape: Vector2) -> void:
	squash = shape

func flinch() -> void:
	hurt = HURT_TIME
	squash = Vector2(0.82, 1.18)

# Returns "jump", "land" or "dash" on the frame that event happens, so the
# scene can add dust; otherwise "".
func advance(delta: float, foot: Vector2, facing: int, in_air: bool, in_dash: bool) -> String:
	squash = squash.lerp(Vector2.ONE, 1.0 - exp(-13.0 * delta))
	hurt = maxf(0.0, hurt - delta)
	for i in range(ghosts.size() - 1, -1, -1):
		ghosts[i].age += delta
		if ghosts[i].age >= GHOST_LIFE:
			ghosts.remove_at(i)
	var event := ""
	if in_air and not airborne:
		squash = Vector2(0.84, 1.2)
		event = "jump"
	elif airborne and not in_air:
		squash = Vector2(1.24, 0.78)
		event = "land"
	if in_dash and not dashing:
		squash = Vector2(1.28, 0.8)
		event = "dash"
	if in_dash:
		ghost_clock -= delta
		if ghost_clock <= 0.0:
			ghost_clock = GHOST_EVERY
			ghosts.append({"foot": foot, "facing": facing, "age": 0.0})
	airborne = in_air
	dashing = in_dash
	return event

func clear() -> void:
	ghosts.clear()
	squash = Vector2.ONE
	hurt = 0.0

# Backward lean, in radians, while flinching from a hit.
func lean() -> float:
	return -0.28 * hurt / HURT_TIME

# Sprite tint: flashes red while hurt.
func tint(base: Color) -> Color:
	var h := hurt / HURT_TIME
	return Color(base.r + 0.9 * h, base.g * (1.0 - 0.6 * h), base.b * (1.0 - 0.6 * h), base.a)

func ghost_color(ghost: Dictionary) -> Color:
	return Color(0.45, 0.85, 1.0, 0.5 * (1.0 - ghost.age / GHOST_LIFE))
