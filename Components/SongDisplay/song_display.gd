extends Control

signal song_selected(song: Control)
signal song_started(song_file: String)
signal song_canceled

@onready var song_title: Label = %SongTitle
@onready var artist: Label = %Artist
@onready var bpm: Label = %Bpm
@onready var start_panel: Panel = %StartPanel

@onready var initiate_start_button: TextureButton = %InitiateStartButton
@onready var start_button: Button = %StartButton
@onready var cancel_button: TextureButton = %CancelButton

var song: Dictionary
var start_tween: Tween
var difficulty: String

func _ready() -> void:
	song_title.text = song.audio.title
	artist.text = song.audio.artist
	
func set_map() -> void:
	SONG.map_selected = song
	SONG.artist = artist.text
	SONG.song_name = song_title.text
	await get_tree().create_timer(0.3).timeout
	
func _on_initiate_start_button_pressed() -> void:
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
	set_map()
	song_started.emit(song.audio_file)

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
