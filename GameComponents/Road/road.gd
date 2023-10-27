extends Node3D

@onready var bars_node: Node3D = %BarsNode
@onready var user_hud: Control = get_parent().get_node('CanvasLayer/UserHUD')

var bar_scene: PackedScene = preload("res://GameComponents/Bar/bar.tscn")
var bars: Array = []

var bar_length_in_meters: float
var current_location: Vector3
var speed: Vector3
var note_scale: float

var current_bar_index: int
var tracks_data: Array
var scaled_bar_amount: float
var max_index: int
var game: Node3D

# Called when the node enters the scene tree for the first time.
func setup(game_config: Node3D) -> void:
	game = game_config
	var game_speed: float = game.speed
	speed = Vector3(0, 0, game_speed)
	bar_length_in_meters = game.bar_length_in_m
	current_location = Vector3(0,0,-bar_length_in_meters)
	note_scale = game.note_scale
	
	current_bar_index = 0
	tracks_data = game.map.tracks
	scaled_bar_amount = max(ceil(32 / bar_length_in_meters), 16)
	max_index = 0
	for t: Dictionary in tracks_data:
		max_index = max(max_index, len(t.bars))
	add_bars(scaled_bar_amount)
	
func _process(delta: float) -> void:
	bars_node.translate(speed * delta)
	for bar: Node3D in bars:
		if bar.position.z + bars_node.position.z >= bar_length_in_meters:
			remove_bar(bar)
			add_bar()
		
		
func add_bar() -> void:
	if (current_bar_index >= max_index):
		return
		
	var bar: Node3D = bar_scene.instantiate()
	bar.position = Vector3(current_location.x, current_location.y, current_location.z)
	bar.note_scale = note_scale
	bar.bar_data = get_bar_data()
	bar.speed = speed
	bars.append(bar)
	bars_node.add_child(bar)
	current_location += Vector3(0, 0, -bar_length_in_meters)
	current_bar_index += 1
	
func get_bar_data() -> Array:
	var irene_data: Dictionary = tracks_data[0].bars[current_bar_index]
	var seulgi_data: Dictionary = tracks_data[1].bars[current_bar_index]
	var wendy_data: Dictionary = tracks_data[2].bars[current_bar_index]
	var joy_data: Dictionary = tracks_data[3].bars[current_bar_index]
	var yeri_data: Dictionary = tracks_data[4].bars[current_bar_index]
	return [irene_data, seulgi_data, wendy_data, joy_data, yeri_data]
	
func remove_bar(bar: Node3D) -> void:
	bar.queue_free()
	bars.erase(bar)
	if(len(bars) == 0) and current_bar_index == max_index:
		user_hud.song_finished()
		get_parent().map_finished()
		
func add_bars(l: float) -> void:
	for _i: float in range(l):
		add_bar()
