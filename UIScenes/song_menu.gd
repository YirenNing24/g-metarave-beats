extends Control

#TODO add beatmap completion

@onready var background_texture: TextureRect = %BackgroundTexture
@onready var audio_player: AudioStreamPlayer = %AudioStreamPlayer
@onready var song_scroll_container: ScrollContainer = %SongScrollContainer
@onready var song_list_container: HBoxContainer = %HBoxContainer

@onready var beats_balance: Label = %BeatsBalance
@onready var gmr_balance: Label = %KMRBalance

@onready var difficulty_label: Label = %DifficultyLabel
@onready var left_difficulty_button: TextureButton = %LeftDifficultyButton
@onready var right_difficulty_button: TextureButton = %RightDifficultyButton

const song_display: PackedScene = preload("res://Components/SongDisplay/song_display.tscn")

var song_files: Array[Dictionary]
var map_changed: bool = false
var selected_map: String

var recharge_progress: float = 0
var time_until_next_recharge : int
var recharge_interval : int = 60 * 60 * 1000 # 1 hour in milliseconds

const difficulty: Array[String] = ['easy', 'medium', 'hard', 'ultra hard']
var difficulty_mode: String = "easy" #default
var currently_highlighted_song: String = "No Doubt"
var all_scores: Dictionary = {} # Global or class-level if needed

var energy_available: bool = false


func _ready() -> void:
	if not SONG.difficulty.is_empty():
		difficulty_mode = SONG.difficulty
		difficulty_update()
	update_difficulty_buttons()
	%LoadingPanel.fake_loader()
	parse_song_files()
	list_songs()
	hud_data()
	connect_signals()
	if difficulty_mode == "easy":
		left_difficulty_button.modulate = "ffffff68"
	else:
		left_difficulty_button.modulate = "ffffffff"
	
	
func _process(delta: float) -> void:
	energy_check(delta)
	
	
func connect_signals() -> void:
	BKMREngine.Score.get_player_highscore_per_song_complete.connect(_on_get_player_highscore_per_song_complete)
	BKMREngine.Energy.use_player_energy_complete.connect(_on_use_player_energy_complete)
	check_energy()
	var _l: int = left_difficulty_button.pressed.connect(_on_left_difficulty_button_pressed)
	var _r: int = right_difficulty_button.pressed.connect(_on_right_difficulty_button_pressed)

	
func check_energy() -> void:
	if PLAYER.current_energy > 0:
		energy_available = true
	
	
func _on_use_player_energy_complete(energy_data: Dictionary) -> void:
	if energy_data.energy == true:
		energy_available = true
		BKMREngine.Energy.game_id = energy_data.gameId
	
	
func get_classic_high_score() -> void:
	BKMREngine.Score.get_player_highscore_per_song()
	
	
func _on_get_player_highscore_per_song_complete(scores: Array) -> void:
	# Group scores by song name and difficulty
	all_scores.clear()
	for score_data: Dictionary in scores:
		var key: String = "%s|%s" % [score_data.songName, score_data.difficulty]
		all_scores[key] = score_data
	
	update_scores_display()
	%LoadingPanel.tween_kill()
	
	
func update_scores_display() -> void:
	var song_map: Dictionary = {}
	for song: Control in song_list_container.get_children():
		song_map[song.name] = song
	
	for song_name: String in song_map.keys():
		var song_node: Control = song_map[song_name]
		var key: String = "%s|%s" % [song_name, difficulty_mode]

		# Default BPM based on difficulty
		var bpm_text: String = "170" if difficulty_mode == "easy" or difficulty_mode == "medium" else "199"
		song_node.get_node("VBoxContainer/HBoxContainer/TextureRect/TextureProgressBar/Bpm3/Bpm").text = bpm_text

		if all_scores.has(key):
			var score_data: Dictionary = all_scores[key]
			var high_score: String = str(score_data.score)
			var formatted_high_score: String = format_scores(high_score)
			song_node.get_node("HBoxContainer2/HBoxContainer/HighScoreLabel").text = formatted_high_score
		else:
			song_node.get_node("HBoxContainer2/HBoxContainer/HighScoreLabel").text = "0"
	
	
