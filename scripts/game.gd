## Game — root script for scenes/game.tscn.
## Wires together RoadRenderer, Player, HUD, and the timer/checkpoint system.
extends Node2D

# ── Timer settings ────────────────────────────────────────────────────────────
const INITIAL_TIME     := 60.0   # seconds at race start
const CHECKPOINT_BONUS := 20.0   # seconds added per checkpoint

# ── Deer obstacle settings ─────────────────────────────────────────────────────
const DEER_AHEAD      := 4000.0  # spawn deer this many world-units ahead of player
const DEER_SPACING    := 700.0   # minimum world-unit gap between deer (+ random extra)
const DEER_HIT_Z      := 280.0   # z-depth window for collision (world units)
const DEER_HIT_X      := 0.30    # lateral half-width for collision
const DEER_SPEED_MULT := 0.40    # speed multiplied by this on deer impact

# ── States ────────────────────────────────────────────────────────────────────
enum State { COUNTDOWN, RACING, GAMEOVER, FINISH }
var _state: State = State.COUNTDOWN

# ── Core objects ──────────────────────────────────────────────────────────────
var _track:    Track
var _renderer: RoadRenderer
var _player:   Player

# ── Timer ─────────────────────────────────────────────────────────────────────
var _time_left:     float = INITIAL_TIME
var _countdown:     float = 3.0
var _checkpoints_hit: int = 0
var _total_checkpoints: int = 0

# ── HUD nodes (built in _ready) ───────────────────────────────────────────────
var _hud:            CanvasLayer
var _lbl_timer:      Label
var _lbl_speed:      Label
var _lbl_checkpoint: Label
var _lbl_countdown:  Label
var _lbl_stage:      Label
var _lbl_deer_hit:   Label
var _overlay:        ColorRect   # game-over / finish screen

# ── Deer state ────────────────────────────────────────────────────────────────
# Each entry: {z: float, x: float}
var _deer:          Array = []
var _next_deer_z:   float = 3000.0   # world-z of next deer spawn
var _deer_hit_t:    float = 0.0      # countdown timer for "DEER!" flash

const STAGE_NAMES = ["SANTA CRUZ", "FELTON", "THE CLIMB", "LOS GATOS"]

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_build_scene()
	_build_hud()
	_state = State.COUNTDOWN

func _build_scene() -> void:
	# Track data
	_track = Track.new()
	_total_checkpoints = _count_checkpoints()

	# Road renderer
	_renderer = RoadRenderer.new()
	_renderer.track = _track
	add_child(_renderer)

	# Player
	_player = Player.new()
	_player.track = _track
	if not GameState.selected_car.is_empty():
		_player.apply_car_stats(GameState.selected_car)
	add_child(_player)
	_player.checkpoint_passed.connect(_on_checkpoint_passed)
	_player.track_finished.connect(_trigger_finish)

	# Draw player car (simple coloured rectangle placeholder)
	var car_rect      := ColorRect.new()
	car_rect.name     = "CarSprite"
	car_rect.size     = Vector2(40, 70)
	car_rect.position = Vector2(-20, -35)
	var car_color: Color = Color(0.80, 0.10, 0.10)
	if not GameState.selected_car.is_empty():
		car_color = GameState.selected_car.get("color", car_color)
	car_rect.color    = car_color
	# Place car at bottom-centre of screen
	_player.position  = Vector2(512, 480)
	_player.add_child(car_rect)

func _count_checkpoints() -> int:
	var n := 0
	for seg in _track.segments:
		if seg.is_checkpoint:
			n += 1
	return n

# ── HUD ───────────────────────────────────────────────────────────────────────
func _build_hud() -> void:
	_hud = CanvasLayer.new()
	add_child(_hud)

	_lbl_timer             = _make_label("60", Vector2(460, 10), 32)
	_lbl_timer.add_theme_color_override("font_color", Color(1, 0.85, 0.1))

	_lbl_speed             = _make_label("0 km/h", Vector2(10, 10), 22)
	_lbl_checkpoint        = _make_label("", Vector2(380, 50), 20)

	_lbl_countdown         = _make_label("", Vector2(430, 250), 64)
	_lbl_countdown.add_theme_color_override("font_color", Color.WHITE)

	_lbl_stage             = _make_label("STAGE 1  SANTA CRUZ", Vector2(10, 40), 16)
	_lbl_stage.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))

	_lbl_deer_hit          = _make_label("", Vector2(362, 260), 44)
	_lbl_deer_hit.add_theme_color_override("font_color", Color(1.0, 0.55, 0.05))

	_overlay               = ColorRect.new()
	_overlay.color         = Color(0, 0, 0, 0.7)
	_overlay.size          = Vector2(1024, 600)
	_overlay.visible       = false
	_hud.add_child(_overlay)

	var _overlay_label     = _make_label("", Vector2(300, 240), 48)
	_overlay_label.name    = "OverlayLabel"
	_overlay.add_child(_make_label("Press ENTER to continue", Vector2(320, 320), 22))

func _make_label(text: String, pos: Vector2, font_size: int) -> Label:
	var lbl := Label.new()
	lbl.text     = text
	lbl.position = pos
	lbl.add_theme_font_size_override("font_size", font_size)
	_hud.add_child(lbl)
	return lbl

