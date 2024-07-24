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


func _ready() -> void:
	set_note_position()
	var _note_connect: int = note_area.area_entered.connect(_on_area_entered)
	connect_notes()
	

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


# Method to set the position of the note based on the line and layer.
func set_note_position() -> void:
	const z_values: Array[float] = [-1.79, -0.89, 0, 0.89, 1.79]
	var z: float

	if line in [1, 2, 3, 4, 5]:
		z = z_values[line - 1]
	elif line in [6, 7, 8, 9, 10, 11, 12, 13, 14, 15]:
		rotation.y = 90
		z = z_values[line - 6]
	position = Vector3(z, layer, -note_position * length_scale)


# Method to handle the area entered signal of the note.
func _on_area_entered(area: Area3D) -> void:
	if collected:
		return
	const area_groups: Array[String] = ["perfect_area", "verygood_area", "good_area", "bad_area", "miss_area"]
	const area_accuracy: Array[int]  = [1, 2, 3, 4, 5]
	
	for i: int in range(area_groups.size()):
		if area.is_in_group(area_groups[i]):
			accuracy = area_accuracy[i]
			is_colliding = (accuracy != 5)
			picker = area.get_parent()
			if accuracy == 5:
				collect(true)
			break


func connect_notes() -> void:
	for note_picker: Node3D in get_tree().get_nodes_in_group('Picker'):
		var feedback: Callable = note_picker.hit_feedback
		var _1: int = hit_feedback.connect(feedback)
