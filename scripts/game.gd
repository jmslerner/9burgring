## Game — root script for scenes/game.tscn.
## Wires together RoadRenderer, Player, HUD, and the timer/checkpoint system.
extends Node2D

# ── Timer settings ────────────────────────────────────────────────────────────
const INITIAL_TIME     := 60.0   # seconds at race start
const CHECKPOINT_BONUS := 120.0  # seconds added per checkpoint (8 CPs → ~16 min max)

# ── Deer obstacle settings ─────────────────────────────────────────────────────
const DEER_HIT_Z      := 280.0   # z-depth window for collision (world units)
const DEER_HIT_X      := 0.30    # lateral half-width for collision
const DEER_SPEED_MULT := 0.40    # speed multiplied by this on deer impact

# ── Pedal bar layout ─────────────────────────────────────────────────────────
const PEDAL_H  := 80.0   # bar height (px)
const PEDAL_W  := 22.0   # bar width  (px)
const PEDAL_BX := 876.0  # left-bar x position
const PEDAL_BY := 490.0  # bar top y position

# ── Stage names (one per checkpoint advance, plus start) ─────────────────────
const STAGE_NAMES = [
	"SANTA CRUZ",
	"SCOTTS VALLEY",
	"FELTON",
	"BEN LOMOND",
	"BOULDER CREEK",
	"THE CLIMB",
	"SARATOGA GAP",
	"LOS GATOS",
	"FINISH LINE",
]

# ── States ────────────────────────────────────────────────────────────────────
enum State { COUNTDOWN, RACING, GAMEOVER, FINISH }
var _state: State = State.COUNTDOWN

# ── Core objects ──────────────────────────────────────────────────────────────
var _track:    Track
var _renderer: RoadRenderer
var _player:   Player

# ── Timer ─────────────────────────────────────────────────────────────────────
var _time_left:       float = INITIAL_TIME
var _countdown:       float = 3.0
var _checkpoints_hit: int   = 0

# ── HUD nodes (built in _ready) ───────────────────────────────────────────────
var _hud:            CanvasLayer
var _lbl_timer:      Label
var _lbl_speed:      Label
var _lbl_checkpoint: Label
var _lbl_countdown:  Label
var _lbl_stage:      Label
var _lbl_deer_hit:   Label
var _overlay:        ColorRect
var _accel_bar:      ColorRect   # green GAS fill bar
var _brake_bar:      ColorRect   # red  BRK fill bar

# ── Deer state ────────────────────────────────────────────────────────────────
# Exactly one deer per run, placed at a random position on the track.
var _deer:       Array = []   # 0 or 1 entry: {z: float, x: float}
var _deer_hit_t: float = 0.0

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_build_scene()
	_build_hud()
	_state = State.COUNTDOWN
	# Start the race music
	var music := GameState.selected_music_file
	if music.is_empty():
		music = "res://audio/Theme Songs/ZISO - White Vacancy.mp3"
	AudioManager.play_music_file(music)

func _build_scene() -> void:
	_track = Track.new()

	# Place exactly one deer at a random point on the track
	var deer_z := randf_range(3000.0, _track.track_length - 1000.0)
	_deer.append({"z": deer_z, "x": randf_range(-0.68, 0.68)})

	_renderer = RoadRenderer.new()
	_renderer.track = _track
	add_child(_renderer)

	_player = Player.new()
	_player.track = _track
	if not GameState.selected_car.is_empty():
		_player.apply_car_stats(GameState.selected_car)
	add_child(_player)
	_player.checkpoint_passed.connect(_on_checkpoint_passed)
	_player.track_finished.connect(_trigger_finish)

	# Coloured rectangle car placeholder
	var car_rect      := ColorRect.new()
	car_rect.name     = "CarSprite"
	car_rect.size     = Vector2(40, 70)
	car_rect.position = Vector2(-20, -35)
	var car_color: Color = Color(0.80, 0.10, 0.10)
	if not GameState.selected_car.is_empty():
		car_color = GameState.selected_car.get("color", car_color)
	car_rect.color   = car_color
	_player.position = Vector2(512, 480)
	_player.add_child(car_rect)

