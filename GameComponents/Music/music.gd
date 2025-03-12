extends Node3D

signal song_finished
signal song_playback_time(time: int)
signal song_length(time: int)

@onready var audio_player: AudioStreamPlayer = %AudioStreamPlayer

var speed: int
var started: bool = false
var pre_start_duration: float
var start_pos_in_sec: int
var audio_file: String = SONG.map_selected.audio_file

var playback_postion: float 

# Load and set the audio stream player with the selected audio file.
func play_song(path: String) -> void:
	var stream: AudioStreamOggVorbis = ResourceLoader.load(path)
	audio_player.set_stream(stream)
	var length: int = audio_player.stream.get_length()

	song_length.emit(length)
	

func _physics_process(_delta: float) -> void:
	var playback_time: int = %AudioStreamPlayer.get_playback_position() + AudioServer.get_time_since_last_mix()
	song_playback_time.emit(playback_time)
	
	
# Set up the audio player for the game
func setup(game: Node3D) -> void:
	# Set up the audio player for the game.
	speed = game.speed
	pre_start_duration = game.bar_length_in_m
	start_pos_in_sec = game.start_pos_in_sec
	play_song(audio_file)
	audio_player.stream.set_loop(false)
	start()
	
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


func _on_user_hud_pause_button_pressed() -> void:
	playback_postion = %AudioStreamPlayer.get_playback_position()
	%AudioStreamPlayer.stop()
	
	
func _on_user_hud_play_button_pressed() -> void:
	%AudioStreamPlayer.play(playback_postion)
