## AudioManager — autoloaded singleton
## Drop audio files into:
##   res://assets/audio/music/  (select.ogg, stage1.ogg, finish.ogg)
##   res://assets/audio/sfx/    (engine.ogg, checkpoint.wav, etc.)
extends Node

var _music_player:  AudioStreamPlayer
var _sfx_player:    AudioStreamPlayer
var _engine_player: AudioStreamPlayer

var music_volume: float = 0.8
var sfx_volume:   float = 1.0

var _current_music: String = ""

func _ready() -> void:
	_music_player  = AudioStreamPlayer.new()
	_sfx_player    = AudioStreamPlayer.new()
	_engine_player = AudioStreamPlayer.new()
	add_child(_music_player)
	add_child(_sfx_player)
	add_child(_engine_player)

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
	_music_player.stream   = stream
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

func update_engine(speed_norm: float) -> void:
	if not _engine_player.playing:
		var stream = _load_audio("res://assets/audio/sfx/engine")
		if stream != null:
			_set_loop(stream, true)
			_engine_player.stream = stream
			_engine_player.play()
	_engine_player.pitch_scale = lerp(0.8, 2.0, speed_norm)
	_engine_player.volume_db   = linear_to_db(sfx_volume * 0.7)

func stop_engine() -> void:
	_engine_player.stop()

# ── Helpers ───────────────────────────────────────────────────────────────────

# Enable looping on any stream type without triggering static-type errors.
func _set_loop(stream, loop: bool) -> void:
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = loop
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = (
			AudioStreamWAV.LOOP_FORWARD if loop else AudioStreamWAV.LOOP_DISABLED
		)

# Returns an untyped Variant so callers can access subclass properties freely.
func _load_audio(base_path: String):
	for ext: String in [".ogg", ".wav", ".mp3"]:
		var path: String = base_path + ext
		if ResourceLoader.exists(path):
			return load(path)
	return null
