extends Node3D

signal song_finished

@onready var audio_player: AudioStreamPlayer = %AudioStreamPlayer

var speed: int
var started: bool = false
var pre_start_duration: float
var start_pos_in_sec: int
var audio_file: String = SONG.map_selected.audio_file


	# Play the selected song when the node is ready.
	# Example usage:
	# ```gdscript
	# _ready()
	# ```
func _ready() -> void:
	# Play the selected song when the node is ready.
	play_song(audio_file)
	
# Load and set the audio stream player with the selected audio file.
func play_song(path: String) -> void:
	var stream: AudioStreamOggVorbis = ResourceLoader.load(path)
	audio_player.set_stream(stream)

# Set up the audio player for the game
func setup(game: Node3D) -> void:
	# Set up the audio player for the game.
	audio_player.stream.set_loop(false)
	speed = game.speed
	pre_start_duration = game.bar_length_in_m
	start_pos_in_sec = game.start_pos_in_sec
	
# Start playing the audio from the specified position.
func start() -> void:
	# Start playing the audio from the specified position.
	audio_player.play(start_pos_in_sec)
	started = true
	
# Check if the pre-start duration has elapsed and start playing the audio.
func _process(delta: float) -> void:
	if not started:
		pre_start_duration -= speed * delta
		if pre_start_duration <= 0:
			start()
			return

func _on_audio_stream_player_finished() -> void:
	song_finished.emit()
