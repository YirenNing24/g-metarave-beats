extends Node3D

signal hit_feedback(accuracy: int, line: int)

# Mesh instance representing the visual body of the note.
@onready var note_body: MeshInstance3D = get_node("NoteMesh/NoteBody")
# Area3D representing the collision area of the note.
@onready var note_area: Area3D = %NoteArea

# Line on which the note is placed.
var line: int
# Layer position of the note.
var layer: float = 0
# Position of the note within the line.
var note_position: int = 0
# Length of the note.
var length: int
# Scaling factor for the length of the note.
var length_scale: float
# Speed vector for the movement of the note.
var speed: Vector3
# Accuracy of the note hit.
var accuracy: int
# Multiplier for scoring.
var multiplier: int = 1
var slanted: bool
var uid: int = -1

# Flag indicating whether the note is currently colliding with the picker.
var is_colliding: bool = false
# Flag indicating whether the note has been collected.
var collected: bool = false
# Reference to the picker (player) node that collects the note.
var picker: Node3D = null
# Array to store concurrent notes (not used in the provided code).
var concurrent: Array = []

# Initialization method called when the node is ready.
func _ready() -> void:
	set_note_position()
	var _note_connect: int = note_area.area_entered.connect(_on_area_entered)

# Process method called on every frame.
func _process(_delta: float) -> void:
	# Check if the picker is present and is not collecting another note.
	if not picker or (picker.note_collect != null and picker.note_collect != self): 
		return
	# Check if the note is colliding and the picker is collecting.
	if not collected:
		if is_colliding and picker.is_collecting:
			collect()

# Method to handle the collection of the note.
func collect(is_miss: bool = false) -> void:
	note_body.visible = false
	collected = true
	picker.is_collecting = false
	if accuracy != 5:
		collected = true
		note_body.visible = false
	if not is_miss:
		picker.note_collect = self
	hit_feedback.emit(accuracy, line)
	#game_ui.hit_feedback(accuracy, line)
	#game_ui.add_score()

# Method to set the position of the note based on the line and layer.
func set_note_position() -> void:
	var z: float
	if line == 1:
		z = -1.79
	elif line == 2:
		z = -0.89
	elif line == 3:
		z = 0
	elif line == 4:
		z = 0.89
	elif line == 5:
		z = 1.79
	position = Vector3(z, layer , -note_position * length_scale)
	#var position_abs: Vector3= position.abs()
	#print("short: ", position_abs)
	#print("global: ", global_position)
	
# Method to handle the area entered signal of the note.
func _on_area_entered(area: Area3D) -> void:
	if collected:
		return
	if area.is_in_group("perfect_area"):
		accuracy = 1
		is_colliding = true
		picker = area.get_parent()
	elif area.is_in_group("verygood_area"):
		accuracy = 2
		is_colliding = true
		picker = area.get_parent()
	elif area.is_in_group("good_area"):
		accuracy = 3
		is_colliding = true
		picker = area.get_parent()
	elif area.is_in_group("bad_area"):
		accuracy = 4
		is_colliding = true
		picker = area.get_parent()
	elif area.is_in_group("miss_area"):
		accuracy = 5
		is_colliding = false
		picker = area.get_parent()
		collect(true)


