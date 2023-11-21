extends Node3D

@onready var audio_player: AudioStreamPlayer = %AudioStreamPlayer

var speed: int
var started: bool
var pre_start_duration: int
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
# Parameters:
# - path: A string representing the file path of the audio file.
#
# Example usage:
# ```gdscript
# play_song("res://audio/song.ogg")
# ```
func play_song(path: String) -> void:
	# Load and set the audio stream player with the selected audio file.
	var ogg_file: FileAccess = FileAccess.open(path, FileAccess.READ)
	var stream: AudioStreamOggVorbis = AudioStreamOggVorbis.load_from_file(path)
	audio_player.set_stream(stream)
	ogg_file.close()

# Set up the audio player for the game.
# Parameters:
# - game: A Node3D representing the game node.
# Example usage:
# ```gdscript
# setup(game)
# ```
func setup(game: Node3D) -> void:
	# Set up the audio player for the game.
	audio_player.stream.set_loop(false)
	speed = game.speed
	started = false
	pre_start_duration = game.bar_length_in_m
	start_pos_in_sec = game.start_pos_in_sec
	
# Start playing the audio from the specified position.
# Example usage:
# ```gdscript
# start()
# ```
func start() -> void:
	# Start playing the audio from the specified position.
	started = true
	audio_player.play(start_pos_in_sec)
	
	# Check if the pre-start duration has elapsed and start playing the audio.
	# Example usage:
	# ```gdscript
	# _process(delta)
	# ```
func _process(delta: float) -> void:
	if not started:
		pre_start_duration -= speed * delta
		if pre_start_duration <= 0:
			start()
			return
