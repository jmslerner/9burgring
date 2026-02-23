class_name Track
extends RefCounted

# Length of each road segment in world units
const SEGMENT_LENGTH := 200.0
# How many segments form one rumble-strip alternation
const RUMBLE_LENGTH  := 3

# ── Scenery object types ──────────────────────────────────────────────────────
const SCENERY_NONE      := 0
const SCENERY_REDWOOD   := 1   # tall thin trunk, narrow canopy  (stages 1-2)
const SCENERY_PINE      := 2   # triangular silhouette            (stage 3)
const SCENERY_GUARDRAIL := 3   # post + horizontal beam           (stage 3 hairpins)
const SCENERY_OAK       := 4   # shorter, wider canopy            (stage 4)

# ── Segment ──────────────────────────────────────────────────────────────────
class Segment:
	var index:         int
	var curve:         float  # lateral curvature delta (neg=left, pos=right)
	var hill:          float  # vertical delta (neg=down, pos=up)
	var color_index:   int    # 0 or 1, alternates every RUMBLE_LENGTH segs
	var is_checkpoint: bool
	var bump_mag:      float  # 0.0=none  0.3=mild ripple  1.0=dramatic jolt
	var stage:         int    # 1=coastal  2=river valley  3=climb  4=descent
	var scenery_l:     int
	var scenery_r:     int

	func _init(i: int, s: int = 1) -> void:
		index         = i
		curve         = 0.0
		hill          = 0.0
		color_index   = (i / Track.RUMBLE_LENGTH) % 2
		is_checkpoint = false
		bump_mag      = 0.0
		stage         = s
		scenery_l     = Track.SCENERY_NONE
		scenery_r     = Track.SCENERY_NONE

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

