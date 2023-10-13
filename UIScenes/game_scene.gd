extends Node3D

@onready var road: Node3D = %Road
@onready var music: Node3D = %Music
@onready var user_hud: Control = %UserHUD

#var audio
var map: Dictionary
var map_file: String

var tempo: int
var bar_length_in_m: float
var quarter_time_in_sec: float
var speed: float
var note_scale: float
var start_pos_in_sec: float
var score: int = 0
var combo: int = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_variables()
	calculate_params()
	setup_nodes()

func set_variables() -> void:
	map_file = SONG.map_selected.map_file
	map = load_map()
	
func calculate_params() -> void:
	tempo = int(map.tempo)
	bar_length_in_m = 16.8# Godot meters
	quarter_time_in_sec = 60/float(tempo) # 60/60 = 1, 60/85 = 0.71
	speed = bar_length_in_m/float(4 * quarter_time_in_sec) # each bar has 4 quarters # 
	note_scale = bar_length_in_m/float(4 * 400)
	start_pos_in_sec = (float(map.start_pos)/400.0) * quarter_time_in_sec
	
func load_map() -> Dictionary:
	var file: FileAccess = FileAccess.open(map_file, FileAccess.READ)
	var content: String = file.get_as_text()
	file.close()
	var json: JSON = JSON.new()
	var error: Error = json.parse(content)
	if error == OK:
		var result: Dictionary = json.data
		return result
	else:
		return {}
		
func setup_nodes() -> void:
	music.setup(self)
	road.setup(self)
	
func build_map(_empty) -> void:
	pass
	
func map_finished() -> void:
	pass
