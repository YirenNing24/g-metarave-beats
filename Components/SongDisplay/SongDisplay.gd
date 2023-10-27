extends Control

signal set_selected_map(audio_file: String)
signal song_selected(game_scene: String)

@onready var song_title: Label = %SongTitle
@onready var artist: Label = %Artist
@onready var bpm: Label = %Bpm
@onready var song_menu: Control = get_tree().get_root().get_node("SongMenu")

var song: Dictionary

func _ready() -> void:
	song_title.text = song.audio.title
	artist.text = song.audio.artist
	var _set_map: int = set_selected_map.connect(SONG.set_map)
	var song_selected_func: Callable = song_menu.song_selected
	var _select_song: int = song_selected.connect(song_selected_func)
	
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
	var _game_scene: int = await LOADER.load_scene(self, "res://UIScenes/game_scene.tscn")
