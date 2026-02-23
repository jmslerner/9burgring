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
var C_ROAD_D  = Color("#666666")
var C_ROAD_L  = Color("#707070")
var C_LANE    = Color("#FFFFFF")
var C_RMB_A   = Color("#FF2D95")   # neon pink rumble
var C_RMB_B   = Color("#FFFFFF")   # white rumble
var C_CHKPT   = Color(0.95, 0.85, 0.10)

# ── Per-stage sky colors [top, bottom] ────────────────────────────────────────
var SKY_TOP: Array[Color] = [
	Color("#5BA3D9"),   # Stage 1 — coastal light blue
	Color("#4488CC"),   # Stage 2 — afternoon blue
	Color("#2A1A4A"),   # Stage 3 — dusk purple
	Color("#CC4400"),   # Stage 4 — sunset orange
]
var SKY_BOT: Array[Color] = [
	Color("#D8EEF8"),   # Stage 1 — coastal haze white
	Color("#DDAA44"),   # Stage 2 — afternoon gold
	Color("#1A2A4A"),   # Stage 3 — dark blue dusk
	Color("#FF2D95"),   # Stage 4 — sunset pink
]

# ── Per-stage mountain silhouette colors ──────────────────────────────────────
var MTN_DARK: Array[Color] = [
	Color("#2A4A2A"),   # Stage 1 — redwood dark
	Color("#304A2A"),   # Stage 2 — forest
	Color("#1A1A2A"),   # Stage 3 — dark ridge
	Color("#4A2A10"),   # Stage 4 — warm ridge
]
var MTN_LIGHT: Array[Color] = [
	Color("#3A603A"),   # Stage 1
	Color("#3A5A30"),   # Stage 2
	Color("#28283A"),   # Stage 3
	Color("#5A3818"),   # Stage 4
]

# ── Per-stage grass colors [dark, light] ──────────────────────────────────────
var GRASS_D: Array[Color] = [
	Color("#2D5A27"),   # Stage 1 — redwood forest
	Color("#2D5A27"),   # Stage 2 — redwood / river
	Color("#3A6B35"),   # Stage 3 — mountain green
	Color("#8B7D3C"),   # Stage 4 — vineyard gold
]
var GRASS_L: Array[Color] = [
	Color("#234D1F"),   # Stage 1
	Color("#234D1F"),   # Stage 2
	Color("#2D5A27"),   # Stage 3
	Color("#7A6C2F"),   # Stage 4
]

# ── State (set by game.gd each frame) ────────────────────────────────────────
var track:         Track
var player_z:      float = 0.0   # distance travelled along track
var player_x:      float = 0.0   # lateral offset in -1..1 range
var cam_y_offset:  float = 0.0   # vertical camera bob in screen pixels (set by game.gd)

# ── Deer obstacle positions (set by game.gd each frame) ───────────────────────
# Each entry: {z: float, x: float}
var deer_list: Array = []

# Current stage derived from projected segments each frame
var _current_stage: int = 1

# ── Internal projected-segment cache ─────────────────────────────────────────
class _PSeg:
	var sx:            float
	var sy:            float
	var sw:            float
	var color_index:   int
	var is_checkpoint: bool
	var stage:         int
	var scenery_l:     int
	var scenery_r:     int

var _proj: Array[_PSeg] = []

# ─────────────────────────────────────────────────────────────────────────────
func _process(_dt: float) -> void:
	queue_redraw()