# ── HUD ───────────────────────────────────────────────────────────────────────
func _build_hud() -> void:
	_hud = CanvasLayer.new()
	add_child(_hud)

	_lbl_timer      = _make_label("60", Vector2(460, 10), 32)
	_lbl_timer.add_theme_color_override("font_color", Color(1, 0.85, 0.1))

	_lbl_speed      = _make_label("0 MPH", Vector2(10, 10), 22)
	_lbl_checkpoint = _make_label("", Vector2(0, 50), 22)
	_lbl_checkpoint.size.x               = 1024.0
	_lbl_checkpoint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_lbl_countdown  = _make_label("", Vector2(430, 250), 64)
	_lbl_countdown.add_theme_color_override("font_color", Color.WHITE)

	_lbl_stage      = _make_label("STAGE 1  SANTA CRUZ", Vector2(10, 40), 16)
	_lbl_stage.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))

	# DEER! alert — centred on screen
	_lbl_deer_hit   = _make_label("", Vector2(0, 265), 50)
	_lbl_deer_hit.size.x               = 1024.0
	_lbl_deer_hit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_deer_hit.add_theme_color_override("font_color", Color(1.0, 0.55, 0.05))

	# ── Pedal bars ─────────────────────────────────────────────────────────
	var _make_pedal_bg := func(x: float) -> void:
		var bg := ColorRect.new()
		bg.size     = Vector2(PEDAL_W, PEDAL_H)
		bg.position = Vector2(x, PEDAL_BY)
		bg.color    = Color(0.08, 0.08, 0.08, 0.85)
		_hud.add_child(bg)

	_make_pedal_bg.call(PEDAL_BX)
	_make_pedal_bg.call(PEDAL_BX + PEDAL_W + 6.0)

	_accel_bar          = ColorRect.new()
	_accel_bar.size     = Vector2(PEDAL_W, 0.0)
	_accel_bar.position = Vector2(PEDAL_BX, PEDAL_BY + PEDAL_H)
	_accel_bar.color    = Color(0.10, 0.95, 0.20)
	_hud.add_child(_accel_bar)

	_brake_bar          = ColorRect.new()
	_brake_bar.size     = Vector2(PEDAL_W, 0.0)
	_brake_bar.position = Vector2(PEDAL_BX + PEDAL_W + 6.0, PEDAL_BY + PEDAL_H)
	_brake_bar.color    = Color(0.95, 0.12, 0.12)
	_hud.add_child(_brake_bar)

	_make_label("GAS", Vector2(PEDAL_BX,              PEDAL_BY + PEDAL_H + 2.0), 10)
	_make_label("BRK", Vector2(PEDAL_BX + PEDAL_W + 6.0, PEDAL_BY + PEDAL_H + 2.0), 10)

	# ── End-screen overlay ─────────────────────────────────────────────────
	_overlay       = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0.7)
	_overlay.size  = Vector2(1024, 600)
	_overlay.visible = false
	_hud.add_child(_overlay)

	var ol := Label.new()
	ol.name                = "OverlayLabel"
	ol.text                = ""
	ol.size                = Vector2(1024, 200)
	ol.position            = Vector2(0, 200)
	ol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ol.add_theme_font_size_override("font_size", 72)
	ol.add_theme_color_override("font_color", Color(1, 0.85, 0.1))
	_overlay.add_child(ol)

	var cont := Label.new()
	cont.text               = "Press ENTER to continue"
	cont.size               = Vector2(1024, 60)
	cont.position           = Vector2(0, 330)
	cont.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cont.add_theme_font_size_override("font_size", 22)
	_overlay.add_child(cont)

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
	_renderer.player_z = _player.position_z
	_renderer.player_x = _player.position_x

	_time_left -= dt
	if _time_left <= 0.0:
		_time_left = 0.0
		_trigger_gameover()
		return

	_tick_deer(dt)

	var accel := Input.is_action_pressed("accelerate")
	var brake := Input.is_action_pressed("brake")
	AudioManager.update_engine(_player.speed / _player.max_speed, accel, brake)

	# Pedal bars (fill from bottom: shrink position.y, grow size.y)
	var a_fill := PEDAL_H if accel else _player.speed / _player.max_speed * PEDAL_H * 0.35
	var b_fill := PEDAL_H if brake else 0.0
	_accel_bar.size.y     = a_fill
	_accel_bar.position.y = PEDAL_BY + PEDAL_H - a_fill
	_brake_bar.size.y     = b_fill
	_brake_bar.position.y = PEDAL_BY + PEDAL_H - b_fill

	# HUD text
	var secs   := int(ceil(_time_left))
	var tenths := int((_time_left - floorf(_time_left)) * 10.0)
	_lbl_timer.text = "%d.%d" % [secs, tenths]
	_lbl_timer.add_theme_color_override("font_color",
		Color(1, 0.1, 0.1) if _time_left < 10.0 else Color(1, 0.85, 0.1))
	_lbl_speed.text = "%d MPH" % _player.get_speed_mph()

func _do_end_screen() -> void:
	if Input.is_action_just_pressed("ui_accept"):
		AudioManager.stop_engine()
		AudioManager.stop_music()
		get_tree().change_scene_to_file("res://scenes/car_select.tscn")

# ── Deer obstacle system ──────────────────────────────────────────────────────

func _tick_deer(dt: float) -> void:
	var pz := _player.position_z

	# Collision check (iterate backwards to safely remove)
	var i := _deer.size() - 1
	while i >= 0:
		var d: Dictionary = _deer[i]
		var dz: float = d["z"]
		var dx: float = d["x"]
		var dz_diff := dz - pz
		if dz_diff < -400.0:
			_deer.remove_at(i)
		elif dz_diff >= 0.0 and dz_diff <= DEER_HIT_Z:
			if absf(_player.position_x - dx) < DEER_HIT_X:
				_player.speed    *= DEER_SPEED_MULT
				_deer_hit_t       = 1.6
				_lbl_deer_hit.text = "DEER!"
				_deer.remove_at(i)
				AudioManager.play_sfx("hit")
		i -= 1

	if _deer_hit_t > 0.0:
		_deer_hit_t -= dt
		if _deer_hit_t <= 0.0:
			_lbl_deer_hit.text = ""

	_renderer.deer_list.clear()
	for d: Dictionary in _deer:
		_renderer.deer_list.append({"z": d["z"], "x": d["x"]})

# ── Checkpoint ────────────────────────────────────────────────────────────────
func _on_checkpoint_passed(_idx: int) -> void:
	_checkpoints_hit += 1
	_time_left       += CHECKPOINT_BONUS
	AudioManager.play_sfx("checkpoint")

	# Speed boost reward
	_player.apply_speed_boost(7.0, 1.30)

	# Advance stage name label
	var si := mini(_checkpoints_hit, STAGE_NAMES.size() - 1)
	_lbl_stage.text = "STAGE %d  %s" % [si + 1, STAGE_NAMES[si]]

	_lbl_checkpoint.text = "CHECKPOINT!  +%ds  SPEED BOOST!" % int(CHECKPOINT_BONUS)
	await get_tree().create_timer(2.5).timeout
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
	AudioManager.stop_music()
	_show_overlay("GOAL!")

func _show_overlay(msg: String) -> void:
	_overlay.visible = true
	var lbl := _overlay.get_node_or_null("OverlayLabel") as Label
	if lbl:
		lbl.text = msg