# ── SR 9: Santa Cruz → Los Gatos  (~8 000 segments, 8 checkpoints) ────────────
#
# Stage 1 (0   – 1999): Santa Cruz coastal → Scotts Valley — flat, redwoods
# Stage 2 (2000– 3999): Felton → Boulder Creek — river valley, S-curves
# Stage 3 (4000– 5999): The Climb — hairpins, steep ascent, pine forest
# Stage 4 (6000– 7999): The Descent — fast sweeps, vineyard, sunset
#
func _build_track() -> void:

	# ── STAGE 1 A: City exit & beach flats  (segs 0–1059) ─────────────────
	_straight(50, 1)                         # city exit, flat
	_section(80,  0.005,  0.001, 1)          # gentle right, slight rise
	_section(50, -0.007,  0.000, 1)          # S-curve left
	_section(50,  0.007,  0.000, 1)          # S-curve right
	_straight(80, 1)                         # beach stretch
	_section(70, -0.008,  0.001, 1)          # long sweeping left
	_section(80,  0.006,  0.002, 1)          # right into redwoods
	_straight(100, 1)                        # redwood straight
	_section(80, -0.009,  0.001, 1)          # winding left
	_section(80,  0.008,  0.002, 1)          # winding right
	_section(50, -0.005,  0.001, 1)          # ease
	_straight(60, 1)
	_section(80,  0.007,  0.002, 1)          # right curve
	_section(70, -0.006,  0.001, 1)          # left lean
	_straight(80, 1)
	# ~1060 segments — CHECKPOINT 1 (Scotts Valley)
	_mark_checkpoint()

	# ── STAGE 1 B: Through the redwood corridor  (segs 1060–1999) ─────────
	_section(60,  0.008,  0.001, 1)
	_section(60, -0.007,  0.002, 1)
	_straight(80, 1)
	_section(70,  0.009,  0.002, 1)
	_section(80, -0.006,  0.001, 1)
	_straight(60, 1)
	_section(70,  0.007,  0.002, 1)
	_section(80, -0.008,  0.001, 1)
	_straight(100, 1)
	_section(60,  0.006,  0.002, 1)
	_section(60, -0.005,  0.001, 1)
	_straight(80, 1)
	_section(50,  0.007,  0.001, 1)
	_straight(30, 1)
	# ~1940 — pad to 2000
	_straight(60, 1)
	# CHECKPOINT 2 (Felton / stage 1→2 boundary) at seg ~2000
	_mark_checkpoint()

	# ── STAGE 2 A: Felton river valley  (segs 2000–2899) ──────────────────
	_straight(50, 2)                         # Felton town flat
	_section(80, -0.008,  0.001, 2)          # S-curve left along river
	_section(80,  0.008,  0.001, 2)          # S-curve right
	_section(90,  0.009,  0.002, 2)          # long right, bridge crossing
	_section(80, -0.008,  0.001, 2)          # left through Ben Lomond
	_straight(60, 2)
	_section(70,  0.007,  0.002, 2)
	_section(70, -0.009,  0.001, 2)
	_section(60,  0.006,  0.002, 2)
	_straight(80, 2)
	_section(80, -0.007,  0.002, 2)
	_section(60,  0.008,  0.001, 2)
	_straight(40, 2)
	# ~900 segments — CHECKPOINT 3 (Ben Lomond)
	_mark_checkpoint()

	# ── STAGE 2 B: Ben Lomond → Boulder Creek  (segs 2900–3999) ──────────
	_section(80, -0.008,  0.002, 2)
	_section(70,  0.007,  0.001, 2)
	_straight(80, 2)
	_section(70, -0.009,  0.001, 2)
	_section(80,  0.008,  0.002, 2)
	_straight(60, 2)
	_section(60, -0.007,  0.001, 2)
	_section(70,  0.008,  0.002, 2)
	_straight(80, 2)
	_section(60, -0.006,  0.002, 2)
	_section(70,  0.009,  0.001, 2)
	_straight(80, 2)
	_section(60, -0.007,  0.001, 2)
	_section(70,  0.008,  0.002, 2)
	_straight(70, 2)
	# ~1100 segments in 2B — CHECKPOINT 4 (Boulder Creek / stage 2→3 boundary)
	_mark_checkpoint()

	# ── STAGE 3 A: The Climb — lower hairpins  (segs 4000–4999) ──────────
	_section(60,  0.006,  0.007, 3)          # steep uphill begins
	_section(80, -0.014,  0.008, 3)          # tight left hairpin
	_section(80,  0.015,  0.008, 3)          # tight right hairpin
	_straight(20, 3)                         # breather ledge
	_section(60,  0.000,  0.009, 3)          # steep cliff straight
	_section(80,  0.016,  0.007, 3)          # tight right hairpin
	_section(80, -0.013,  0.006, 3)          # left recovery
	_section(70,  0.011,  0.007, 3)          # right lean
	_straight(30, 3)
	_section(80, -0.017,  0.008, 3)          # very tight left (Castle Rock)
	_section(70,  0.012,  0.006, 3)          # recovery sweep
	_section(70, -0.013,  0.007, 3)          # left again
	_straight(40, 3)
	_section(80,  0.014,  0.008, 3)
	_section(70, -0.010,  0.006, 3)
	_straight(30, 3)
	# ~1000 segments — CHECKPOINT 5 (mid-Climb)
	_mark_checkpoint()

	# ── STAGE 3 B: The Climb — upper hairpins  (segs 5000–5999) ──────────
	_section(80,  0.013,  0.007, 3)
	_section(80, -0.015,  0.008, 3)
	_section(70,  0.016,  0.006, 3)
	_straight(30, 3)
	_section(80, -0.012,  0.005, 3)
	_section(80,  0.013,  0.006, 3)
	_section(70, -0.010,  0.005, 3)
	_straight(40, 3)
	_section(70,  0.011,  0.005, 3)
	_section(80, -0.014,  0.006, 3)
	_section(70,  0.009,  0.004, 3)
	_straight(60, 3)
	_section(70, -0.007,  0.004, 3)
	_section(60,  0.010,  0.005, 3)
	_straight(50, 3)
	_straight(10, 3)                         # summit approach
	# ~1000 segments — CHECKPOINT 6 (Saratoga Gap / stage 3→4)
	_mark_checkpoint()

	# ── STAGE 4 A: Fast descent — upper section  (segs 6000–6909) ────────
	_straight(60, 4)                         # summit vista
	_section(80,  0.010, -0.008, 4)          # fast right, steep descent begins
	_section(80, -0.007, -0.007, 4)          # S-curves downhill left
	_section(80,  0.009, -0.007, 4)          # S-curves downhill right
	_section(100,-0.009, -0.006, 4)          # long sweeping left, vineyard views
	_section(70,  0.006, -0.004, 4)          # easing curves
	_straight(60, 4)
	_section(80, -0.008, -0.005, 4)
	_section(70,  0.010, -0.006, 4)
	_section(80, -0.007, -0.004, 4)
	_straight(80, 4)
	_section(70,  0.009, -0.005, 4)
	# ~910 segments — CHECKPOINT 7 (Los Gatos approach)
	_mark_checkpoint()

	# ── STAGE 4 B: Saratoga → Los Gatos  (segs 6910–7999) ────────────────
	_section(70, -0.007, -0.003, 4)
	_section(80,  0.008, -0.002, 4)
	_straight(80, 4)
	_section(70, -0.006, -0.002, 4)
	_section(80,  0.007, -0.003, 4)
	_straight(60, 4)
	_section(70, -0.005, -0.002, 4)
	_section(60,  0.006, -0.001, 4)
	_straight(80, 4)
	_section(70, -0.004, -0.002, 4)          # easing into Los Gatos
	_section(70,  0.008, -0.002, 4)
	_straight(80, 4)
	_section(70, -0.005, -0.001, 4)
	_section(60,  0.006, -0.001, 4)
	_straight(70, 4)
	_section(70, -0.004, -0.002, 4)
	_section(80,  0.007, -0.003, 4)
	_straight(60, 4)
	# ~1090 segments — CHECKPOINT 8 (near finish)
	_mark_checkpoint()

	_straight(10, 4)                         # finish run-in

	track_length = float(segments.size()) * SEGMENT_LENGTH
	_assign_scenery()
	_add_bumps()

