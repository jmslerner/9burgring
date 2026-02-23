## Car selection screen — Outrun 1986 style.
extends Node2D

# ── Reference palette ─────────────────────────────────────────────────────────
const C_SKY_DEEP  := Color(0.102, 0.039, 0.180)   # #1a0a2e  deep space
const C_SKY_MID   := Color(0.239, 0.067, 0.333)   # #3d1155  mid purple
const C_HORIZON   := Color(1.000, 0.176, 0.584)   # #ff2d95  neon pink
const C_SUN_YEL   := Color(1.000, 0.894, 0.302)   # #ffe44d  bright yellow
const C_SUN_ORG   := Color(1.000, 0.420, 0.169)   # #ff6b2b  orange
const C_NEON_BLUE := Color(0.000, 0.831, 1.000)   # #00d4ff  cyan
const C_NEON_PINK := Color(1.000, 0.176, 0.584)   # #ff2d95
const C_NEON_YEL  := Color(1.000, 0.894, 0.302)   # #ffe44d
const C_CARD_BG   := Color(0.000, 0.000, 0.000, 0.72)

# ── Layout ────────────────────────────────────────────────────────────────────
const SW        := 1024.0
const SH        :=  600.0
const HORIZON_Y := SH * 0.60   # 360 px
const SUN_CX    := SW * 0.50
const SUN_CY    := SH * 0.20
const SUN_R     := 72.0

# Card grid  (4 columns × 2 rows)
const CARD_W     := 236.0
const CARD_H     := 148.0
const CARD_GAP_X := 10.0
const CARD_GAP_Y := 10.0
const GRID_LEFT  := 25.0
const GRID_TOP   := 34.0

# ── Stat-bar config ───────────────────────────────────────────────────────────
const STAT_LABELS = ["HP", "HAND", "ACCEL", "BRAKE", "SPEED"]
const STAT_KEYS   = ["hp", "handling", "accel", "braking", "top_speed"]
const STAT_MAXES  = [550,  5,          5,       5,         200        ]

# ── Car roster (all 8) ────────────────────────────────────────────────────────
const CARS = [
	{"driver":"Myles",   "car":"BMW Turbo",     "type":"4-Door",
	 "hp":400,"handling":3,"accel":4,"braking":3,"top_speed":150,
	 "body":Color("#e63946"),"accent":Color("#c1121f")},
	{"driver":"Jack",    "car":"Ford ST",        "type":"4-Door",
	 "hp":350,"handling":3,"accel":3,"braking":3,"top_speed":135,
	 "body":Color("#2196f3"),"accent":Color("#1565c0")},
	{"driver":"Cameron", "car":"BMW V8",         "type":"2-Door",
	 "hp":400,"handling":2,"accel":4,"braking":4,"top_speed":160,
	 "body":Color("#222222"),"accent":Color("#444444")},
	{"driver":"Ari",     "car":"Porsche GT3",    "type":"2-Door",
	 "hp":450,"handling":5,"accel":4,"braking":5,"top_speed":185,
	 "body":Color("#ffe44d"),"accent":Color("#f4a700")},
	{"driver":"Hrag",    "car":"Audi R8",        "type":"2-Door",
	 "hp":450,"handling":4,"accel":4,"braking":4,"top_speed":175,
	 "body":Color("#b537f2"),"accent":Color("#8a2be2")},
	{"driver":"Ethan",   "car":"Porsche Spyder", "type":"2-Door",
	 "hp":420,"handling":4,"accel":4,"braking":5,"top_speed":165,
	 "body":Color("#ff6b2b"),"accent":Color("#d4500a")},
	{"driver":"James",   "car":"Shelby GT350",   "type":"2-Door",
	 "hp":525,"handling":3,"accel":5,"braking":3,"top_speed":160,
	 "body":Color("#e0e0e0"),"accent":Color("#aaaaaa")},
	{"driver":"Henry",   "car":"Honda Civic",    "type":"4-Door",
	 "hp":250,"handling":4,"accel":2,"braking":3,"top_speed":135,
	 "body":Color("#4caf50"),"accent":Color("#2e7d32")},
]

# Soundtrack data
const TRACKS = [
	{"name":"WHITE VACANCY", "artist":"ZISO",
	 "file":"res://audio/ZISO_-_White_Vacancy.mp3"},
	{"name":"TURBO POWER",   "artist":"2050",
	 "file":"res://audio/2050_-_Turbo_Power.mp3"},
]