func on_get_classic_high_score_complete(high_scores: Array[Dictionary]) -> void:
	# Map song names to their corresponding Control nodes
	var song_map: Dictionary
	for song: Control in song_list_container.get_children():
		song_map[song.name] = song
	
	# Update high scores using the map
	for score: Dictionary[String, Variant] in high_scores:
		var song_name: String = score.scoreStats.finalStats.songName
		if song_map.has(song_name):
			var high_score: String = str(score.scoreStats.finalStats.score)
			var formatted_high_score: String = format_scores(high_score)
			song_map[song_name].get_node("HBoxContainer2/HBoxContainer/HighScoreLabel").text = formatted_high_score
	
	
# Initialize HUD data, such as energy, beats, and kmr balances.
func hud_data() -> void:
	%LoadingPanel.fake_loader()
	beats_balance.text = PLAYER.beats_balance
	gmr_balance.text = PLAYER.gmr_balance
	#native_balance.text = PLAYER.native_balance
	%Energy.text = str(PLAYER.current_energy) + " " + "/" + " " + str(PLAYER.max_energy)
	if PLAYER.time_until_next_recharge != 0:
		start_recharge_countdown(PLAYER.time_until_next_recharge)
	get_battery_percentage()
	
	
func get_battery_percentage() -> void:
	var battery_level: int = int(AndroidInterface.get_battery_level())
	%BatteryPercentage.text = str(battery_level) + "%"
	var _c:int = get_tree().create_timer(15.0).timeout.connect(get_battery_percentage)
	
	
func start_recharge_countdown(time_until_next: int) -> void:
	time_until_next_recharge = time_until_next
	recharge_progress = 0.0
	
	
func energy_check(delta: float) -> void:
	if PLAYER.current_energy >= PLAYER.max_energy:
		# Max energy reached, hide recharge label
		%EnergyRecharge.visible = false
		return

	# Recharge countdown is active
	time_until_next_recharge -= int(delta * 1000)
	if time_until_next_recharge > 0:
		recharge_progress = 100.0 - (float(time_until_next_recharge) / float(recharge_interval)) * 100.0
		%EnergyRecharge.text = str(int(recharge_progress)) + "%"
		%EnergyRecharge.visible = true
	else:
		# Recharge complete: add energy and reset countdown
		PLAYER.current_energy += 1
		%Energy.text = str(PLAYER.current_energy) + " / " + str(PLAYER.max_energy)

		if PLAYER.current_energy < PLAYER.max_energy:
			time_until_next_recharge = recharge_interval
			%EnergyRecharge.text = "1%"
		else:
			# Energy is maxed out, hide recharge progress
			%EnergyRecharge.visible = false
	
	
