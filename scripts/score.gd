extends Node

# Original two-stem score. Both loops share an exact sample count and stay running
# together; only their gains change. No synthesis work runs in the gameplay loop.
var bed: AudioStreamPlayer
var melody: AudioStreamPlayer
var enabled := true
var volume := 0.5
var clarity := 0.0
var started := false
var active := true
var current_bed := 0.0
var current_melody := 0.0

func _ready() -> void:
	bed=_player("res://assets/audio/room-to-breathe-bed.ogg")
	melody=_player("res://assets/audio/room-to-breathe-melody.ogg")

func _player(path: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	var stream: AudioStreamOggVorbis = load(path).duplicate()
	stream.loop=true
	player.stream=stream
	player.volume_linear=0.0
	add_child(player)
	return player

func unlock() -> void:
	if not started and enabled and volume>0.0 and active:
		# Called by a real pointer/key gesture, so browser autoplay stays respected.
		started=true
		bed.play();melody.play()
	if started and active and enabled and volume>0.0:
		bed.stream_paused=false;melody.stream_paused=false

func set_active(value: bool) -> void:
	active=value
	if not active:
		bed.stream_paused=true;melody.stream_paused=true
	elif started and enabled and volume>0.0:
		bed.stream_paused=false;melody.stream_paused=false

func _process(delta: float) -> void:
	if not started or not active: return
	var target_bed := volume*0.35 if enabled else 0.0
	var target_melody := volume*lerpf(0.07,0.26,clarity) if enabled else 0.0
	current_bed=move_toward(current_bed,target_bed,delta*0.8)
	current_melody=move_toward(current_melody,target_melody,delta*0.30)
	bed.volume_linear=current_bed;melody.volume_linear=current_melody
	if current_bed==0.0 and current_melody==0.0:
		bed.stream_paused=true;melody.stream_paused=true

func is_audible() -> bool:
	return started and active and enabled and volume>0.0 and bed.playing and melody.playing and not bed.stream_paused
