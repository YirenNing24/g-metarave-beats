extends Node3D


# Reference to the road Node3D.
@onready var road: Node3D = %Road
# Reference to the music Node3D.
@onready var music: Node3D = %Music
# Reference to the user HUD Control node.
@onready var user_hud: Control = %UserHUD

# Dictionary storing the map data.
var beatmap: Dictionary

# File path of the selected map.
@export var beatmap_file: String
@export var audio_file: String = SONG.map_selected.audio_file
@export var is_loading_done: bool = false

# Parameters for gameplay.
var tempo: int
var bar_length_in_m: float
var quarter_time_in_sec: float
var speed: float
var note_scale: float
var start_pos_in_sec: float
var score: int = 0
var combo: int = 0

var peer_id: int


func _ready() -> void:
	connect_signals()
	
	
func _on_road_notepicker_position(picker_y_position: float) -> void:
	var song_map: String = SONG.map_selected.map_file
	var song_audio_file: String = SONG.map_selected.audio_file
	MULTIPLAYER.load_song(song_map, song_audio_file, picker_y_position)
	
	
func connect_signals() -> void:
	var _1: int = MULTIPLAYER.loading_start.connect(_on_loading_start)
	var _2: int = MULTIPLAYER.server_game_started.connect(_on_server_game_started)
	var _3: int = MULTIPLAYER.player_peer_id_received.connect(_on_player_peer_id_received)
	
	
func song_game_start() -> void:
	set_variables()
	calculate_params()
	setup_nodes()
	

func _on_player_peer_id_received(id: int) -> void:
	peer_id = id
	PLAYER.peer_id = id
	name = str(id)
	

func set_variables() -> void:
	beatmap_file = SONG.map_selected.map_file
	beatmap = load_beatmap()


func _on_loading_start(id_peer: int) -> void:
	if name != "Game":
		return
	name = str(id_peer)
	%LoadingScreen.visible = true


func _on_loading_screen_loading_finished() -> void:
	get_tree().paused = true
	song_game_start()
	MULTIPLAYER.loading_finished(peer_id)
	
	
func _on_server_game_started(id_peer: int) -> void:
	if peer_id == id_peer:
		%LoadingScreen.visible = false
		get_tree().paused = false
	
	
# Function to calculate parameters based on the loaded map.
func calculate_params() -> void:
	var song_tempo: int = beatmap.tempo
	tempo = song_tempo
	bar_length_in_m = 16.8  # Godot meters
	quarter_time_in_sec = 60 / float(tempo)  # 60/60 = 1, 60/85 = 0.71
	speed = bar_length_in_m / float(4 * quarter_time_in_sec)  # each bar has 4 quarters
	note_scale = bar_length_in_m / float(4 * 400)

	var beatmap_start_pos: float = beatmap.start_pos
	start_pos_in_sec = (float(beatmap_start_pos) / 400.0) * quarter_time_in_sec


# Function to load the map data from the specified file.
func load_beatmap() -> Dictionary:
	var file: FileAccess = FileAccess.open(beatmap_file, FileAccess.READ)
	var content: String = file.get_as_text()
	file.close()
	var json: JSON = JSON.new()
	var error: Error = json.parse(content)
	if error == OK:
		var result: Dictionary = json.data
		return result
	else:
		return {}


# Function to set up the gameplay nodes (music and road).
func setup_nodes() -> void:
	road.setup(self)
	music.setup(self)