func _draw() -> void:
	if track == null:
		return
	_project_segments()   # sets _current_stage before sky draw
	_draw_sky()
	_draw_road_strips()
	_draw_deer_obstacles()

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

	# Accumulated curve/hill offsets applied while iterating.
	# Curves use DOUBLE integration (velocity → position) so that scale * acc_x
	# grows linearly with distance and the road visibly bends.
	# Hills use single integration (world-height offset scaled by perspective).
	var acc_curve := 0.0   # lateral "velocity" — integral of curvature
	var acc_x     := 0.0   # lateral "position" — integral of acc_curve
	var acc_y     := 0.0   # vertical offset (world units)

	for i in range(DRAW_DIST):
		var idx := (start + i) % track.segments.size()
		var seg := track.segments[idx]

		# Perspective depth of this segment's far edge from camera
		var z_dist := float(i) * seg_len - cam_z + seg_len
		var scale  := CAM_DEPTH * SH / z_dist

		# Double-integrate curve: curvature → lateral velocity → lateral position.
		# This gives acc_x ∝ i², so scale * acc_x ∝ i → visible bend in distance.
		acc_curve += seg.curve * seg_len
		acc_x     += acc_curve
		acc_y     += seg.hill  * seg_len

		# Project road centre to screen.
		# Near segments → large sy (bottom of screen)
		# Far segments  → small sy (near horizon at SH*0.5)
		var sx := SW * 0.5 + scale * (acc_x - player_x * ROAD_WIDTH)
		var sy := SH * 0.5 + scale * (CAM_HEIGHT - acc_y)
		var sw := scale * ROAD_WIDTH

		var p             := _PSeg.new()
		p.sx            = sx
		p.sy            = sy
		p.sw            = sw
		p.color_index   = seg.color_index
		p.is_checkpoint = seg.is_checkpoint
		p.stage         = seg.stage
		p.scenery_l     = seg.scenery_l
		p.scenery_r     = seg.scenery_r
		_proj.append(p)

	# Derive current stage from the nearest visible segment
	if not _proj.is_empty():
		_current_stage = _proj[0].stage

# ── Draw road from back to front ──────────────────────────────────────────────
func _draw_road_strips() -> void:
	# Draw back-to-front (far → near). Near strips naturally overwrite far ones.
	for i in range(_proj.size() - 1, 0, -1):
		var near := _proj[i - 1]   # closer to camera  → bottom of strip (large sy)
		var far  := _proj[i]       # farther from camera → top of strip  (small sy)

		# Clamp to screen; skip zero-height strips
		# cam_y_offset applies a uniform vertical shift (bump/camera bob)
		var y_bot := clampi(int(near.sy + cam_y_offset), 0, int(SH) - 1)
		var y_top := clampi(int(far.sy  + cam_y_offset), 0, int(SH) - 1)
		if y_top >= y_bot:
			continue

		var even := near.color_index == 0
		var si   := near.stage - 1   # 0-based stage index for palette

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
		if near.is_checkpoint:
			_quad(far.sx,  y_top, far.sw  * 0.55,
				  near.sx, y_bot, near.sw * 0.55, C_CHKPT)

		# ── Centre lane marking ────────────────────────────────────────────
		if even:
			_quad(far.sx,  y_top, far.sw  * 0.015,
				  near.sx, y_bot, near.sw * 0.015, C_LANE)

		# ── Roadside scenery ───────────────────────────────────────────────
		var sc := near.sw / ROAD_WIDTH
		if near.scenery_r != 0:
			_draw_scenery(near.scenery_r, near.sx + near.sw * 1.22, y_bot, sc)
		if near.scenery_l != 0:
			_draw_scenery(near.scenery_l, near.sx - near.sw * 1.22, y_bot, sc)

# ── Helpers ───────────────────────────────────────────────────────────────────

# ── Scenery drawing ───────────────────────────────────────────────────────────

func _draw_scenery(type: int, x: float, y_base: int, sc: float) -> void:
	match type:
		Track.SCENERY_REDWOOD:   _draw_redwood(x, y_base, sc)
		Track.SCENERY_PINE:      _draw_pine(x, y_base, sc)
		Track.SCENERY_GUARDRAIL: _draw_guardrail(x, y_base, sc)
		Track.SCENERY_OAK:       _draw_oak(x, y_base, sc)

func _draw_redwood(x: float, y_base: int, sc: float) -> void:
	var tw := maxf(sc * 70.0,  2.0)
	var th  := sc * 500.0
	var cw := maxf(sc * 300.0, 3.0)
	var ch  := sc * 2000.0
	draw_rect(Rect2(x - tw * 0.5, y_base - th,       tw, th), Color("#5A3010"))
	draw_rect(Rect2(x - cw * 0.5, y_base - th - ch,  cw, ch), Color("#173A17"))

func _draw_pine(x: float, y_base: int, sc: float) -> void:
	var hw := maxf(sc * 320.0, 2.0)
	var h   := sc * 1600.0
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(x,      y_base - h),
			Vector2(x + hw, float(y_base)),
			Vector2(x - hw, float(y_base)),
		]),
		Color("#163818")
	)

