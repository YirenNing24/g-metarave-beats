extends Control

signal set_selected_map(audio_file)
signal song_selected

@onready var song_title: Label = %SongTitle
@onready var artist: Label = %Artist
@onready var bpm: Label = %Bpm
@onready var song_menu: Control = get_tree().get_root().get_node("SongMenu")

var song: Dictionary

func _ready() -> void:
	song_title.text = song.audio.title
	artist.text = song.audio.artist
	set_selected_map.connect(SONG.set_map)
	song_selected.connect(song_menu._song_selected)
	
func set_map() -> void:
	SONG.map_selected = song
	SONG.artist = artist.text
	SONG.song_name = song_title.text
	song_menu.set_selected_map(song.audio_file)
	await get_tree().create_timer(0.3).timeout
	
func _on_texture_button_pressed() -> void:
	set_map()
	song_selected.emit()
	#song_menu.gamestart_panel.show()
	LOADER.load_scene(self, "res://UIScenes/game_scene.tscn")
