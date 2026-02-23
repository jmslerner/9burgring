class_name Track
extends RefCounted

# Length of each road segment in world units
const SEGMENT_LENGTH := 200.0
# How many segments form one rumble-strip alternation
const RUMBLE_LENGTH  := 3

# ── Segment ──────────────────────────────────────────────────────────────────
class Segment:
	var index:         int
	var curve:         float  # lateral curvature delta (neg=left, pos=right)
	var hill:          float  # vertical delta (neg=down, pos=up)
	var color_index:   int    # 0 or 1, alternates every RUMBLE_LENGTH segs
	var is_checkpoint: bool
	var stage:         int    # 1=Santa Cruz, 2=Felton, 3=Climb, 4=Descent

	func _init(i: int, s: int = 1) -> void:
		index         = i
		curve         = 0.0
		hill          = 0.0
		color_index   = (i / Track.RUMBLE_LENGTH) % 2
		is_checkpoint = false
		stage         = s

# ── Track ─────────────────────────────────────────────────────────────────────
var segments: Array[Segment] = []
var track_length: float = 0.0

func _init() -> void:
	_build_track()

# ── Builder helpers ───────────────────────────────────────────────────────────

func _seg(curve: float = 0.0, hill: float = 0.0, stage: int = 1) -> void:
	var s := Segment.new(segments.size(), stage)
	s.curve = curve
	s.hill  = hill
	segments.append(s)

func _straight(count: int, stage: int = 1) -> void:
	for _i in range(count):
		_seg(0.0, 0.0, stage)

# Smoothly interpolate a section: ramp up, hold, ramp down
func _section(count: int, curve: float, hill: float, stage: int = 1) -> void:
	var ramp := mini(count / 4, 8)
	for i in range(count):
		var t: float
		if i < ramp:
			t = float(i) / ramp
		elif i > count - ramp:
			t = float(count - i) / ramp
		else:
			t = 1.0
		_seg(curve * t, hill * t, stage)

func _mark_checkpoint() -> void:
	if segments.is_empty():
		return
	segments.back().is_checkpoint = true

# ── SR 9: Santa Cruz → Los Gatos (900 segments, 3 checkpoints) ───────────────
#
# Stage 1 (0–199):   Santa Cruz → Felton   — coastal town, redwood forest
# Stage 2 (200–379): Felton → Boulder Creek — mountain towns, river valley
# Stage 3 (380–699): The Climb              — tight hairpins, steep ascent
# Stage 4 (700–899): The Descent            — sweeping curves, vineyard, sunset
#
func _build_track() -> void:

	# ── STAGE 1: Santa Cruz → Felton ──────────────────────────────────────
	_straight(30, 1)                        # city exit, flat
	_section(30,  0.003,  0.002, 1)         # gentle right, slight rise
	_section(15, -0.004,  0.000, 1)         # S-curve left
	_section(15,  0.004,  0.000, 1)         # S-curve right
	_section(40, -0.005,  0.002, 1)         # long left into redwood forest
	_straight(30, 1)                        # straight through redwoods
	_section(40,  0.004,  0.002, 1)         # right curve into Felton
	_mark_checkpoint()                      # CHECKPOINT 1 — Felton (seg 199)

	# ── STAGE 2: Felton → Boulder Creek ───────────────────────────────────
	_straight(30, 2)                        # town zone, flat
	_section(20, -0.005,  0.001, 2)         # S-curve left along river
	_section(20,  0.005,  0.001, 2)         # S-curve right
	_section(40,  0.006,  0.002, 2)         # long right, bridge crossing
	_section(40, -0.005,  0.001, 2)         # left through Ben Lomond
	_section(30, -0.003,  0.002, 2)         # into Boulder Creek
	_mark_checkpoint()                      # CHECKPOINT 2 — Boulder Creek (seg 379)

	# ── STAGE 3: The Climb ─────────────────────────────────────────────────
	_section(40,  0.003,  0.005, 3)         # steep uphill begins, gentle curves
	_section(40, -0.009,  0.006, 3)         # tight left hairpin + uphill
	_straight(10, 3)                        # short breather
	_section(30,  0.000,  0.007, 3)         # steep uphill, cliff edge
	_section(40,  0.010,  0.005, 3)         # tight right hairpin
	_section(20, -0.005,  0.003, 3)         # left lean recovery
	_section(40, -0.008,  0.004, 3)         # S-curve left, continued climb
	_section(40,  0.006,  0.003, 3)         # S-curve right
	_section(40, -0.011,  0.005, 3)         # very tight left hairpin (Castle Rock)
	_section(40,  0.007,  0.003, 3)         # sweeping right, uphill eases
	_mark_checkpoint()                      # CHECKPOINT 3 — Saratoga Gap (seg 699)

	# ── STAGE 4: The Descent ───────────────────────────────────────────────
	_straight(40, 4)                        # summit vista, panoramic moment
	_section(40,  0.007, -0.006, 4)         # fast right, steep downhill begins
	_section(20, -0.005, -0.005, 4)         # S-curves downhill left
	_section(20,  0.005, -0.005, 4)         # S-curves downhill right
	_section(40, -0.006, -0.004, 4)         # long sweeping left, vineyard scenery
	_section(20,  0.003, -0.002, 4)         # gentle curves, entering Saratoga
	_straight(20, 4)                        # final straight into Los Gatos

	track_length = float(segments.size()) * SEGMENT_LENGTH

# ── Query ─────────────────────────────────────────────────────────────────────

func get_segment(z: float) -> Segment:
	var wrapped := fmod(z, track_length)
	if wrapped < 0.0:
		wrapped += track_length
	var idx := int(wrapped / SEGMENT_LENGTH) % segments.size()
	return segments[idx]

func get_segment_by_index(idx: int) -> Segment:
	return segments[idx % segments.size()]
