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

# Ready function called when the node and its children are added to the scene.
func _ready() -> void:
	# Initialize and set up the UI elements, connect signals.
	parse_song_files()
	list_songs()
	hud_data()
	var _song_selected: int = SONG.set_selected_map.connect(set_selected_map)

# Initialize HUD data, such as energy, beats, and kmr balances.
func hud_data() -> void:
	energy_balance.text = "500 Energy to do"
	beats_balance.text = PLAYER.beats_balance
	kmr_balance.text = PLAYER.kmr_balance

# Parse the song files in the specified directory.
func parse_song_files() -> void:
	# Initialize arrays to store file names and directories.
	var file_names: Array = []
	var dir: DirAccess = DirAccess.open(songs_directory)

	if dir:
		var _list_begin: int = dir.list_dir_begin()
		var file_name: String = dir.get_next()

		# Iterate through the directory entries.
		while file_name != "":
			if not dir.current_is_dir():
				# Check for .song files and add them to the list.
				if file_name.ends_with(".song"):
					file_names.append(["", file_name])
			elif file_name != ".." and file_name != ".":
				# Recursively search subdirectories.
				file_names += search_dir(songs_directory + file_name)
			file_name = dir.get_next()

		dir.list_dir_end()

		# Parse each song file.
		for file_name_entry: Array in file_names:
			parse_song_file(file_name_entry)

# Parse individual song files.
func parse_song_file(file_name_entry: Array) -> void:
	var song_file_dir: String = file_name_entry[0]
	var song_file_name: String = file_name_entry[1]
	var song_file_path: String = song_file_name

	# Construct the full path to the song file.
	if song_file_dir != "":
		song_file_path = song_file_dir + "/" + song_file_name

	# Open the song file and parse its content.
	var file: FileAccess = FileAccess.open(song_file_path, FileAccess.READ)
	if file:
		var content: String = file.get_as_text()
		file.close()
		var content_json: Dictionary = JSON.parse_string(content)

		# Update file paths in the content JSON.
		content_json.audio_file = song_file_dir + "/" + content_json.audio_file
		content_json.map_file = song_file_dir + "/" + song_file_name
		content_json.map_directory = song_file_dir + "/"
		song_files.append(content_json)
	else:
		print("Error opening file: ", song_file_path)

# Recursively search subdirectories for .json files.
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

# List the parsed songs in the UI.
func list_songs() -> void:
	for song: Dictionary in song_files:
		var songs: Control = song_display.instantiate()
		songs.song = song
		songs.name = song.audio.title
		var song_title: String = 'UITextures/SongMenu/' + song.audio.title.to_lower() + '.png'
		songs.get_node("TextureRect/SongArt").texture = load(song_title)
		song_list_container.add_child(songs)

# Callback function to set the selected map when a song is chosen.
func set_selected_map(audio_file: String) -> void:
	if selected_map != SONG.map_selected.song_folder:
		map_changed = true
		selected_map = SONG.map_selected.song_folder
		play_song(audio_file)

# Play the selected song.
func play_song(path: String) -> void:
	var stream: AudioStreamOggVorbis = AudioStreamOggVorbis.load_from_file(path)
	audio_player.set_stream(stream)
	audio_player.play(stream.get_length() / 2)

# Callback function for the close button pressed signal.
func _on_close_button_pressed() -> void:
	# Perform actions on close button press.
	BKMREngine.Auth.auto_login_player()
	LOADER.previous_texture = background_texture.texture
	LOADER.next_texture = preload("res://UITextures/BGTextures/main.png")
	var _main_screen: int = await LOADER.load_scene(self, "res://UIScenes/main_screen.tscn")

# Callable function for song selection in the UI.
func song_selected() -> Callable:
	# Load the game scene when a song is selected.
	var _game_scene: int = await LOADER.load_scene(self, "res://UIScenes/game_scene.tscn")
	return song_selected
