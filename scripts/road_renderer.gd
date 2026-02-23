class_name RoadRenderer
extends Node2D

# ── Screen / camera constants ─────────────────────────────────────────────────
const SW           := 1024.0  # screen width
const SH           :=  600.0  # screen height
const DRAW_DIST    :=  200    # segments drawn ahead of camera
const CAM_DEPTH    :=   0.84  # FOV control  (0.5=wide  1.0=narrow)
const CAM_HEIGHT   := 1500.0  # camera height above road surface
const ROAD_WIDTH   := 2000.0  # half-width of road in world units

# ── Road surface palette (shared across stages) ───────────────────────────────
const C_ROAD_D  := Color("#666666")
const C_ROAD_L  := Color("#707070")
const C_LANE    := Color("#FFFFFF")
const C_RMB_A   := Color("#FF2D95")   # neon pink rumble
const C_RMB_B   := Color("#FFFFFF")   # white rumble
const C_CHKPT   := Color(0.95, 0.85, 0.10)

# ── Per-stage sky colors [top, bottom] ────────────────────────────────────────
const SKY_TOP := [
	Color("#5BA3D9"),   # Stage 1 — coastal light blue
	Color("#4488CC"),   # Stage 2 — afternoon blue
	Color("#2A1A4A"),   # Stage 3 — dusk purple
	Color("#CC4400"),   # Stage 4 — sunset orange
]
const SKY_BOT := [
	Color("#D8EEF8"),   # Stage 1 — coastal haze white
	Color("#DDAA44"),   # Stage 2 — afternoon gold
	Color("#1A2A4A"),   # Stage 3 — dark blue dusk
	Color("#FF2D95"),   # Stage 4 — sunset pink
]

# ── Per-stage mountain silhouette colors ──────────────────────────────────────
const MTN_DARK := [
	Color("#2A4A2A"),   # Stage 1 — redwood dark
	Color("#304A2A"),   # Stage 2 — forest
	Color("#1A1A2A"),   # Stage 3 — dark ridge
	Color("#4A2A10"),   # Stage 4 — warm ridge
]
const MTN_LIGHT := [
	Color("#3A603A"),   # Stage 1
	Color("#3A5A30"),   # Stage 2
	Color("#28283A"),   # Stage 3
	Color("#5A3818"),   # Stage 4
]

# ── Per-stage grass colors [dark, light] ──────────────────────────────────────
const GRASS_D := [
	Color("#2D5A27"),   # Stage 1 — redwood forest
	Color("#2D5A27"),   # Stage 2 — redwood / river
	Color("#3A6B35"),   # Stage 3 — mountain green
	Color("#8B7D3C"),   # Stage 4 — vineyard gold
]
const GRASS_L := [
	Color("#234D1F"),   # Stage 1
	Color("#234D1F"),   # Stage 2
	Color("#2D5A27"),   # Stage 3
	Color("#7A6C2F"),   # Stage 4
]

# ── State (set by game.gd each frame) ────────────────────────────────────────
var track:      Track
var player_z:   float = 0.0   # distance travelled along track
var player_x:   float = 0.0   # lateral offset in -1..1 range

# Current stage derived from projected segments each frame
var _current_stage: int = 1

# ── Internal projected-segment cache ─────────────────────────────────────────
class _PSeg:
	var sx: float   # screen x of road centre
	var sy: float   # screen y (large = bottom of screen, small = horizon)
	var sw: float   # half-width of road on screen
	var seg: Track.Segment

var _proj: Array = []  # Array of _PSeg

# ─────────────────────────────────────────────────────────────────────────────
func _process(_dt: float) -> void:
	queue_redraw()

func _draw() -> void:
	if track == null:
		return
	_project_segments()   # sets _current_stage before sky draw
	_draw_sky()
	_draw_road_strips()

# ── Sky + mountain silhouette ─────────────────────────────────────────────────
func _draw_sky() -> void:
	var si := _current_stage - 1  # 0-based index into palette arrays
	# Fill full screen so there are no gaps between sky and road
	draw_rect(Rect2(0, 0, SW, SH), SKY_BOT[si])
	draw_rect(Rect2(0, 0, SW, SH * 0.38), SKY_TOP[si])
	# Mountain silhouette bands just above the horizon
	draw_rect(Rect2(0, SH * 0.38, SW, SH * 0.08), MTN_DARK[si])
	draw_rect(Rect2(0, SH * 0.44, SW, SH * 0.06), MTN_LIGHT[si])

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

	# Derive current stage from the nearest visible segment
	if not _proj.is_empty():
		_current_stage = _proj[0].seg.stage

# ── Draw road from back to front ──────────────────────────────────────────────
func _draw_road_strips() -> void:
	# Draw back-to-front (far → near). Near strips naturally overwrite far ones.
	for i in range(_proj.size() - 1, 0, -1):
		var near := _proj[i - 1]   # closer to camera  → bottom of strip (large sy)
		var far  := _proj[i]       # farther from camera → top of strip  (small sy)

		# Clamp to screen; skip zero-height strips
		var y_bot := clampi(int(near.sy), 0, int(SH) - 1)
		var y_top := clampi(int(far.sy),  0, int(SH) - 1)
		if y_top >= y_bot:
			continue

		var even := near.seg.color_index == 0
		var si   := near.seg.stage - 1   # 0-based stage index for palette

		# ── Grass ─────────────────────────────────────────────────────────
		draw_rect(Rect2(0, y_top, SW, y_bot - y_top),
			GRASS_D[si] if even else GRASS_L[si])

		# ── Rumble strips ──────────────────────────────────────────────────
		_quad(far.sx,  y_top, far.sw  * 1.18,
			  near.sx, y_bot, near.sw * 1.18,
			  C_RMB_A if even else C_RMB_B)

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
