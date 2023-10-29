extends Control

@onready var background_texture: TextureRect = %BackgroundTexture
@onready var audio_player: AudioStreamPlayer = %AudioStreamPlayer
@onready var song_scroll: ScrollContainer = %ScrollContainer
@onready var song_list_container: HBoxContainer = %HBoxContainer

@onready var energy_balance: Label = %EnergyBalance
@onready var beats_balance: Label = %BeatsBalance
@onready var kmr_balance: Label = %KMRBalance

var song_display: PackedScene = preload("res://Components/SongDisplay/SongDisplay.tscn")
var songs_directory: String = "res://Songs/"
var song_files: Array
var map_changed: bool = false
var selected_map: String

var difficulty: Array = ['easy', 'medium', 'hard', 'ultra hard']
var difficulty_mode: String = "easy" #default
var tween: Tween

func _ready() -> void:
	parse_song_files()
	list_songs()
	hud_data()
	var _song_selected: int = SONG.set_selected_map.connect(set_selected_map)
	
func hud_data() -> void:
	energy_balance.text = "500 Energy to do"
	beats_balance.text = PLAYER.beats_balance
	kmr_balance.text = PLAYER.kmr_balance
	
func parse_song_files() -> void:
	var file_names: Array = []
	var dir: DirAccess = DirAccess.open(songs_directory)
	if dir:
		var _list_begin: int = dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while  file_name != "":
			if not dir.current_is_dir():
				if file_name.ends_with(".song"):
					file_names.append(["", file_name])
					
			elif file_name != ".." and file_name != ".":
				file_names += search_dir(songs_directory + file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
		for file_name_entry: Array in file_names:
			parse_song_file(file_name_entry)
	
func parse_song_file(file_name_entry: Array) -> void:
	var song_file_dir: String = file_name_entry[0]
	var song_file_name: String = file_name_entry[1]
	var song_file_path: String = song_file_name
	
	if song_file_dir != "":
		song_file_path = song_file_dir + "/" + song_file_name
	var file: FileAccess = FileAccess.open(song_file_path, FileAccess.READ)
	if file:
		var content: String = file.get_as_text()
		file.close()
		var content_json: Dictionary = JSON.parse_string(content)
		content_json.audio_file = song_file_dir + "/" + content_json.audio_file
		content_json.map_file = song_file_dir + "/" + song_file_name
		content_json.map_directory = song_file_dir + "/"
		song_files.append(content_json)
		
	else:
		print("Error opening file: ", song_file_path)
	
func search_dir(dir_name: String) -> Array:
	var file_names: Array = []
	var dir: DirAccess = DirAccess.open(dir_name)
	if dir:
		var _list_begin: int = dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				if file_name.ends_with(".json"):
					file_names.append([dir_name, file_name])
			elif file_name != ".." and file_name != ".":
				file_names += search_dir(dir_name + "/" + file_name)
			file_name = dir.get_next()
		return file_names
	else:
		return []                                                                                                       
	  
func list_songs() -> void:
	for song: Dictionary in song_files:
		var songs: Control = song_display.instantiate()
		songs.song = song
		songs.name = song.audio.title
		var song_title: String = 'UITextures/SongMenu/' + song.audio.title.to_lower() + '.png'
		songs.get_node("TextureRect/SongArt").texture = load(song_title)
		song_list_container.add_child(songs)
		
func set_selected_map(audio_file: String) -> void:
	if selected_map != SONG.map_selected.song_folder:
		map_changed = true
		selected_map = SONG.map_selected.song_folder
		play_song(audio_file)
		
func play_song(path: String) -> void:
	var stream: AudioStreamOggVorbis = AudioStreamOggVorbis.load_from_file(path)
	audio_player.set_stream(stream)
	audio_player.play(stream.get_length()/2)
	
func _on_close_button_pressed() -> void:
	BKMREngine.Auth.auto_login_player()
	LOADER.previous_texture = background_texture.texture
	LOADER.next_texture = preload("res://UITextures/BGTextures/main.png")
	var _main_screen: int = await LOADER.load_scene(self, "res://UIScenes/main_screen.tscn")
	
func song_selected() -> Callable:
	var _game_scene: int = await LOADER.load_scene(self, "res://UIScenes/game_scene.tscn")
	return song_selected
