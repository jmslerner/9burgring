## Car selection screen — Outrun 1986 style.
## Background only for now; car cards added in a later pass.
extends Node2D

# ── Reference palette ─────────────────────────────────────────────────────────
const C_SKY_DEEP  := Color(0.102, 0.039, 0.180)   # #1a0a2e  deep space
const C_SKY_MID   := Color(0.239, 0.067, 0.333)   # #3d1155  mid purple
const C_HORIZON   := Color(1.000, 0.176, 0.584)   # #ff2d95  neon pink
const C_SUN_YEL   := Color(1.000, 0.894, 0.302)   # #ffe44d  bright yellow
const C_SUN_ORG   := Color(1.000, 0.420, 0.169)   # #ff6b2b  orange
const C_NEON_BLUE := Color(0.000, 0.831, 1.000)   # #00d4ff  cyan

# ── Layout ────────────────────────────────────────────────────────────────────
const SW         := 1024.0
const SH         :=  600.0
const HORIZON_Y  := SH * 0.60   # y where grid floor begins (360 px)
const SUN_CX     := SW * 0.50
const SUN_CY     := SH * 0.20   # 20 % from top
const SUN_R      := 72.0

# ── Car roster (all 8, used by game logic) ────────────────────────────────────
const CARS := [
	{"driver":"Myles",  "car":"BMW Turbo",      "type":"4-Door",
	 "hp":400,"handling":3,"accel":4,"braking":3,"top_speed":150,
	 "body":Color("#e63946"),"accent":Color("#c1121f")},
	{"driver":"Jack",   "car":"Ford ST",         "type":"4-Door",
	 "hp":350,"handling":3,"accel":3,"braking":3,"top_speed":135,
	 "body":Color("#2196f3"),"accent":Color("#1565c0")},
	{"driver":"Cameron","car":"BMW V8",          "type":"2-Door",
	 "hp":400,"handling":2,"accel":4,"braking":4,"top_speed":160,
	 "body":Color("#222222"),"accent":Color("#111111")},
	{"driver":"Ari",    "car":"Porsche GT3",     "type":"2-Door",
	 "hp":450,"handling":5,"accel":4,"braking":5,"top_speed":185,
	 "body":Color("#ffe44d"),"accent":Color("#f4a700")},
	{"driver":"Hrag",   "car":"Audi R8",         "type":"2-Door",
	 "hp":450,"handling":4,"accel":4,"braking":4,"top_speed":175,
	 "body":Color("#b537f2"),"accent":Color("#8a2be2")},
	{"driver":"Ethan",  "car":"Porsche Spyder",  "type":"2-Door",
	 "hp":420,"handling":4,"accel":4,"braking":5,"top_speed":165,
	 "body":Color("#ff6b2b"),"accent":Color("#d4500a")},
	{"driver":"James",  "car":"Shelby GT350",    "type":"2-Door",
	 "hp":525,"handling":3,"accel":5,"braking":3,"top_speed":160,
	 "body":Color("#e0e0e0"),"accent":Color("#aaaaaa")},
	{"driver":"Henry",  "car":"Honda Civic",     "type":"4-Door",
	 "hp":250,"handling":4,"accel":2,"braking":3,"top_speed":135,
	 "body":Color("#4caf50"),"accent":Color("#2e7d32")},
]

# ── Runtime state ─────────────────────────────────────────────────────────────
var _sun_pulse:  float = 0.0
var _car_index:  int   = 0
var _blink_show: bool  = true
var _blink_t:    float = 0.0
var _confirming: bool  = false

# ── Audio nodes ───────────────────────────────────────────────────────────────
var _announcer: AudioStreamPlayer
var _music:     AudioStreamPlayer

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_build_grid_floor()
	_build_scanline()
	_build_audio()

func _process(dt: float) -> void:
	_sun_pulse = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.0012)
	_blink_t  += dt
	if _blink_t >= 0.5:
		_blink_t   = 0.0
		_blink_show = !_blink_show
	queue_redraw()

func _draw() -> void:
	_draw_sky()
	_draw_sun()
	_draw_mountains()
	_draw_hud_hint()

# ── Sky gradient ──────────────────────────────────────────────────────────────
func _draw_sky() -> void:
	# Upper band: deep space → mid purple
	_grad_rect(0.0, 0.0, SW, HORIZON_Y * 0.58, C_SKY_DEEP, C_SKY_MID)
	# Lower band: mid purple → neon-pink horizon
	_grad_rect(0.0, HORIZON_Y * 0.58, SW, HORIZON_Y, C_SKY_MID, C_HORIZON)

# ── Sun (concentric circles + scan lines + pulsing glow) ─────────────────────
func _draw_sun() -> void:
	var cx := SUN_CX
	var cy := SUN_CY
	var r  := SUN_R + _sun_pulse * 4.0

	# Glow rings: faint neon-pink halos around the sun
	for ring in range(7, 0, -1):
		var gr := r + ring * 13.0
		var ga := maxf(0.0, 0.13 - ring * 0.016) * (0.65 + _sun_pulse * 0.35)
		draw_circle(Vector2(cx, cy), gr,
			Color(C_HORIZON.r, C_HORIZON.g, C_HORIZON.b, ga))

	# Sun body: draw from outermost (rim) inward so later circles overwrite earlier
	# t=1.0 → rim, t→0 → bright centre
	var steps := 24
	for i in range(steps, 0, -1):
		var t  := float(i) / float(steps)
		var cr := r * t
		var c: Color
		if t > 0.65:
			c = C_SUN_ORG.lerp(C_HORIZON, (t - 0.65) / 0.35)  # orange → pink rim
		elif t > 0.30:
			c = C_SUN_YEL.lerp(C_SUN_ORG, (t - 0.30) / 0.35)  # yellow → orange
		else:
			c = C_SUN_YEL                                        # bright yellow core
		draw_circle(Vector2(cx, cy), cr, c)

	# Horizontal scan lines drawn across the face of the sun
	var scan_y := cy - r
	while scan_y <= cy + r:
		var half_w := sqrt(maxf(0.0, r * r - (scan_y - cy) * (scan_y - cy)))
		if half_w > 0.5:
			draw_line(Vector2(cx - half_w, scan_y),
					  Vector2(cx + half_w, scan_y),
					  Color(0.0, 0.0, 0.0, 0.20))
		scan_y += 5.0