# ── Runtime state ─────────────────────────────────────────────────────────────
var _sun_pulse:   float = 0.0
var _car_index:   int   = 0
var _hover_index: int   = -1
var _blink_show:  bool  = true
var _blink_t:     float = 0.0
var _confirming:  bool  = false
var _track_index: int   = -1

var _card_alpha:   Array = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var _bar_t:        Array = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var _car_textures: Array = []

# Stat-bar gradient pairs (parallel to STAT_LABELS)
var _stat_c1: Array = [
	Color("#ff2d95"), Color("#00d4ff"),
	Color("#ffe44d"), Color("#b537f2"), Color("#00d4ff"),
]
var _stat_c2: Array = [
	Color("#ff6b2b"), Color("#b537f2"),
	Color("#ff6b2b"), Color("#ff2d95"), Color("#ffe44d"),
]

# ── Audio nodes ───────────────────────────────────────────────────────────────
var _announcer: AudioStreamPlayer
var _music:     AudioStreamPlayer

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_build_grid_floor()
	_build_scanline()
	_build_audio()
	_build_car_textures()
	_animate_cards_in()

func _process(dt: float) -> void:
	_sun_pulse = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.0012)
	_blink_t  += dt
	if _blink_t >= 0.5:
		_blink_t    = 0.0
		_blink_show = !_blink_show
	var mp := get_local_mouse_position()
	_hover_index = -1
	for i in range(CARS.size()):
		if _card_rect(i).has_point(mp):
			_hover_index = i
			break
	queue_redraw()

func _draw() -> void:
	_draw_sky()
	_draw_sun()
	_draw_mountains()
	_draw_title()
	_draw_cards()
	_draw_soundtrack_bar()
	_draw_hud_hint()

# ── Sky gradient ──────────────────────────────────────────────────────────────
func _draw_sky() -> void:
	_grad_rect(0.0, 0.0,              SW, HORIZON_Y * 0.58, C_SKY_DEEP, C_SKY_MID)
	_grad_rect(0.0, HORIZON_Y * 0.58, SW, HORIZON_Y,        C_SKY_MID,  C_HORIZON)

# ── Sun ───────────────────────────────────────────────────────────────────────
func _draw_sun() -> void:
	var cx := SUN_CX
	var cy := SUN_CY
	var r  := SUN_R + _sun_pulse * 4.0

	for ring in range(7, 0, -1):
		var gr := r + ring * 13.0
		var ga := maxf(0.0, 0.13 - ring * 0.016) * (0.65 + _sun_pulse * 0.35)
		draw_circle(Vector2(cx, cy), gr,
			Color(C_HORIZON.r, C_HORIZON.g, C_HORIZON.b, ga))

	var steps := 24
	for i in range(steps, 0, -1):
		var t  := float(i) / float(steps)
		var cr := r * t
		var c: Color
		if t > 0.65:
			c = C_SUN_ORG.lerp(C_HORIZON, (t - 0.65) / 0.35)
		elif t > 0.30:
			c = C_SUN_YEL.lerp(C_SUN_ORG, (t - 0.30) / 0.35)
		else:
			c = C_SUN_YEL
		draw_circle(Vector2(cx, cy), cr, c)

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
	_filled_poly(PackedVector2Array([
		Vector2(0,    HORIZON_Y - 10),
		Vector2(90,   HORIZON_Y - 78),  Vector2(200,  HORIZON_Y - 130),
		Vector2(310,  HORIZON_Y - 84),  Vector2(430,  HORIZON_Y - 112),
		Vector2(540,  HORIZON_Y - 58),  Vector2(660,  HORIZON_Y - 120),
		Vector2(780,  HORIZON_Y - 92),  Vector2(900,  HORIZON_Y - 125),
		Vector2(1024, HORIZON_Y - 72),
		Vector2(1024, SH + 5), Vector2(0, SH + 5),
	]), Color(0.098, 0.031, 0.165))

	_filled_poly(PackedVector2Array([
		Vector2(0,    HORIZON_Y +  2),
		Vector2(70,   HORIZON_Y - 46),  Vector2(175,  HORIZON_Y - 68),
		Vector2(285,  HORIZON_Y - 40),  Vector2(395,  HORIZON_Y - 58),
		Vector2(510,  HORIZON_Y - 26),  Vector2(620,  HORIZON_Y - 52),
		Vector2(740,  HORIZON_Y - 36),  Vector2(860,  HORIZON_Y - 64),
		Vector2(970,  HORIZON_Y - 44),  Vector2(1024, HORIZON_Y +  2),
		Vector2(1024, SH + 5), Vector2(0, SH + 5),
	]), Color(0.150, 0.049, 0.235))

