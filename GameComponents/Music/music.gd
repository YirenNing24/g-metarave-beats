extends Node3D

@onready var audio_player: AudioStreamPlayer = %AudioStreamPlayer

var speed: int
var started: bool
var pre_start_duration: int
var start_pos_in_sec: int
var audio_file: String = SONG.map_selected.audio_file

func _ready() -> void:
	play_song(audio_file)
	
func play_song(path: String) -> void:
	var ogg_file: FileAccess = FileAccess.open(path, FileAccess.READ)
	var stream: AudioStreamOggVorbis = AudioStreamOggVorbis.load_from_file(path)
	audio_player.set_stream(stream)
	ogg_file.close()
	
func setup(game: Node3D) -> void:
	audio_player.stream.set_loop(false)
	speed = game.speed
	started = false
	pre_start_duration = game.bar_length_in_m
	start_pos_in_sec = game.start_pos_in_sec
	
func start() -> void:
	started = true
	audio_player.play(start_pos_in_sec)
	
func _process(delta: float) -> void:
	if not started:
		pre_start_duration -= speed * delta
		if pre_start_duration <= 0:
			start()
			return