# ── Mountain silhouettes ──────────────────────────────────────────────────────
func _draw_mountains() -> void:
	# Back range — darker, taller peaks
	_filled_poly(PackedVector2Array([
		Vector2(0,    HORIZON_Y - 10),
		Vector2(90,   HORIZON_Y - 78),  Vector2(200,  HORIZON_Y - 130),
		Vector2(310,  HORIZON_Y - 84),  Vector2(430,  HORIZON_Y - 112),
		Vector2(540,  HORIZON_Y - 58),  Vector2(660,  HORIZON_Y - 120),
		Vector2(780,  HORIZON_Y - 92),  Vector2(900,  HORIZON_Y - 125),
		Vector2(1024, HORIZON_Y - 72),
		Vector2(1024, SH + 5), Vector2(0, SH + 5),
	]), Color(0.098, 0.031, 0.165))

	# Front range — lighter purple, shorter, closer to horizon
	_filled_poly(PackedVector2Array([
		Vector2(0,    HORIZON_Y +  2),
		Vector2(70,   HORIZON_Y - 46),  Vector2(175,  HORIZON_Y - 68),
		Vector2(285,  HORIZON_Y - 40),  Vector2(395,  HORIZON_Y - 58),
		Vector2(510,  HORIZON_Y - 26),  Vector2(620,  HORIZON_Y - 52),
		Vector2(740,  HORIZON_Y - 36),  Vector2(860,  HORIZON_Y - 64),
		Vector2(970,  HORIZON_Y - 44),  Vector2(1024, HORIZON_Y +  2),
		Vector2(1024, SH + 5), Vector2(0, SH + 5),
	]), Color(0.150, 0.049, 0.235))

# ── Temporary placeholder HUD ────────────────────────────────────────────────
func _draw_hud_hint() -> void:
	if not _blink_show:
		return
	var font := ThemeDB.fallback_font
	draw_string(font,
		Vector2(SW * 0.5 - 220, HORIZON_Y + 36),
		"<  SELECT CAR  >     ENTER = RACE",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 16, C_NEON_BLUE)

# ── Child nodes (built once in _ready) ───────────────────────────────────────
func _build_grid_floor() -> void:
	var rect      := ColorRect.new()
	rect.size      = Vector2(SW, SH - HORIZON_Y + 2.0)
	rect.position  = Vector2(0.0, HORIZON_Y - 2.0)
	var mat        := ShaderMaterial.new()
	mat.shader     = load("res://shaders/grid_floor.gdshader")
	rect.material  = mat
	add_child(rect)

func _build_scanline() -> void:
	var rect      := ColorRect.new()
	rect.size      = Vector2(SW, SH)
	rect.z_index   = 200
	var mat        := ShaderMaterial.new()
	mat.shader     = load("res://shaders/scanline.gdshader")
	rect.material  = mat
	add_child(rect)

func _build_audio() -> void:
	_announcer = AudioStreamPlayer.new()
	add_child(_announcer)
	_music = AudioStreamPlayer.new()
	add_child(_music)

	# "Choose your driver!" on screen load
	var sfx = _try_load("res://audio/Choose_your_driver.mp3")
	if sfx != null:
		_announcer.stream = sfx
		_announcer.play()

# ── Input ─────────────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if _confirming:
		return
	if event.is_action_pressed("ui_left"):
		_car_index = (_car_index - 1 + CARS.size()) % CARS.size()
	elif event.is_action_pressed("ui_right"):
		_car_index = (_car_index + 1) % CARS.size()
	elif event.is_action_pressed("ui_accept"):
		_confirm_car()

func _confirm_car() -> void:
	_confirming = true
	GameState.selected_car = CARS[_car_index] as Dictionary

	var sfx = _try_load("res://audio/Good_choice.mp3")
	if sfx != null:
		_announcer.stream = sfx
		_announcer.play()
		await _announcer.finished

	get_tree().change_scene_to_file("res://scenes/game.tscn")

# ── Helpers ───────────────────────────────────────────────────────────────────

# Horizontal gradient quad from top_c to bot_c
func _grad_rect(x: float, y_top: float, w: float, y_bot: float,
				top_c: Color, bot_c: Color) -> void:
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(x,     y_top), Vector2(x + w, y_top),
			Vector2(x + w, y_bot), Vector2(x,     y_bot),
		]),
		PackedColorArray([top_c, top_c, bot_c, bot_c])
	)

# Solid-colour filled polygon
func _filled_poly(pts: PackedVector2Array, color: Color) -> void:
	var colors := PackedColorArray()
	colors.resize(pts.size())
	colors.fill(color)
	draw_colored_polygon(pts, colors)

# Safe resource loader — returns null if path doesn't exist
func _try_load(path: String):
	if ResourceLoader.exists(path):
		return load(path)
	return null
