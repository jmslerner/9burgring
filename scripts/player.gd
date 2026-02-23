class_name Player
extends Node2D

# ── Car stats (overwritten by car_select.gd before scene load) ───────────────
# Speed multiplier: top_speed_mph * 40 = max_speed world-units/sec
# Display: speed * 0.025 = mph shown on HUD  (= speed / 40)
var max_speed:    float = 6400.0  # 160 mph * 40
var acceleration: float = 1800.0  # accel=3 baseline
var deceleration: float = 625.0   # natural slow-down when not pressing gas
var brake_force:  float = 5000.0  # braking=3 baseline
var handling:     float = 3.0     # lateral responsiveness (1=loose 5=tight)

# ── Runtime state ─────────────────────────────────────────────────────────────
var speed:      float = 0.0   # current speed (world-units/s)
var position_z: float = 0.0   # distance along track
var position_x: float = 0.0   # lateral offset (-1 = left edge, 1 = right edge)
var off_road:   bool  = false  # true when car is outside road bounds

# ── Signals ───────────────────────────────────────────────────────────────────
signal checkpoint_passed(index: int)
signal track_finished
signal wall_hit

# ── References (set by game.gd) ───────────────────────────────────────────────
var track: Track

# ── Car sprite (child node, optional) ────────────────────────────────────────
@onready var _sprite: Node2D = $CarSprite if has_node("CarSprite") else null

# Internal
var _passed_checkpoints: Array[int] = []
var _finished:       bool  = false
var _boost_t:        float = 0.0   # seconds remaining on speed boost
var _boost_mult:     float = 1.0   # current max_speed multiplier (1.0 = normal)
var _wall_cooldown:  float = 0.0   # prevents wall_hit signal from spamming

# ─────────────────────────────────────────────────────────────────────────────
func apply_car_stats(stats: Dictionary) -> void:
	# top_speed (mph) * 40 = world-units/sec; display with speed * 0.025
	# accel/braking 1–5 use wide lerp ranges so every point is felt
	var ts: float = float(stats.get("top_speed", 160))
	var ac: float = float(stats.get("accel",     3))
	var br: float = float(stats.get("braking",   3))
	handling     = float(stats.get("handling",   3))
	max_speed    = ts * 40.0
	acceleration = lerp(600.0,  3000.0, (ac - 1.0) / 4.0)
	deceleration = lerp(350.0,   900.0, (ac - 1.0) / 4.0)
	brake_force  = lerp(2500.0, 7500.0, (br - 1.0) / 4.0)

func apply_speed_boost(duration: float, mult: float) -> void:
	_boost_t    = duration
	_boost_mult = mult

func reset() -> void:
	speed      = 0.0
	position_z = 0.0
	position_x = 0.0
	off_road   = false
	_finished  = false
	_boost_t       = 0.0
	_boost_mult    = 1.0
	_wall_cooldown = 0.0
	_passed_checkpoints.clear()

# ─────────────────────────────────────────────────────────────────────────────
func _physics_process(dt: float) -> void:
	_update_boost(dt)
	_handle_input(dt)
	_update_position(dt)
	_check_checkpoints()
	_update_sprite()

func _update_boost(dt: float) -> void:
	if _boost_t > 0.0:
		_boost_t -= dt
		if _boost_t <= 0.0:
			_boost_mult = 1.0

func _handle_input(dt: float) -> void:
	if _wall_cooldown > 0.0:
		_wall_cooldown -= dt

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

	speed = clamp(speed, 0.0, max_speed * _boost_mult)

	# Steering (scales with speed for feel)
	var steer := Input.get_axis("steer_left", "steer_right")
	if steer != 0.0:
		var steer_amount := handling * steer * dt * (speed / max_speed + 0.2)
		position_x += steer_amount

	# Road-edge check
	off_road = absf(position_x) > 1.0
	# Hard wall: bounce back, big one-shot speed penalty + signal
	if absf(position_x) > 1.3:
		position_x = sign(position_x) * 1.3
		if _wall_cooldown <= 0.0:
			speed *= 0.45          # slam into barrier — big slowdown
			wall_hit.emit()
			_wall_cooldown = 2.0   # won't fire again for 2 s

func _update_position(dt: float) -> void:
	position_z += speed * dt
	if not _finished and track != null and position_z >= track.track_length:
		position_z = track.track_length
		speed = 0.0
		_finished = true
		track_finished.emit()

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
func get_speed_mph() -> int:
	return int(speed * 0.025)   # 1/40 matches the speed multiplier
