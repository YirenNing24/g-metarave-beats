extends Node3D


signal notepicker_position(pos: float)

#signal song_finished

# Reference to the node containing musical bars.
@onready var bars_node: Node3D = %BarsNode
# Reference to the user's heads-up display (HUD).
@onready var user_hud: Control = get_node('../CanvasLayer/UserHUD')

# PackedScene for the musical bar.
var bar_scene: PackedScene = load("res://GameComponents/Bar/bar.tscn")
# Array to store the active musical bars.
var bars: Array[Node3D] = []

# Length of a musical bar in meters.
var bar_length_in_meters: float
# Current location of the bars in the game world.
var current_location: Vector3
# Speed vector for the movement of the bars.
var speed: Vector3
# Scaling factor for the musical notes.
var note_scale: float

# Index of the current musical bar.
var current_bar_index: int = 0
# Data for the musical tracks.
var tracks_data: Array
# Scaled amount of bars to be displayed on the screen.
var scaled_bar_amount: float
# Maximum index of musical bars.
var max_index: int
# Reference to the main game node.
var game: Node3D


# Set up the musical bars for the game.
func setup(game_config: Node3D) -> void:
	game = game_config
	var game_speed: float = game.speed
	speed = Vector3(0, 0, game_speed)
	bar_length_in_meters = game.bar_length_in_m
	current_location = Vector3(0, 0, -bar_length_in_meters)
	note_scale = game.note_scale

	current_bar_index = 0
	tracks_data = game.beatmap.tracks
	scaled_bar_amount = max(ceil(32 / bar_length_in_meters), 16.8)

	for track: Dictionary in tracks_data:
		max_index = max(max_index, len(track.bars))
	add_bars(scaled_bar_amount)
	

func _on_game_new_peer_id(peer_id: int) -> void:
	for picker: Node3D in get_tree().get_nodes_in_group("Picker"):
		picker.set_peer_id(peer_id)
	
	
# Process method called on every frame to update the position of musical bars.
func _physics_process(delta: float) -> void:
	# Apply movement with time scaling
	var scaled_delta: float = delta * Engine.time_scale
	bars_node.translate(speed * scaled_delta)

	# Remove bars that move too far and add new ones
	for bar: Node3D in bars: 
		if bar.position.z + bars_node.position.x >= bar_length_in_meters * 2:
			remove_bar(bar)
			add_bar()



# Method to add a musical bar to the scene.
func add_bar() -> void:
	if current_bar_index >= max_index:
		return
	
	var bar: Node3D = bar_scene.instantiate()
	bar.position = Vector3(current_location.x, current_location.y, current_location.z)
	bar.note_scale = note_scale
	bar.bar_data = get_bar_data()
	bar.speed = speed
	bars.append(bar)
	bars_node.add_child(bar)
	current_bar_index += 1
	bar.bar_index = current_bar_index
	current_location += Vector3(0, 0, -bar_length_in_meters)

# Method to retrieve the data for the current musical bar.
func get_bar_data() -> Array[Dictionary]:
	var irene_data: Dictionary = tracks_data[0].bars[current_bar_index]
	var seulgi_data: Dictionary = tracks_data[1].bars[current_bar_index]
	var wendy_data: Dictionary = tracks_data[2].bars[current_bar_index]
	var joy_data: Dictionary = tracks_data[3].bars[current_bar_index]
	var yeri_data: Dictionary = tracks_data[4].bars[current_bar_index]
	
	return [irene_data, seulgi_data, wendy_data, joy_data, yeri_data] 


# Method to remove a musical bar from the scene.
func remove_bar(bar: Node3D) -> void:
	bar.queue_free()
	bars.remove_at(0)
	if (len(bars) == 0) and current_bar_index == max_index:
		pass
		#song_finished.emit()

# Method to add a specified number of musical bars to the scene.
func add_bars(length: float) -> void:
	for _i: float in range(length):
		add_bar()


func _on__position_notepicker(y_position: float) -> void:
	notepicker_position.emit(y_position)
