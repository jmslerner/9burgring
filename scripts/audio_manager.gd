## AudioManager — autoloaded singleton
## Drop audio files into:
##   res://assets/audio/music/  (select.ogg, stage1.ogg, finish.ogg)
##   res://assets/audio/sfx/    (checkpoint.wav, gameover.wav, etc.)
extends Node

var _music_player:  AudioStreamPlayer
var _sfx_player:    AudioStreamPlayer
var _accel_player:  AudioStreamPlayer   # porsche speed-by (acceleration)
var _decel_player:  AudioStreamPlayer   # honda downshift  (deceleration)

var music_volume: float = 0.8
var sfx_volume:   float = 1.0

var _current_music:  String = ""
var _prev_accel:     bool   = false
var _prev_braking:   bool   = false

func _ready() -> void:
	_music_player  = AudioStreamPlayer.new()
	_sfx_player    = AudioStreamPlayer.new()
	_accel_player  = AudioStreamPlayer.new()
	_decel_player  = AudioStreamPlayer.new()
	add_child(_music_player)
	add_child(_sfx_player)
	add_child(_accel_player)
	add_child(_decel_player)

	# Pre-load engine sounds from res://audio/
	var accel_stream = _load_audio("res://audio/engine_accel")
	if accel_stream != null:
		_accel_player.stream    = accel_stream
		_accel_player.volume_db = linear_to_db(sfx_volume * 0.9)

	var decel_stream = _load_audio("res://audio/engine_decel")
	if decel_stream != null:
		_decel_player.stream    = decel_stream
		_decel_player.volume_db = linear_to_db(sfx_volume * 0.9)

# ── Music ─────────────────────────────────────────────────────────────────────

func play_music(track_name: String) -> void:
	if track_name == _current_music:
		return
	_current_music = track_name
	var stream = _load_audio("res://assets/audio/music/" + track_name)
	if stream == null:
		push_warning("AudioManager: music '%s' not found" % track_name)
		return
	_set_loop(stream, true)
	_music_player.stream    = stream
	_music_player.volume_db = linear_to_db(music_volume)
	_music_player.play()

func stop_music() -> void:
	_music_player.stop()
	_current_music = ""

# ── SFX ───────────────────────────────────────────────────────────────────────

func play_sfx(sfx_name: String) -> void:
	var stream = _load_audio("res://assets/audio/sfx/" + sfx_name)
	if stream == null:
		return
	_sfx_player.stream    = stream
	_sfx_player.volume_db = linear_to_db(sfx_volume)
	_sfx_player.play()

# ── Engine sound ──────────────────────────────────────────────────────────────
# Call each frame from game.gd with current normalised speed and input state.

func update_engine(speed_norm: float, accelerating: bool, braking: bool) -> void:
	# Pitch the accel clip slightly with speed for some extra feel
	_accel_player.pitch_scale = lerp(0.85, 1.2, speed_norm)

	# Trigger accel sound on rising edge of accelerate input
	if accelerating and not _prev_accel:
		if _accel_player.stream != null:
			_accel_player.play()

	# Trigger decel sound on rising edge of brake/lift, but only if moving
	if (braking or (not accelerating and _prev_accel)) and speed_norm > 0.05:
		if not _prev_braking and _decel_player.stream != null:
			_decel_player.play()

	_prev_accel   = accelerating
	_prev_braking = braking

func stop_engine() -> void:
	_accel_player.stop()
	_decel_player.stop()
	_prev_accel   = false
	_prev_braking = false

# ── Helpers ───────────────────────────────────────────────────────────────────

func _set_loop(stream, loop: bool) -> void:
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = loop
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = (
			AudioStreamWAV.LOOP_FORWARD if loop else AudioStreamWAV.LOOP_DISABLED
		)

func _load_audio(base_path: String):
	for ext: String in [".mp3", ".ogg", ".wav"]:
		var path: String = base_path + ext
		if ResourceLoader.exists(path):
			return load(path)
	return null
