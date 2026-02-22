class_name Player
extends Node2D

# ── Car stats (overwritten by car_select.gd before scene load) ───────────────
var max_speed:    float = 300.0   # world-units / second at top speed
var acceleration: float = 120.0   # world-units / second²
var deceleration: float = 200.0   # natural slow-down when not pressing gas
var brake_force:  float = 400.0   # braking deceleration
var handling:     float = 2.0     # lateral responsiveness (1=loose 3=tight)

# ── Runtime state ─────────────────────────────────────────────────────────────
var speed:      float = 0.0   # current speed (world-units/s)
var position_z: float = 0.0   # distance along track
var position_x: float = 0.0   # lateral offset (-1 = left edge, 1 = right edge)
var off_road:   bool  = false  # true when car is outside road bounds

# ── Signals ───────────────────────────────────────────────────────────────────
signal checkpoint_passed(index: int)

# ── References (set by game.gd) ───────────────────────────────────────────────
var track: Track

# ── Car sprite (child node, optional) ────────────────────────────────────────
@onready var _sprite: Node2D = $CarSprite if has_node("CarSprite") else null

# Internal
var _passed_checkpoints: Array[int] = []

# ─────────────────────────────────────────────────────────────────────────────
func apply_car_stats(stats: Dictionary) -> void:
	max_speed    = stats.get("max_speed",    300.0)
	acceleration = stats.get("acceleration", 120.0)
	deceleration = stats.get("deceleration", 200.0)
	brake_force  = stats.get("brake_force",  400.0)
	handling     = stats.get("handling",     2.0)

func reset() -> void:
	speed      = 0.0
	position_z = 0.0
	position_x = 0.0
	off_road   = false
	_passed_checkpoints.clear()

# ─────────────────────────────────────────────────────────────────────────────
func _physics_process(dt: float) -> void:
	_handle_input(dt)
	_update_position(dt)
	_check_checkpoints()
	_update_sprite()

func _handle_input(dt: float) -> void:
	# Throttle / brake
	if Input.is_action_pressed("accelerate"):
		speed += acceleration * dt
	elif Input.is_action_pressed("brake"):
		speed -= brake_force * dt
	else:
		speed -= deceleration * dt

	# Off-road speed penalty
	if off_road:
		speed -= deceleration * 1.5 * dt

	speed = clamp(speed, 0.0, max_speed)

	# Steering (scales with speed for feel)
	var steer := Input.get_axis("steer_left", "steer_right")
	if steer != 0.0:
		var steer_amount := handling * steer * dt * (speed / max_speed + 0.2)
		position_x += steer_amount

	# Road-edge check
	off_road = absf(position_x) > 1.0
	# Soft wall: push back but allow slight overshoot
	if absf(position_x) > 1.3:
		position_x = sign(position_x) * 1.3
		speed *= 0.96   # gravel scrub

func _update_position(dt: float) -> void:
	position_z += speed * dt
	# Wrap around track
	if track != null:
		position_z = fmod(position_z, track.track_length)
		if position_z < 0.0:
			position_z += track.track_length

func _check_checkpoints() -> void:
	if track == null:
		return
	var seg := track.get_segment(position_z)
	if seg.is_checkpoint:
		var idx := seg.index
		if idx not in _passed_checkpoints:
			_passed_checkpoints.append(idx)
			checkpoint_passed.emit(_passed_checkpoints.size() - 1)

func _update_sprite() -> void:
	if _sprite == null:
		return
	# Lean sprite slightly based on steering input
	var steer := Input.get_axis("steer_left", "steer_right")
	_sprite.rotation = lerp(_sprite.rotation, steer * 0.08, 0.2)

# ─────────────────────────────────────────────────────────────────────────────
func get_speed_kmh() -> int:
	# Convert world-units/s to a display-friendly number
	return int(speed * 0.8)