# ── Title ─────────────────────────────────────────────────────────────────────
func _draw_title() -> void:
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(SW * 0.5 - 66.0, 23.0),
		"9BURGRING",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 20,
		Color(0.0, 0.0, 0.0, 0.55))
	draw_string(font, Vector2(SW * 0.5 - 68.0, 22.0),
		"9BURGRING",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 20, C_NEON_PINK)

# ── Card grid ─────────────────────────────────────────────────────────────────
func _card_rect(i: int) -> Rect2:
	var col: int = i % 4
	var row: int = i / 4
	return Rect2(
		GRID_LEFT + float(col) * (CARD_W + CARD_GAP_X),
		GRID_TOP  + float(row) * (CARD_H + CARD_GAP_Y),
		CARD_W, CARD_H
	)

func _draw_cards() -> void:
	for i in range(CARS.size()):
		_draw_card(i)

func _draw_card(i: int) -> void:
	var alpha: float = _card_alpha[i]
	if alpha < 0.01:
		return

	var car: Dictionary = CARS[i]
	var r: Rect2        = _card_rect(i)
	var font            := ThemeDB.fallback_font
	var body_c: Color   = car["body"]

	# Background
	draw_rect(r, Color(C_CARD_BG.r, C_CARD_BG.g, C_CARD_BG.b, C_CARD_BG.a * alpha))

	# Border — yellow if selected, pink if hovered, dim blue otherwise
	var border_c: Color
	if i == _car_index:
		border_c = Color(C_NEON_YEL.r, C_NEON_YEL.g, C_NEON_YEL.b, alpha)
	elif i == _hover_index:
		border_c = Color(C_NEON_PINK.r, C_NEON_PINK.g, C_NEON_PINK.b, alpha)
	else:
		border_c = Color(C_NEON_BLUE.r, C_NEON_BLUE.g, C_NEON_BLUE.b, alpha * 0.45)
	draw_rect(r, border_c, false, 2.0)

	# Door-type badge (top-left corner)
	var bx := r.position.x + 4.0
	var by := r.position.y + 4.0
	draw_rect(Rect2(bx, by, 44.0, 13.0),
		Color(body_c.r * 0.4, body_c.g * 0.4, body_c.b * 0.4, alpha * 0.85))
	draw_string(font, Vector2(bx + 2.0, by + 11.0),
		str(car["type"]),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 8,
		Color(1.0, 1.0, 1.0, alpha))

	# Driver name — neon yellow
	draw_string(font, Vector2(r.position.x + 6.0, r.position.y + 30.0),
		str(car["driver"]).to_upper(),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12,
		Color(C_NEON_YEL.r, C_NEON_YEL.g, C_NEON_YEL.b, alpha))

	# Car name — neon blue
	draw_string(font, Vector2(r.position.x + 6.0, r.position.y + 44.0),
		str(car["car"]),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 10,
		Color(C_NEON_BLUE.r, C_NEON_BLUE.g, C_NEON_BLUE.b, alpha * 0.85))

	# Pixel-art car sprite (scaled 3×)
	var tex := _car_textures[i] as ImageTexture
	if tex != null:
		var sw3 := float(tex.get_width())  * 3.0
		var sh3 := float(tex.get_height()) * 3.0
		var sx  := r.position.x + (CARD_W - sw3) * 0.5
		var sy  := r.position.y + 50.0
		draw_texture_rect(tex, Rect2(sx, sy, sw3, sh3),
			false, Color(1.0, 1.0, 1.0, alpha))

	# Stat bars
	_draw_stat_bars(i, r, alpha)