# Parse the song files in the specified directory.
func parse_song_files() -> void:
	const songs_directory: String = "res://Songs/"
	# Initialize arrays to store file names and directories.
	var file_names: Array[Array] = []
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
		for file_name_entry: Array[String] in file_names:
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
	var file_names: Array[Array] = []
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
	var grouped_songs: Dictionary = {}  # Store unique songs by title
	
	# Group songs by title
	for song: Dictionary[String, Variant] in song_files:
		var title: String = song.audio.title
		
		# If the song title is not yet in grouped_songs, create a new entry
		if not grouped_songs.has(title):
			grouped_songs[title] = {
				"easy": {},
				"medium": {},
				"hard": {},
				"ultra hard": {}
			}
		
		# Assign the song to its respective difficulty
		grouped_songs[title][song.difficulty] = song

	# Instantiate only one song_display per title
	for title: String in grouped_songs.keys():
		var song_entry: Control = song_display.instantiate()
		song_entry.name = title

		# Ensure each difficulty level gets a valid dictionary, even if empty
		song_entry.song_easy = grouped_songs[title]["easy"] if grouped_songs[title]["easy"] else {}
		song_entry.song_medium = grouped_songs[title]["medium"] if grouped_songs[title]["medium"] else {}
		song_entry.song_hard = grouped_songs[title]["hard"] if grouped_songs[title]["hard"] else {}
		song_entry.song_ultra_hard = grouped_songs[title]["ultra hard"] if grouped_songs[title]["ultra hard"] else {}

		# Load cover art dynamically
		var song_title: String = 'UITextures/SongMenu/' + title.to_lower().replace(' ', '') + '.png'
		song_entry.get_node("TextureRect/SongArt").texture = load(song_title)

		song_list_container.add_child(song_entry)

		# Connect signals
		song_entry.song_selected.connect(song_selected)
		song_entry.song_selected.connect(song_unfocused_selected.bind(song_entry.get_index()))
		song_entry.song_started.connect(song_start)
		song_entry.song_canceled.connect(song_cancel)
		song_entry.song_highlighted.connect(song_highlighted)
		song_entry.no_energy.connect(_on_no_energy)
	
	get_classic_high_score()
	%SongScrollContainer.add_songs()
	
	
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
	
	# Determine the correct song variant based on difficulty_mode
	var selected_song: Dictionary = {}
	match difficulty_mode:
		"easy":
			selected_song = display.song_easy
		"medium":
			selected_song = display.song_medium
		"hard":
			selected_song = display.song_hard
		"ultra hard":
			selected_song = display.song_ultra_hard
	
	# If the selected difficulty does not exist, default to "easy"
	if selected_song.is_empty():
		selected_song = display.song_easy
	
	# Check if there is a valid song to play
	if selected_song and selected_song.has("audio_file"):
		var song_path: String = selected_song.audio_file
		play_preview(song_path)
	else:
		print("No valid song found for", difficulty_mode)
	
	
func song_cancel() -> void:
	song_scroll_container.mouse_filter = Control.MOUSE_FILTER_PASS
	audio_player.stop()
	
	
func song_unfocused_selected(_song_display: Control, index: int) -> void:
	song_scroll_container.song_unfocused_selected(index) 
		
		 
func song_start(song_file: String) -> void:
	if energy_available:
		BKMREngine.Energy.game_id = ""
		BKMREngine.Energy.use_player_energy()
		SONG.difficulty = difficulty_mode
		set_selected_map(song_file)
		BKMREngine.Auth.validate_player_session()
		var _game_scene: int = await LOADER.load_scene(self, "res://UIScenes/game_scene.tscn")
		
	
func song_highlighted(song_name: String) -> void:
	if song_name != currently_highlighted_song:
		currently_highlighted_song = song_name

	
func _on_left_difficulty_button_pressed() -> void:
	var current_index: int = difficulty.find(difficulty_mode)
	if current_index > 0:
		difficulty_mode = difficulty[current_index - 1]
		SONG.difficulty = difficulty_mode
		difficulty_update()
		update_scores_display()
	update_difficulty_buttons()

func _on_right_difficulty_button_pressed() -> void:
	var current_index: int = difficulty.find(difficulty_mode)
	if current_index < difficulty.size() - 1:
		difficulty_mode = difficulty[current_index + 1]
		SONG.difficulty = difficulty_mode
		difficulty_update()
		update_scores_display()
	update_difficulty_buttons()


func update_difficulty_buttons() -> void:
	var current_index: int = difficulty.find(difficulty_mode)

	left_difficulty_button.disabled = current_index == 0
	right_difficulty_button.disabled = current_index == difficulty.size() - 1

	left_difficulty_button.modulate = "ffffff" if !left_difficulty_button.disabled else "ffffff68"
	right_difficulty_button.modulate = "ffffff" if !right_difficulty_button.disabled else "ffffff68"
	
	
func difficulty_update() -> void:
	difficulty_label.text = difficulty_mode
	update_difficulty_buttons()
	
	
func _on_no_energy() -> void:
	%AnimationPlayer.play("Notification")
	Input.vibrate_handheld(500)
	
	
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
	
	
func _on_leaderboard_button_pressed() -> void:
	%Leaderboard2Screen.open_laderboard(currently_highlighted_song, difficulty_mode)


func _on_leaderboard_2_screen_leaderboard_loading() -> void:
	%LoadingPanel.fake_loader()
	
	
func _on_leaderboard_2_screen_leaderboard_loading_complete() -> void:
	%LoadingPanel.tween_kill()
