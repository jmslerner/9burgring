## CarSelect — builds the car-selection UI entirely in code.
## Attach to the root node of scenes/car_select.tscn.
extends Node2D

# ── Car roster ────────────────────────────────────────────────────────────────
const CARS := [
	{
		"id":          "gt_red",
		"name":        "Crimson GT",
		"description": "A classic Italian sports car. Balanced and forgiving.",
		"max_speed":    280.0,
		"acceleration": 110.0,
		"deceleration": 180.0,
		"brake_force":  360.0,
		"handling":     2.2,
		# stat bars 0–10 for display
		"stat_speed":    7,
		"stat_accel":    6,
		"stat_handling": 7,
		"color": Color(0.80, 0.10, 0.10),
	},
	{
		"id":          "turbo_silver",
		"name":        "Silver Turbo",
		"description": "Maximum top speed. Needs a steady hand on hairpins.",
		"max_speed":    340.0,
		"acceleration":  95.0,
		"deceleration": 160.0,
		"brake_force":  300.0,
		"handling":     1.6,
		"stat_speed":    10,
		"stat_accel":     5,
		"stat_handling":  4,
		"color": Color(0.75, 0.78, 0.80),
	},
	{
		"id":          "grip_yellow",
		"name":        "Apex Yellow",
		"description": "Track-tuned suspension. Carves corners effortlessly.",
		"max_speed":    260.0,
		"acceleration": 130.0,
		"deceleration": 200.0,
		"brake_force":  420.0,
		"handling":     3.0,
		"stat_speed":    6,
		"stat_accel":    8,
		"stat_handling": 10,
		"color": Color(0.95, 0.85, 0.10),
	},
	{
		"id":          "rally_blue",
		"name":        "Touge Blue",
		"description": "Born on mountain passes. Thrives on gravel and asphalt.",
		"max_speed":    270.0,
		"acceleration": 140.0,
		"deceleration": 220.0,
		"brake_force":  390.0,
		"handling":     2.6,
		"stat_speed":    6,
		"stat_accel":    9,
		"stat_handling": 8,
		"color": Color(0.15, 0.35, 0.80),
	},
]

# ── State ─────────────────────────────────────────────────────────────────────
var _index: int = 0

# ── UI nodes (created in _ready) ──────────────────────────────────────────────
var _title_label:  Label
var _car_preview:  ColorRect
var _name_label:   Label
var _desc_label:   Label
var _bar_speed:    ProgressBar
var _bar_accel:    ProgressBar
var _bar_handling: ProgressBar
var _hint_label:   Label

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_build_ui()
	_refresh()
	AudioManager.play_music("select")

func _build_ui() -> void:
	# Dark background
	var bg := ColorRect.new()
	bg.color     = Color(0.06, 0.06, 0.10)
	bg.size      = Vector2(1024, 600)
	add_child(bg)

	# Title
	_title_label        = Label.new()
	_title_label.text   = "9BURGRING — SELECT YOUR CAR"
	_title_label.add_theme_font_size_override("font_size", 28)
	_title_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.10))
	_title_label.position = Vector2(50, 30)
	add_child(_title_label)

	# Car colour preview box (placeholder until sprites are added)
	_car_preview        = ColorRect.new()
	_car_preview.size   = Vector2(240, 140)
	_car_preview.position = Vector2(50, 100)
	add_child(_car_preview)

	# Car name
	_name_label       = Label.new()
	_name_label.add_theme_font_size_override("font_size", 22)
	_name_label.add_theme_color_override("font_color", Color.WHITE)
	_name_label.position = Vector2(320, 110)
	add_child(_name_label)

	# Description
	_desc_label           = Label.new()
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_desc_label.custom_minimum_size = Vector2(380, 0)
	_desc_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	_desc_label.position = Vector2(320, 145)
	add_child(_desc_label)

	# Stat bars
	var bar_y := 210
	_bar_speed    = _make_bar("SPEED",    bar_y);      bar_y += 45
	_bar_accel    = _make_bar("ACCEL",    bar_y);      bar_y += 45
	_bar_handling = _make_bar("HANDLING", bar_y)

	# Navigation hint
	_hint_label       = Label.new()
	_hint_label.text  = "← → to browse     ENTER to race"
	_hint_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	_hint_label.position = Vector2(50, 520)
	add_child(_hint_label)

func _make_bar(label_text: String, y: int) -> ProgressBar:
	var lbl        := Label.new()
	lbl.text       = label_text
	lbl.position   = Vector2(320, y)
	lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	add_child(lbl)

	var bar             := ProgressBar.new()
	bar.min_value       = 0
	bar.max_value       = 10
	bar.size            = Vector2(280, 22)
	bar.position        = Vector2(420, y + 2)
	bar.show_percentage = false
	add_child(bar)
	return bar

# ── Input ─────────────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left"):
		_index = (_index - 1 + CARS.size()) % CARS.size()
		_refresh()
		AudioManager.play_sfx("select_move")
	elif event.is_action_pressed("ui_right"):
		_index = (_index + 1) % CARS.size()
		_refresh()
		AudioManager.play_sfx("select_move")
	elif event.is_action_pressed("ui_accept"):
		_start_game()

func _refresh() -> void:
	var car: Dictionary = CARS[_index]
	_car_preview.color     = car["color"]
	_name_label.text       = car["name"]
	_desc_label.text       = car["description"]
	_bar_speed.value       = car["stat_speed"]
	_bar_accel.value       = car["stat_accel"]
	_bar_handling.value    = car["stat_handling"]

func _start_game() -> void:
	# Store selection globally so game.gd can read it
	GameState.selected_car = CARS[_index]
	AudioManager.stop_music()
	AudioManager.play_sfx("select_confirm")
	get_tree().change_scene_to_file("res://scenes/game.tscn")
