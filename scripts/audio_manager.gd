## AudioManager — autoloaded singleton
## Handles music tracks, sound effects, and engine audio.
## Add OGG/WAV files under:
##   res://assets/audio/music/   (e.g. stage1.ogg, select.ogg)
##   res://assets/audio/sfx/     (e.g. checkpoint.wav, offroad.wav)
extends Node

# ── Audio bus indices ─────────────────────────────────────────────────────────
const BUS_MASTER := "Master"

# ── Players ───────────────────────────────────────────────────────────────────
var _music_player:  AudioStreamPlayer
var _sfx_player:    AudioStreamPlayer
var _engine_player: AudioStreamPlayer

# ── Volume settings ───────────────────────────────────────────────────────────
var music_volume: float = 0.8  setget _set_music_vol
var sfx_volume:   float = 1.0  setget _set_sfx_vol

# ── State ─────────────────────────────────────────────────────────────────────
var _current_music: String = ""
var _engine_base_pitch := 0.8

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_music_player  = _make_player(false)
	_sfx_player    = _make_player(false)
	_engine_player = _make_player(true)   # loops continuously

func _make_player(loop: bool) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	add_child(p)
	return p

# ── Music ─────────────────────────────────────────────────────────────────────

## Play a music file by name (without extension).
## Looks for .ogg first, then .wav.
func play_music(name: String) -> void:
	if name == _current_music:
		return
	_current_music = name
	var stream := _load_audio("res://assets/audio/music/" + name)
	if stream == null:
		push_warning("AudioManager: music '%s' not found" % name)
		return
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_music_player.stream = stream
	_music_player.volume_db = linear_to_db(music_volume)
	_music_player.play()

func stop_music() -> void:
	_music_player.stop()
	_current_music = ""

# ── SFX ───────────────────────────────────────────────────────────────────────

## One-shot sound effect by name (without extension).
func play_sfx(name: String) -> void:
	var stream := _load_audio("res://assets/audio/sfx/" + name)
	if stream == null:
		return
	_sfx_player.stream = stream
	_sfx_player.volume_db = linear_to_db(sfx_volume)
	_sfx_player.play()

# ── Engine sound ──────────────────────────────────────────────────────────────

## Call every frame with normalised speed (0.0 – 1.0).
func update_engine(speed_norm: float) -> void:
	if not _engine_player.playing:
		var stream := _load_audio("res://assets/audio/sfx/engine")
		if stream != null:
			if stream is AudioStreamOggVorbis:
				stream.loop = true
			elif stream is AudioStreamWAV:
				stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			_engine_player.stream = stream
			_engine_player.play()
	_engine_player.pitch_scale = lerp(_engine_base_pitch, 2.0, speed_norm)
	_engine_player.volume_db   = linear_to_db(sfx_volume * 0.7)

func stop_engine() -> void:
	_engine_player.stop()

# ── Volume setters ────────────────────────────────────────────────────────────

func _set_music_vol(v: float) -> void:
	music_volume = clamp(v, 0.0, 1.0)
	_music_player.volume_db = linear_to_db(music_volume)

func _set_sfx_vol(v: float) -> void:
	sfx_volume = clamp(v, 0.0, 1.0)

# ── Internal loader ───────────────────────────────────────────────────────────

func _load_audio(base_path: String) -> AudioStream:
	for ext in [".ogg", ".wav", ".mp3"]:
		var path := base_path + ext
		if ResourceLoader.exists(path):
			return load(path) as AudioStream
	return null