# ── Main loop ─────────────────────────────────────────────────────────────────
func _process(dt: float) -> void:
	match _state:
		State.COUNTDOWN: _do_countdown(dt)
		State.RACING:    _do_racing(dt)
		State.GAMEOVER:  _do_end_screen()
		State.FINISH:    _do_end_screen()

func _do_countdown(dt: float) -> void:
	_countdown -= dt
	if _countdown > 2.0:
		_lbl_countdown.text = "3"
	elif _countdown > 1.0:
		_lbl_countdown.text = "2"
	elif _countdown > 0.0:
		_lbl_countdown.text = "1"
	else:
		_lbl_countdown.text = "GO!"
		if _countdown < -0.4:
			_lbl_countdown.visible = false
			_state = State.RACING

func _do_racing(dt: float) -> void:
	# Feed player state to renderer
	_renderer.player_z = _player.position_z
	_renderer.player_x = _player.position_x

	# Update timer
	_time_left -= dt
	if _time_left <= 0.0:
		_time_left = 0.0
		_trigger_gameover()
		return

	# Deer
	_tick_deer(dt)

	# Update engine audio
	var accel := Input.is_action_pressed("accelerate")
	var brake := Input.is_action_pressed("brake")
	AudioManager.update_engine(_player.speed / _player.max_speed, accel, brake)

	# HUD
	var secs   := int(ceil(_time_left))
	var tenths := int((_time_left - floorf(_time_left)) * 10.0)
	_lbl_timer.text = "%d.%d" % [secs, tenths]
	_lbl_timer.add_theme_color_override("font_color",
		Color(1, 0.1, 0.1) if _time_left < 10.0 else Color(1, 0.85, 0.1))
	_lbl_speed.text = "%d km/h" % _player.get_speed_kmh()

func _do_end_screen() -> void:
	if Input.is_action_just_pressed("ui_accept"):
		AudioManager.stop_engine()
		AudioManager.stop_music()
		get_tree().change_scene_to_file("res://scenes/car_select.tscn")

# ── Deer obstacle system ──────────────────────────────────────────────────────

func _tick_deer(dt: float) -> void:
	# Spawn deer ahead of the player
	var pz := _player.position_z
	while _next_deer_z < pz + DEER_AHEAD and _next_deer_z < _track.track_length - 600.0:
		_deer.append({"z": _next_deer_z, "x": randf_range(-0.72, 0.72)})
		_next_deer_z += DEER_SPACING + randf_range(0.0, 500.0)

	# Collision check and despawn (iterate backwards to safely remove)
	var i := _deer.size() - 1
	while i >= 0:
		var d: Dictionary = _deer[i]
		var dz: float = d["z"]
		var dx: float = d["x"]
		var dz_diff := dz - pz
		if dz_diff < -400.0:
			# Well behind the player — clean up
			_deer.remove_at(i)
		elif dz_diff >= 0.0 and dz_diff <= DEER_HIT_Z:
			if absf(_player.position_x - dx) < DEER_HIT_X:
				# Impact!
				_player.speed *= DEER_SPEED_MULT
				_deer.remove_at(i)
				_deer_hit_t = 1.4
				_lbl_deer_hit.text = "DEER!"
				AudioManager.play_sfx("hit")
		i -= 1

	# Expire the deer-hit flash
	if _deer_hit_t > 0.0:
		_deer_hit_t -= dt
		if _deer_hit_t <= 0.0:
			_lbl_deer_hit.text = ""

	# Update renderer
	_renderer.deer_list.clear()
	for d: Dictionary in _deer:
		_renderer.deer_list.append({"z": d["z"], "x": d["x"]})

# ── Checkpoint ────────────────────────────────────────────────────────────────
func _on_checkpoint_passed(idx: int) -> void:
	_checkpoints_hit += 1
	_time_left       += CHECKPOINT_BONUS
	AudioManager.play_sfx("checkpoint")

	# Advance stage label (checkpoint N puts you in stage N+1)
	var stage := _checkpoints_hit + 1
	_lbl_stage.text = "STAGE %d  %s" % [stage, STAGE_NAMES[stage - 1]]
	_lbl_checkpoint.text = "CHECKPOINT! +%ds" % int(CHECKPOINT_BONUS)
	await get_tree().create_timer(2.0).timeout
	if _state == State.RACING:
		_lbl_checkpoint.text = ""

func _trigger_gameover() -> void:
	_state = State.GAMEOVER
	AudioManager.stop_engine()
	AudioManager.stop_music()
	AudioManager.play_sfx("gameover")
	_show_overlay("TIME OVER")

func _trigger_finish() -> void:
	_state = State.FINISH
	AudioManager.stop_engine()
	AudioManager.play_music("finish")
	_show_overlay("GOAL!")

func _show_overlay(msg: String) -> void:
	_overlay.visible = true
	var lbl := _overlay.get_node_or_null("OverlayLabel") as Label
	if lbl:
		lbl.text = msg
		lbl.add_theme_font_size_override("font_size", 72)
		lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.1))
