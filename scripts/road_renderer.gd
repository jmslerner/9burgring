class_name RoadRenderer
extends Node2D

# ── Screen / camera constants ─────────────────────────────────────────────────
const SW           := 1024.0  # screen width
const SH           :=  600.0  # screen height
const DRAW_DIST    :=  200    # segments drawn ahead of camera
const CAM_DEPTH    :=   0.84  # FOV control  (0.5=wide  1.0=narrow)
const CAM_HEIGHT   := 1500.0  # camera height above road surface
const ROAD_WIDTH   := 2000.0  # half-width of road in world units

# ── Palette ───────────────────────────────────────────────────────────────────
const C_SKY_TOP   := Color(0.25, 0.45, 0.80)
const C_SKY_BOT   := Color(0.55, 0.75, 0.95)
const C_MTN_DARK  := Color(0.30, 0.38, 0.30)
const C_MTN_LIGHT := Color(0.38, 0.48, 0.35)
const C_TREE_DARK := Color(0.10, 0.38, 0.10)
const C_TREE_LIT  := Color(0.14, 0.46, 0.14)
const C_GRASS_D   := Color(0.13, 0.46, 0.13)
const C_GRASS_L   := Color(0.16, 0.52, 0.16)
const C_ROAD_D    := Color(0.30, 0.30, 0.31)
const C_ROAD_L    := Color(0.37, 0.37, 0.38)
const C_RMB_RED   := Color(0.82, 0.10, 0.10)
const C_RMB_WHT   := Color(0.92, 0.92, 0.92)
const C_LANE      := Color(0.90, 0.90, 0.90)
const C_CHKPT     := Color(0.95, 0.85, 0.10)

# ── State (set by game.gd each frame) ────────────────────────────────────────
var track:      Track
var player_z:   float = 0.0   # distance travelled along track
var player_x:   float = 0.0   # lateral offset in -1..1 range

# ── Internal projected-segment cache ─────────────────────────────────────────
class _PSeg:
	var sx: float   # screen x of road centre
	var sy: float   # screen y (large = bottom of screen, small = horizon)
	var sw: float   # half-width of road on screen
	var seg         # Track.Segment

var _proj: Array = []  # Array of _PSeg

# ─────────────────────────────────────────────────────────────────────────────
func _process(_dt: float) -> void:
	queue_redraw()

func _draw() -> void:
	if track == null:
		return
	_draw_sky()
	_project_segments()
	_draw_road_strips()

# ── Sky + mountain silhouette ─────────────────────────────────────────────────
func _draw_sky() -> void:
	# Fill full screen so there are no gaps between sky and road
	draw_rect(Rect2(0, 0, SW, SH), C_SKY_BOT)
	draw_rect(Rect2(0, 0, SW, SH * 0.38), C_SKY_TOP)
	# Mountain silhouette bands just above the horizon
	draw_rect(Rect2(0, SH * 0.38, SW, SH * 0.08), C_MTN_DARK)
	draw_rect(Rect2(0, SH * 0.44, SW, SH * 0.06), C_MTN_LIGHT)

# ── Project all visible segments ──────────────────────────────────────────────
func _project_segments() -> void:
	_proj.clear()

	var seg_len := Track.SEGMENT_LENGTH
	var start   := int(player_z / seg_len) % track.segments.size()
	var cam_z   := fmod(player_z, seg_len)  # how far into the current segment

	# Accumulated curve/hill offsets applied while iterating
	var acc_x := 0.0
	var acc_y := 0.0

	for i in range(DRAW_DIST):
		var idx := (start + i) % track.segments.size()
		var seg := track.segments[idx]

		# Perspective depth of this segment's far edge from camera
		var z_dist := float(i) * seg_len - cam_z + seg_len
		var scale  := CAM_DEPTH * SH / z_dist

		# Accumulate curve / hill
		acc_x += seg.curve * seg_len
		acc_y += seg.hill  * seg_len

		# Project road centre to screen.
		# Near segments → large sy (bottom of screen)
		# Far segments  → small sy (near horizon at SH*0.5)
		var sx := SW * 0.5 + scale * (acc_x - player_x * ROAD_WIDTH)
		var sy := SH * 0.5 + scale * (CAM_HEIGHT - acc_y)
		var sw := scale * ROAD_WIDTH

		var p     := _PSeg.new()
		p.sx  = sx
		p.sy  = sy
		p.sw  = sw
		p.seg = seg
		_proj.append(p)

# ── Draw road from back to front ──────────────────────────────────────────────
func _draw_road_strips() -> void:
	# Draw back-to-front (far → near). Near strips naturally overwrite far ones.
	for i in range(_proj.size() - 1, 0, -1):
		var near = _proj[i - 1]   # closer to camera  → bottom of strip (large sy)
		var far  = _proj[i]       # farther from camera → top of strip  (small sy)

		# Clamp to screen; skip zero-height strips
		var y_bot := clampi(int(near.sy), 0, int(SH) - 1)
		var y_top := clampi(int(far.sy),  0, int(SH) - 1)
		if y_top >= y_bot:
			continue

		var even := near.seg.color_index == 0

		# ── Grass ─────────────────────────────────────────────────────────
		draw_rect(Rect2(0, y_top, SW, y_bot - y_top),
			C_GRASS_D if even else C_GRASS_L)

		# ── Rumble strips ──────────────────────────────────────────────────
		_quad(far.sx,  y_top, far.sw  * 1.18,
			  near.sx, y_bot, near.sw * 1.18,
			  C_RMB_RED if even else C_RMB_WHT)

		# ── Road surface ───────────────────────────────────────────────────
		_quad(far.sx,  y_top, far.sw,
			  near.sx, y_bot, near.sw,
			  C_ROAD_D if even else C_ROAD_L)

		# ── Checkpoint flash ───────────────────────────────────────────────
		if near.seg.is_checkpoint:
			_quad(far.sx,  y_top, far.sw  * 0.55,
				  near.sx, y_bot, near.sw * 0.55, C_CHKPT)

		# ── Centre lane marking ────────────────────────────────────────────
		if even:
			_quad(far.sx,  y_top, far.sw  * 0.015,
				  near.sx, y_bot, near.sw * 0.015, C_LANE)

# ── Helpers ───────────────────────────────────────────────────────────────────

# Draw a perspective trapezoid centred on x1/x2
func _quad(x1: float, y1: int, w1: float,
		   x2: float, y2: int, w2: float,
		   color: Color) -> void:
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(x1 - w1, float(y1)), Vector2(x1 + w1, float(y1)),
			Vector2(x2 + w2, float(y2)), Vector2(x2 - w2, float(y2)),
		]),
		PackedColorArray([color, color, color, color])
	)
