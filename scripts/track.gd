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

	func _init(i: int) -> void:
		index         = i
		curve         = 0.0
		hill          = 0.0
		color_index   = (i / Track.RUMBLE_LENGTH) % 2
		is_checkpoint = false

# ── Track ─────────────────────────────────────────────────────────────────────
var segments: Array[Segment] = []
var track_length: float = 0.0

func _init() -> void:
	_build_track()

# ── Builder helpers ───────────────────────────────────────────────────────────

func _seg(curve: float = 0.0, hill: float = 0.0) -> void:
	var s := Segment.new(segments.size())
	s.curve = curve
	s.hill  = hill
	segments.append(s)

func _straight(count: int) -> void:
	for _i in range(count):
		_seg()

# Smoothly interpolate a section: ramp up, hold, ramp down
func _section(count: int, curve: float, hill: float) -> void:
	var ramp := mini(count / 4, 8)
	for i in range(count):
		var t: float
		if i < ramp:
			t = float(i) / ramp
		elif i > count - ramp:
			t = float(count - i) / ramp
		else:
			t = 1.0
		_seg(curve * t, hill * t)

func _mark_checkpoint() -> void:
	if segments.is_empty():
		return
	segments.back().is_checkpoint = true

# ── Touge mountain pass layout ────────────────────────────────────────────────
# Inspired by Initial D / OutRun: tight curves, big elevation changes,
# two checkpoints before the summit, then a descent sprint.
func _build_track() -> void:
	# Approach valley
	_straight(30)
	_section(40,  0.004, 0.004)   # gentle right, rising
	_section(20,  0.000, 0.006)   # brief straight, still climbing
	_section(35, -0.008, 0.005)   # left hairpin, steep rise

	# First mountain section
	_section(15,  0.000, 0.003)   # breather
	_section(30,  0.010, 0.004)   # tight right, nearing peak
	_section(25, -0.005, 0.002)   # S-left before summit
	_straight(10)

	# CHECKPOINT 1 (mid-mountain)
	_mark_checkpoint()

	# Summit twists
	_section(30,  0.009, -0.003)  # right, starting descent
	_section(25, -0.010, -0.005)  # sharp left hairpin, dropping fast
	_section(20,  0.006, -0.004)  # right, leveling
	_section(30, -0.004, -0.003)  # long left sweeper, descent continues
	_straight(15)

	# CHECKPOINT 2 (lower switchbacks)
	_mark_checkpoint()

	# Valley sprint
	_section(50,  0.003, -0.004)  # long right sweeper, flattening
	_section(30, -0.007,  0.002)  # back left, small rise
	_section(20,  0.008,  0.003)  # tight right
	_section(40, -0.005, -0.003)  # winding descent to finish
	_straight(40)                  # finish straight

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
