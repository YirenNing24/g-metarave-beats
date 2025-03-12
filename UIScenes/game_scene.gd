extends Node3D

# References to game objects
@onready var road: Node3D = %Road
@onready var music: Node3D = %Music
@onready var user_hud: Control = %UserHUD
@onready var loading_screen: Control = %LoadingScreen

# Game configuration
var beatmap: Dictionary
var beatmap_file: String
var audio_file: String = SONG.map_selected.audio_file

# Gameplay parameters
var tempo: int
var bar_length_in_m: float = 16.8  # Godot meters
var quarter_time_in_sec: float
var speed: float
var note_scale: float
var start_pos_in_sec: float
var score: int = 0
var combo: int = 0

# Multiplayer-related variables
var peer_id: int = 0
var has_loaded: bool = false

func _ready() -> void:
	loading_screen.visible = true
	set_variables()


func set_variables() -> void:
	beatmap_file = SONG.map_selected.map_file
	print("anu: ", beatmap_file)
	beatmap = load_beatmap()
	if beatmap.is_empty():
		push_error("Failed to load beatmap.")
		return
	
	# Set UI elements
	user_hud.difficulty = beatmap.difficulty
	user_hud.song_name = beatmap.audio.title
	user_hud.set_artist(beatmap.audio.artist, beatmap.audio.title)
	SONG.song_name = beatmap.audio.title
	SONG.difficulty = beatmap.difficulty
	
	
func _on_loading_screen_loading_finished() -> void:
	loading_screen.visible = false
	song_game_start()
	
	
func song_game_start() -> void:
	if beatmap.is_empty():
		push_error("Beatmap is empty. Cannot start game.")
		return
	
	calculate_params()
	setup_nodes()
	
	
func calculate_params() -> void:
	tempo = beatmap.tempo
	quarter_time_in_sec = 60.0 / tempo  # Quarter note duration in seconds
	speed = bar_length_in_m / (4 * quarter_time_in_sec)  # Speed based on bar length
	note_scale = speed / 400  # Scale factor for notes

	var beatmap_start_pos: float = beatmap.start_pos
	start_pos_in_sec = (beatmap_start_pos / 400.0) * quarter_time_in_sec
	
	
func load_beatmap() -> Dictionary:
	var file: FileAccess = FileAccess.open(beatmap_file, FileAccess.READ)
	if not file:
		push_error("Error opening beatmap file: " + beatmap_file)
		return {}
	
	var json: JSON = JSON.new()
	if json.parse(file.get_as_text()) == OK and json.data is Dictionary:
		return json.data
	
	push_error("Error parsing beatmap JSON: " + beatmap_file)
	return {}
	
	
func setup_nodes() -> void:
	road.setup(self)
	music.setup(self)