func _draw_stat_bars(i: int, r: Rect2, alpha: float) -> void:
	var car: Dictionary = CARS[i]
	var bt: float       = _bar_t[i]
	var font            := ThemeDB.fallback_font

	var lbl_w  := 36.0
	var bar_w  := CARD_W - lbl_w - 26.0   # ≈ 174 px
	var bar_h  := 6.0
	var row_h  := 9.0
	var bar_x  := r.position.x + 6.0
	var bar_y0 := r.position.y + 102.0

	for s in range(5):
		var label: String = str(STAT_LABELS[s])
		var key:   String = str(STAT_KEYS[s])
		var max_v: int    = int(STAT_MAXES[s])
		var val_i: int    = int(car[key])
		var fill:  float  = clampf(float(val_i) / float(max_v), 0.0, 1.0) * bt
		var y             := bar_y0 + float(s) * row_h

		# Label
		draw_string(font, Vector2(bar_x, y + bar_h),
			label, HORIZONTAL_ALIGNMENT_LEFT, -1, 7,
			Color(0.75, 0.75, 0.85, alpha * 0.75))

		var bx := bar_x + lbl_w

		# Dark trough
		draw_rect(Rect2(bx, y, bar_w, bar_h),
			Color(0.0, 0.0, 0.0, alpha * 0.55))

		# Gradient fill
		if fill > 0.001:
			var fw  := bar_w * fill
			var c1: Color = _stat_c1[s]
			var c2: Color = _stat_c2[s]
			c1.a = alpha
			c2.a = alpha
			draw_colored_polygon(
				PackedVector2Array([
					Vector2(bx,      y),
					Vector2(bx + fw, y),
					Vector2(bx + fw, y + bar_h),
					Vector2(bx,      y + bar_h),
				]),
				PackedColorArray([c1, c2, c2, c1])
			)
			# Segmented notches every 6 px
			var nx := bx + 6.0
			while nx < bx + fw - 1.0:
				draw_line(Vector2(nx, y), Vector2(nx, y + bar_h),
					Color(0.0, 0.0, 0.0, alpha * 0.30))
				nx += 6.0

		# Numeric value to the right of bar
		draw_string(font, Vector2(bx + bar_w + 3.0, y + bar_h),
			str(val_i),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 7,
			Color(1.0, 1.0, 1.0, alpha * 0.7))

# ── Soundtrack bar ────────────────────────────────────────────────────────────
func _soundtrack_y() -> float:
	return GRID_TOP + (CARD_H + CARD_GAP_Y) * 2.0 + 4.0   # ≈ 354 px

func _soundtrack_rect(t: int) -> Rect2:
	return Rect2(GRID_LEFT + 106.0 + float(t) * 260.0, _soundtrack_y(), 248.0, 20.0)

func _draw_soundtrack_bar() -> void:
	var font := ThemeDB.fallback_font
	var y    := _soundtrack_y()
	draw_string(font, Vector2(GRID_LEFT, y + 14.0),
		"SOUNDTRACK:", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, C_NEON_BLUE)
	for t in range(TRACKS.size()):
		var track: Dictionary = TRACKS[t]
		var tr := _soundtrack_rect(t)
		draw_rect(tr, Color(0.0, 0.0, 0.0, 0.55))
		var bc: Color
		if t == _track_index:
			bc = C_NEON_YEL
		else:
			bc = Color(C_NEON_BLUE.r, C_NEON_BLUE.g, C_NEON_BLUE.b, 0.5)
		draw_rect(tr, bc, false, 1.5)
		var label: String = str(track["artist"]) + " — " + str(track["name"])
		draw_string(font, Vector2(tr.position.x + 5.0, tr.position.y + 14.0),
			label, HORIZONTAL_ALIGNMENT_LEFT, -1, 9,
			Color(1.0, 1.0, 1.0, 0.9))

# ── HUD hint (blinking) ───────────────────────────────────────────────────────
func _draw_hud_hint() -> void:
	if not _blink_show:
		return
	var font := ThemeDB.fallback_font
	draw_string(font,
		Vector2(SW * 0.5 - 186.0, HORIZON_Y + 34.0),
		"← / →  SELECT     ENTER = RACE     CLICK CARD",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, C_NEON_BLUE)

# ── Child-node builders ───────────────────────────────────────────────────────
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
	var sfx = _try_load("res://audio/Choose_your_driver.mp3")
	if sfx != null:
		_announcer.stream = sfx
		_announcer.play()

# ── Pixel-art car texture ─────────────────────────────────────────────────────
func _build_car_textures() -> void:
	for i in range(CARS.size()):
		var car: Dictionary = CARS[i]
		var body: Color     = car["body"]
		var accent: Color   = car["accent"]
		var is4d: bool      = str(car["type"]) == "4-Door"
		_car_textures.append(_make_car_texture(is4d, body, accent))

