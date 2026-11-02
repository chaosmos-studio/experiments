extends Node

# Every clip is optional: a missing file plays nothing, so the game runs the same whether or not the
# audio has been downloaded or synthesised yet.

const SFX_DIR: String = "res://assets/audio/sfx/"
const MUSIC_DIR: String = "res://assets/audio/music/"

const SFX_VOICES: int = 10

# Footsteps repeat several times a second. Four variants picked at random, with the pitch jittered a few
# percent, is enough that the ear stops hearing a loop.
const FOOTSTEP_VARIANTS: int = 4
const FOOTSTEP_DB: float = -13.0

# Named so the rest of the game asks for an event, not a filename.
const CLIPS: Dictionary = {
	&"click": "click.ogg",
	&"jump": "jump.ogg",
	&"land": "land.ogg",
	&"hit": "hit.ogg",
	&"pickup": "pickup.ogg",
}

const MUSIC_TRACK: String = "music.ogg"

# The same loop at 1.0 and at 1.12 reads as the game tightening.
const PITCH_AT_BASE: float = 1.0
const PITCH_AT_MAX: float = 1.12
const MUSIC_DB: float = -9.0
const DUCK_DB: float = -24.0

var _clips: Dictionary = {}
var _footsteps: Array[AudioStream] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _voices: Array[AudioStreamPlayer] = []
var _next_voice: int = 0
var _music: AudioStreamPlayer
var _want_music: bool = false

func _ready() -> void:
	for key: StringName in CLIPS:
		var path: String = SFX_DIR + String(CLIPS[key])
		if ResourceLoader.exists(path):
			_clips[key] = load(path)

	for i: int in range(FOOTSTEP_VARIANTS):
		var step: String = SFX_DIR + "footstep_%d.ogg" % i
		if ResourceLoader.exists(step):
			_footsteps.append(load(step))

	for i: int in range(SFX_VOICES):
		var voice: AudioStreamPlayer = AudioStreamPlayer.new()
		add_child(voice)
		_voices.append(voice)

	_music = AudioStreamPlayer.new()
	_music.volume_db = MUSIC_DB
	add_child(_music)
	var track: String = MUSIC_DIR + MUSIC_TRACK
	if ResourceLoader.exists(track):
		_music.stream = load(track)
		if _music.stream is AudioStreamOggVorbis:
			(_music.stream as AudioStreamOggVorbis).loop = true
	_music.finished.connect(_restart_music)

# Round-robins the voices, so a pickup during a crash does not cut the crash off.
func play(key: StringName, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	var stream: AudioStream = _clips.get(key, null)
	if stream == null:
		return
	var voice: AudioStreamPlayer = _voices[_next_voice]
	_next_voice = (_next_voice + 1) % _voices.size()
	voice.stream = stream
	voice.volume_db = volume_db
	voice.pitch_scale = pitch
	voice.play()

func footstep() -> void:
	if _footsteps.is_empty():
		return
	var voice: AudioStreamPlayer = _voices[_next_voice]
	_next_voice = (_next_voice + 1) % _voices.size()
	voice.stream = _footsteps[_rng.randi_range(0, _footsteps.size() - 1)]
	voice.volume_db = FOOTSTEP_DB
	voice.pitch_scale = _rng.randf_range(0.92, 1.08)
	voice.play()

func start_music() -> void:
	_want_music = true
	if _music.stream == null or _music.playing:
		return
	_music.pitch_scale = PITCH_AT_BASE
	_music.volume_db = MUSIC_DB
	_music.play()

func stop_music() -> void:
	_want_music = false
	_music.stop()

# 0 at the start of a run, 1 at its most intense.
func set_intensity(ratio: float) -> void:
	_music.pitch_scale = lerpf(PITCH_AT_BASE, PITCH_AT_MAX, clampf(ratio, 0.0, 1.0))

# Pulled down rather than stopped, so a crash lands against something instead of silence.
func duck() -> void:
	_music.volume_db = DUCK_DB

func unduck() -> void:
	_music.volume_db = MUSIC_DB

# Web is included on purpose: a phone running the web build reports mobile=false.
func buzz(milliseconds: int) -> void:
	if OS.has_feature("mobile") or OS.has_feature("web"):
		Input.vibrate_handheld(milliseconds)

func _restart_music() -> void:
	if _want_music:
		_music.play()
