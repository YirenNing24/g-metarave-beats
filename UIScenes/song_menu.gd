extends Control
#NOTE afer canceling song select the song displays scroll on its own
#NOTE preview music not playing when selecting a song from the song displays

@onready var background_texture: TextureRect = %BackgroundTexture
@onready var audio_player: AudioStreamPlayer = %AudioStreamPlayer
@onready var song_scroll_container: ScrollContainer = %SongScrollContainer
@onready var song_list_container: HBoxContainer = %HBoxContainer

@onready var energy_balance: Label = %EnergyBalance
@onready var beats_balance: Label = %BeatsBalance
@onready var gmr_balance: Label = %KMRBalance

@onready var difficulty_label: Label = %DifficultyLabel
@onready var left_difficulty_button: TextureButton = %LeftDifficultyButton
@onready var right_difficulty_button: TextureButton = %RightDifficultyButton

const song_display: PackedScene = preload("res://Components/SongDisplay/song_display.tscn")
const songs_directory: String = "res://Songs/"
var song_files: Array
var map_changed: bool = false
var selected_map: String

const difficulty: Array[String] = ['easy', 'medium', 'hard', 'ultra hard']
var difficulty_mode: String = "easy" #default

# Ready function called when the node and its children are added to the scene.
func _ready() -> void:
	# Initialize and set up the UI elements, connect signals.

	parse_song_files()
	list_songs()
	hud_data()
	#get_classic_high_score()
	
	left_difficulty_button.disabled = true
	left_difficulty_button.modulate = "ffffff68"


func on_get_classic_high_score_complete(high_scores: Array[Dictionary]) -> void:
	for score: Dictionary in high_scores:
		for song: Control in song_list_container.get_children():
			if song.name == score.scoreStats.finalStats.songName:
				var high_score: String = str(score.scoreStats.finalStats.score)
				var formatted_high_score: String = format_scores(high_score)
				song.get_node("HBoxContainer2/HBoxContainer/HighScoreLabel").text = formatted_high_score
				

# Initialize HUD data, such as energy, beats, and kmr balances.
func hud_data() -> void:
	energy_balance.text = "0"
	beats_balance.text = PLAYER.beats_balance
	gmr_balance.text = PLAYER.gmr_balance


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

		return file_names as Array
	else:
		return []


# List the parsed songs in the UI.
func list_songs() -> void:
	for song: Dictionary in song_files:
		var songs: Control = song_display.instantiate()
		songs.song = song
		songs.name = song.audio.title
		var song_title: String = 'UITextures/SongMenu/' + song.audio.title.to_lower().replace(' ', '') + '.png'
		songs.get_node("TextureRect/SongArt").texture = load(song_title)
		song_list_container.add_child(songs)
		
		songs.song_selected.connect(song_selected)
		songs.song_selected.connect(song_unfocused_selected.bind(songs.get_index()))
		songs.song_started.connect(song_start)
		songs.song_canceled.connect(song_cancel)

# Callback function to set the selected map when a song is chosen.
func set_selected_map(_audio_file: String) -> void:
	if selected_map != SONG.map_selected.song_folder:
		map_changed = true
		selected_map = SONG.map_selected.song_folder

# Preview Play the selected song.
func play_preview(path: String) -> void:
	var stream: AudioStreamOggVorbis = ResourceLoader.load(path)
	audio_player.set_stream(stream)
	audio_player.play(stream.get_length() / 2)


# Callback function for the close button pressed signal.
func _on_close_button_pressed() -> void:
	# Perform actions on close button press.
	BKMREngine.Auth.auto_login_player()
	LOADER.previous_texture = background_texture.texture
	LOADER.next_texture = preload("res://UITextures/BGTextures/main_city.png")
	var _main_screen: int = await LOADER.load_scene(self, "res://UIScenes/main_screen.tscn")


# Callable function for song selection in the UI.
func song_selected(display: Control) -> void:
	song_scroll_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var song_path: String = display.song.audio_file
	play_preview(song_path)


func song_cancel() -> void:
	song_scroll_container.mouse_filter = Control.MOUSE_FILTER_PASS
	audio_player.stop()


func song_unfocused_selected(_song_display: Control, index: int) -> void:
	song_scroll_container.song_unfocused_selected(index) 
		
		 
func song_start(song_file: String) -> void:
	SONG.difficulty = difficulty_mode
	set_selected_map(song_file)  
	var _game_scene: int = await LOADER.load_scene(self, "res://UIScenes/game_scene.tscn")
	
	
func _on_left_difficulty_button_pressed() -> void:
	var current_difficulty: int = difficulty.find(difficulty_mode)
	if current_difficulty != 0:  
		var new_difficulty: String = difficulty[current_difficulty - 1]
		difficulty_mode = new_difficulty
		difficulty_update()
		right_difficulty_button.disabled = false
		right_difficulty_button.modulate = "ffffff"
	if difficulty_mode == "easy":
		left_difficulty_button.disabled = true
		left_difficulty_button.modulate = "ffffff68"
		
		
func _on_right_difficulty_button_pressed() -> void:
	var current_difficulty: int = difficulty.find(difficulty_mode)
	if current_difficulty != 3:
		var new_difficulty: String = difficulty[current_difficulty + 1]
		difficulty_mode = new_difficulty
		difficulty_update()
		left_difficulty_button.disabled = false
		left_difficulty_button.modulate = "ffffff"
	if difficulty_mode == "ultra hard":
		right_difficulty_button.disabled = true
		right_difficulty_button.modulate = "ffffff68"
		
		
func difficulty_update() -> void:
	difficulty_label.text = difficulty_mode
	
	
func format_scores(value: String) -> String:
	var parts: Array = value.split(".")
	var wholePart: String = parts[0]
	
	# Add commas for every three digits in the whole part.
	var formattedWholePart: String = ""
	var digitCount: int = 0
	for i: int in range(wholePart.length() - 1, -1, -1):
		formattedWholePart = wholePart[i] + formattedWholePart
		digitCount += 1
		if digitCount == 3 and i != 0:
			formattedWholePart = "," + formattedWholePart
			digitCount = 0
	return formattedWholePart as String