# ── Scenery placement ─────────────────────────────────────────────────────────
func _assign_scenery() -> void:
	for seg: Segment in segments:
		var alt := seg.index % 2 == 0
		match seg.stage:
			1:  # Coastal → redwood forest after city exit
				if seg.index >= 15 and alt:
					seg.scenery_l = SCENERY_REDWOOD
					seg.scenery_r = SCENERY_REDWOOD
			2:  # River valley: redwoods with occasional town gaps
				if alt and (seg.index % 14) > 3:
					seg.scenery_l = SCENERY_REDWOOD
					seg.scenery_r = SCENERY_REDWOOD
			3:  # Climb: pine forest; guardrails replace pines on tight hairpins
				if alt:
					seg.scenery_l = SCENERY_PINE
					seg.scenery_r = SCENERY_PINE
				if absf(seg.curve) > 0.008:
					seg.scenery_l = SCENERY_GUARDRAIL
					seg.scenery_r = SCENERY_GUARDRAIL
			4:  # Descent: oaks on right side (open valley view on left)
				if alt:
					seg.scenery_r = SCENERY_OAK

# ── Bump placement ────────────────────────────────────────────────────────────
# Marks segments with bump magnitude.
# mild_int: gentle ripples every N segments (bump_mag = 0.3)
# big_int:  dramatic jolts every M segments (bump_mag = 1.0), big wins if both hit
func _add_bumps() -> void:
	for seg: Segment in segments:
		if seg.is_checkpoint:
			continue
		var mild_int: int
		var big_int: int
		match seg.stage:
			1: mild_int = 90;  big_int = 450
			2: mild_int = 70;  big_int = 350
			3: mild_int = 50;  big_int = 250
			4: mild_int = 80;  big_int = 400
			_: mild_int = 90;  big_int = 450
		if seg.index % big_int == 7:
			seg.bump_mag = 1.0
		elif seg.index % mild_int == 3:
			seg.bump_mag = 0.3

# ── Query ─────────────────────────────────────────────────────────────────────

func get_segment(z: float) -> Segment:
	var wrapped := fmod(z, track_length)
	if wrapped < 0.0:
		wrapped += track_length
	var idx := int(wrapped / SEGMENT_LENGTH) % segments.size()
	return segments[idx]

func get_segment_by_index(idx: int) -> Segment:
	return segments[idx % segments.size()]