func _draw_guardrail(x: float, y_base: int, sc: float) -> void:
	var pw := maxf(sc * 40.0,  1.0)
	var ph  := sc * 280.0
	var bh := maxf(sc * 55.0,  1.0)
	var bw := maxf(sc * 300.0, 2.0)
	draw_rect(Rect2(x - pw * 0.5, y_base - ph,        pw, ph), Color("#707070"))
	draw_rect(Rect2(x - bw * 0.5, y_base - ph * 0.65, bw, bh), Color("#C0C0C0"))

func _draw_oak(x: float, y_base: int, sc: float) -> void:
	var tw := maxf(sc * 90.0,  2.0)
	var th  := sc * 380.0
	var cw := maxf(sc * 650.0, 3.0)
	var ch  := sc * 850.0
	draw_rect(Rect2(x - tw * 0.5, y_base - th,       tw, th), Color("#4A2A0A"))
	draw_rect(Rect2(x - cw * 0.5, y_base - th - ch,  cw, ch), Color("#2A5C18"))

# ── Deer rendering ────────────────────────────────────────────────────────────

func _draw_deer_obstacles() -> void:
	if deer_list.is_empty():
		return
	# Sort farthest-first so nearer deer are drawn on top (painter's algorithm)
	var sorted: Array = deer_list.duplicate()
	sorted.sort_custom(func(a, b): return float(a["z"]) > float(b["z"]))

	for d in sorted:
		var offset_z := float(d["z"]) - player_z
		if offset_z <= 0.0 or offset_z > float(DRAW_DIST) * Track.SEGMENT_LENGTH:
			continue
		var pidx := int(offset_z / Track.SEGMENT_LENGTH)
		if pidx >= _proj.size() - 1:
			continue
		var p  := _proj[pidx]
		var sc := p.sw / ROAD_WIDTH
		var sx := p.sx + float(d["x"]) * p.sw
		_draw_deer_sprite(sx, int(p.sy), sc)

func _draw_deer_sprite(x: float, y_base: int, sc: float) -> void:
	var C_BODY := Color("#8B6340")
	var C_ANTL := Color("#5C3D1A")

	var lw := maxf(sc * 28.0,  2.0)   # leg width
	var lh  := sc * 340.0              # leg height
	var bw := maxf(sc * 250.0, 3.0)   # body width
	var bh  := sc * 300.0              # body height
	var hw := maxf(sc * 100.0, 2.0)   # head width
	var hh  := sc * 190.0             # head + neck height

	var y_feet := float(y_base)
	var y_body := y_feet - lh
	var y_head := y_body - bh

	# Legs (two visible: front and rear)
	draw_rect(Rect2(x - bw * 0.32 - lw, y_body, lw, lh), C_BODY)
	draw_rect(Rect2(x + bw * 0.32,       y_body, lw, lh), C_BODY)
	# Body
	draw_rect(Rect2(x - bw * 0.5, y_head, bw, bh), C_BODY)
	# Neck + head (offset forward — deer faces right by convention)
	var hx := x + bw * 0.26
	draw_rect(Rect2(hx - hw * 0.5, y_head - hh, hw, hh), C_BODY)
	# Antlers
	var ah := sc * 200.0
	if ah >= 2.0:
		var aw := maxf(sc * 18.0, 1.0)
		# Left antler
		draw_rect(Rect2(hx - aw * 3.0, y_head - hh - ah,          aw, ah),       C_ANTL)
		draw_rect(Rect2(hx - aw * 6.5, y_head - hh - ah * 0.55,   aw * 3.5, aw), C_ANTL)
		# Right antler
		draw_rect(Rect2(hx + aw * 2.0, y_head - hh - ah,          aw, ah),       C_ANTL)
		draw_rect(Rect2(hx + aw * 2.0, y_head - hh - ah * 0.55,   aw * 3.5, aw), C_ANTL)

# Draw a perspective trapezoid centred on x1/x2
func _quad(x1: float, y1: int, w1: float,
		   x2: float, y2: int, w2: float,
		   color: Color) -> void:
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(x1 - w1, float(y1)), Vector2(x1 + w1, float(y1)),
			Vector2(x2 + w2, float(y2)), Vector2(x2 - w2, float(y2)),
		]),
		color
	)