# Draws a 60×16 pixel car. Displayed at 3× scale (180×48 px) in each card.
func _make_car_texture(is4d: bool, body: Color, accent: Color) -> ImageTexture:
	var img   := Image.create(60, 16, false, Image.FORMAT_RGBA8)
	var win   := Color("#00d4ff")
	var trim  := Color("#333333")
	var wheel := Color("#1a1a2e")
	var hl    := Color("#ffe44d")

	# Roof (rows 0-1)
	for x in range(18, 42):
		img.set_pixel(x, 0, accent)
		img.set_pixel(x, 1, accent)

	# Cabin shell (rows 2-4)
	for y in range(2, 5):
		for x in range(8, 52):
			img.set_pixel(x, y, body)

	# Windows
	for y in range(2, 5):
		for x in range(11, 22):
			img.set_pixel(x, y, win)    # left
		for x in range(25, 36):
			img.set_pixel(x, y, win)    # right
		if is4d:
			for x in range(39, 50):
				img.set_pixel(x, y, win)   # rear (4-door)

	# Pillars (trim colour)
	for y in range(2, 5):
		for dx in [8, 9, 22, 23, 24, 50, 51]:
			img.set_pixel(dx, y, trim)
		if is4d:
			img.set_pixel(37, y, trim)
			img.set_pixel(38, y, trim)

	# Body main (rows 5-9)
	for y in range(5, 10):
		for x in range(4, 56):
			img.set_pixel(x, y, body)

	# Side vents (2-door) or door split (4-door)
	if not is4d:
		for y in range(6, 9):
			for x in range(4, 8):
				img.set_pixel(x, y, accent)
			for x in range(52, 56):
				img.set_pixel(x, y, accent)
	else:
		var door_c := Color(accent.r * 0.7, accent.g * 0.7, accent.b * 0.7)
		for y in range(5, 10):
			img.set_pixel(30, y, door_c)

	# Headlights (rows 5-7, both ends)
	for y in range(5, 8):
		for x in range(0, 4):
			img.set_pixel(x, y, hl)
		for x in range(56, 60):
			img.set_pixel(x, y, hl)

	# Bumper (row 10)
	for x in range(2, 58):
		img.set_pixel(x, 10, trim)

	# Wheels (rows 11-14)
	for y in range(11, 15):
		for x in range(2, 13):
			img.set_pixel(x, y, wheel)
		for x in range(47, 58):
			img.set_pixel(x, y, wheel)
		for x in range(13, 47):
			img.set_pixel(x, y, body)
	var shine := Color(0.25, 0.25, 0.40)
	for x in range(4, 11):
		img.set_pixel(x, 11, shine)
	for x in range(49, 56):
		img.set_pixel(x, 11, shine)

	# Ground shadow (row 15)
	for x in range(5, 55):
		img.set_pixel(x, 15, Color(0.0, 0.0, 0.0, 0.35))

	return ImageTexture.create_from_image(img)

# ── Card stagger-in animations ────────────────────────────────────────────────
func _animate_cards_in() -> void:
	for i in range(CARS.size()):
		var delay := float(i) * 0.08

		var tw := create_tween()
		tw.tween_interval(delay)
		tw.tween_method(_set_card_alpha.bind(i), 0.0, 1.0, 0.35).set_ease(Tween.EASE_OUT)

		var bw := create_tween()
		bw.tween_interval(delay + 0.25)
		bw.tween_method(_set_bar_t.bind(i), 0.0, 1.0, 0.80).set_ease(Tween.EASE_OUT)

func _set_card_alpha(i: int, v: float) -> void:
	_card_alpha[i] = v

func _set_bar_t(i: int, v: float) -> void:
	_bar_t[i] = v

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
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_handle_click()

func _handle_click() -> void:
	var pos := get_local_mouse_position()
	for i in range(CARS.size()):
		if _card_rect(i).has_point(pos):
			if i == _car_index:
				_confirm_car()
			else:
				_car_index = i
			return
	for t in range(TRACKS.size()):
		if _soundtrack_rect(t).has_point(pos):
			_select_track(t)
			return

func _select_track(t: int) -> void:
	_track_index = t
	var track: Dictionary = TRACKS[t]
	var sfx = _try_load(str(track["file"]))
	if sfx != null:
		_music.stream = sfx
		_music.play()

func _confirm_car() -> void:
	_confirming = true
	GameState.selected_car = CARS[_car_index]

	var sfx = _try_load("res://audio/Good_choice.mp3")
	if sfx != null:
		_music.stop()
		_announcer.stream = sfx
		_announcer.play()
		await _announcer.finished

	get_tree().change_scene_to_file("res://scenes/game.tscn")

# ── Helpers ───────────────────────────────────────────────────────────────────

# Horizontal gradient quad (top_c → bot_c)
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
