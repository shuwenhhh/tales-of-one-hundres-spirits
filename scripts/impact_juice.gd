extends RefCounted

# Screen-level impact feedback shared by the boss fights: a quick zoom punch
# toward the point of contact, an optional shake, and a brief darkening of the
# background so the bright impact effects pop.

const ZOOM_TIME := 0.24
const DIM_TIME := 0.2
const SHAKE_TIME := 0.22

var focus := Vector2(480, 270)
var zoom_amount := 0.0
var zoom_left := 0.0
var dim_strength := 0.0
var dim_left := 0.0
var shake_size := 0.0
var shake_left := 0.0
var clock := 0.0

func punch(at: Vector2, power := 1.0, shake := true) -> void:
	focus = at
	zoom_amount = 0.06 * power
	zoom_left = ZOOM_TIME
	dim_strength = minf(0.62, 0.45 * power)
	dim_left = DIM_TIME
	if shake:
		shake_size = 7.0 * power
		shake_left = SHAKE_TIME

func advance(delta: float) -> void:
	clock += delta
	zoom_left = maxf(0.0, zoom_left - delta)
	dim_left = maxf(0.0, dim_left - delta)
	shake_left = maxf(0.0, shake_left - delta)

func clear() -> void:
	zoom_left = 0.0
	dim_left = 0.0
	shake_left = 0.0

# Moves and scales the whole scene node. `calm` honours the reduce-shake setting.
func apply(node: Node2D, calm := false) -> void:
	var zoom := 0.0 if calm else zoom_amount * pow(zoom_left / ZOOM_TIME, 2.0)
	var shake := Vector2.ZERO
	if not calm and shake_left > 0.0:
		shake = Vector2(sin(clock * 97.0), cos(clock * 113.0)) * shake_size * pow(shake_left / SHAKE_TIME, 2.0)
	node.scale = Vector2.ONE * (1.0 + zoom)
	node.position = (-focus * zoom + shake).round()

# Opacity of the dark wash to draw over the background, under the actors.
func dim() -> float:
	return dim_strength * dim_left / DIM_TIME
