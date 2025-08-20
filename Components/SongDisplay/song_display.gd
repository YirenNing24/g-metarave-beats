extends Control

signal song_highlighted(song_name: String)
signal song_selected(song: Control)
signal song_started(song_file: String)
signal song_canceled
signal no_energy

@onready var song_title: Label = %SongTitle
@onready var artist: Label = %Artist
@onready var bpm: Label = %Bpm
@onready var start_panel: Panel = %StartPanel

@onready var initiate_start_button: TextureButton = %InitiateStartButton
@onready var start_button: Button = %StartButton
@onready var cancel_button: TextureButton = %CancelButton

var song_easy: Dictionary
var song_medium: Dictionary
var song_hard: Dictionary
var song_ultra_hard: Dictionary

var start_tween: Tween
var difficulty: String


var difficulty_mode: String

func _ready() -> void:
	var selected_song: Dictionary = song_easy  # Default to song_easy

	# If song_easy is empty, use song_ultra_hard instead
	if song_easy.is_empty():
		selected_song = song_ultra_hard

	# Set title and artist
	if selected_song.has("audio"):
		song_title.text = selected_song.audio.title
		artist.text = selected_song.audio.artist

	# Set tempo if it exists
	if selected_song.has("tempo"):
		@warning_ignore("unsafe_call_argument")
		%Bpm.text = str(int(selected_song.tempo))

	# Enable start button
	%StartButton.disabled = false
	
	
	
	
func set_map() -> void:
	difficulty_mode = get_tree().current_scene.difficulty_mode
	# Select the song data based on the difficulty_mode from the main scene
	var selected_song: Dictionary = {}
	match difficulty_mode:
		"easy":
			selected_song = song_easy
		"medium":
			selected_song = song_medium
		"hard":
			selected_song = song_hard
		"ultra hard":
			print(song_ultra_hard)
			selected_song = song_ultra_hard
	
	# Ensure a valid song is selected
	if selected_song.is_empty():
		print("No available song for difficulty: ", difficulty_mode)
		return
	SONG.map_selected = selected_song
	SONG.artist = artist.text
	SONG.song_name = song_title.text
	await get_tree().create_timer(0.3).timeout

	
func _on_initiate_start_button_pressed() -> void:
	if PLAYER.current_energy == 0:
		no_energy.emit()
		return
	cancel_button.visible = true
	on_song_selected()
	disable_not_selected_songs()
	song_selected.emit(self)
	
	
func on_song_selected() -> void:
	start_panel.visible = true
	start_tween = create_tween()
	var _tween_property: PropertyTweener = start_tween.tween_property(
		start_panel, 
		"modulate", 
		Color(255, 255, 255, 0), 
		1.5).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
		
	start_panel.modulate = "#ffffff"
	var _tween_callback: CallbackTweener = start_tween.tween_callback(on_song_selected)
	
	
func _on_start_button_pressed() -> void:
	start_tween.kill()
	difficulty_mode = get_tree().current_scene.difficulty_mode
	# Determine the correct song variant based on difficulty_mode
	var selected_song: Dictionary = {}
	match difficulty_mode:
		"easy":
			selected_song = song_easy
		"medium":
			selected_song = song_medium
		"hard":
			selected_song = song_hard
		"ultra hard":
			selected_song = song_ultra_hard
	
	# If the selected difficulty does not exist, default to "easy"
	if selected_song.is_empty():
		print("Error: No valid song found for ", difficulty_mode)
		return
		#selected_song = song_easy
	
	# Ensure we have a valid song before emitting the signal
	if selected_song and selected_song.has("audio_file"):
		set_map()
		print(selected_song.difficulty)
		song_started.emit(selected_song.audio_file)
	else:
		print("Error: No valid song found for ", difficulty_mode)

	
	
func _on_cancel_button_pressed() -> void:
	for songs: Control in get_tree().get_nodes_in_group('SongDisplay'):
		if songs.name != name:
			songs.initiate_start_button.disabled = false
			
	cancel_button.visible = false
	start_panel.visible = false
	start_tween.kill()
	song_canceled.emit()


func disable_not_selected_songs() -> void:
	for song_display: Control in get_tree().get_nodes_in_group('SongDisplay'):
		if song_display.name != name:
			song_display.initiate_start_button.disabled = true


func on_song_highlighted() -> void:
	song_highlighted.emit(song_title.text)
	
