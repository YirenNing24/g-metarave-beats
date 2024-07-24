extends Node3D

signal hit_continued_feedback(accuracy: int, line: int)
signal hit_feedback(accuracy: int, line: int)
# Mesh instance representing the visual body of the note.
@onready var note_body: MeshInstance3D = get_node("NoteMesh/NoteBody")
# Area3D representing the collision area of the note.
@onready var note_area: Area3D = %NoteArea
# Node3D representing the beam visual effect of the note.
@onready var beam: Node3D = %Beam
# Node3D representing the entire note mesh.
@onready var note_mesh: Node3D = %NoteMesh

# Properties defining the note's characteristics.
var line: int
var layer: float
var note_position: int = 0
var length: int
var length_scale: float
var speed: Vector3
var accuracy: int
var multiplier: int = 1

# State variables for note interactions.
var is_colliding: bool = false
var collected: bool = false
var picker: Node3D = null
var concurrent: Array = []

# Variables for long note handling.
var curr_length_in_m: float
var hold_started: bool = false
var hold_canceled: bool = false
var note_collecting: bool = false
var time_delay: float = 0.1
var time: float = 0
var hold: int = 0
var captured: bool = false

var slanted: bool
var uid: int = -1


# Initialize the note when ready.
func _ready() -> void:
	set_note_position()
	var _note_connect: int = note_area.area_entered.connect(_on_area_entered)
	
	# Calculate and set the current length of the note and update the beam scale.
	curr_length_in_m = max(100, length - 100) * length_scale
	beam.scale.z = curr_length_in_m
	connect_notes()
	
	
# Set the position of the note based on the specified line and layer.
# Method to set the position of the note based on the line and layer.
func set_note_position() -> void:
	var z_values: Array[float] = [-1.79, -0.89, 0, 0.89, 1.79]
	var z: float

	if line in [1, 2, 3, 4, 5]:
		z = z_values[line - 1]
	elif line in [6, 7, 8, 9, 10, 11, 12, 13, 14, 15]:
		rotation.y = 90
		z = z_values[line - 6]
	position = Vector3(z, layer, -note_position * length_scale)


# Handle the process logic for the note.
func _process(delta: float) -> void:
	# Check if the picker is present or if the current note is being collected by another picker.
	if not picker or (picker.note_collect != null and picker.note_collect != self):
		return

	if is_colliding:
		handle_collision()
	else:
		# If the hold was started and not canceled, trigger long_note_hold once.
		if hold_started and not hold_canceled:
			long_note_hold()
			hold_canceled = true

	# Check if the hold is started and not canceled.
	if hold_started and not hold_canceled:
		# Update the current length of the note and handle note collecting.
		handle_note_collecting(delta)


func handle_collision() -> void:
	if picker.is_collecting and not collected:
		collect()
		hold_started = true
		picker.note_collect = self
	elif not picker.is_collecting and hold_started and collected:
		hold_canceled = true
		picker.note_collect = null
		picker.is_collecting = false


func handle_note_collecting(delta: float) -> void:
	# Update the current length of the note.
	curr_length_in_m -= speed.z * delta
	note_collecting = true

	if note_collecting and curr_length_in_m > 0:
		# Update the time and trigger the long note hold if the time delay is reached.
		time += delta
		if time > time_delay:
			long_note_hold()
			time = 0
	else:
		note_collecting = false


# Handle the continued holding of a long note.
func long_note_hold() -> void:
	hit_continued_feedback.emit(accuracy, line)


# Collect the note and provide feedback.
func collect(is_miss: bool = false) -> void:
	note_mesh.visible = false
	collected = true

	if is_miss and beam != null:
		pass
	hit_feedback.emit(accuracy, line)


# Handle the area entered signal of the note.
func _on_area_entered(area: Area3D) -> void:
	if collected:
		return
	var area_groups: Array[String] = ["perfect_area", "verygood_area", "good_area", "bad_area", "miss_area"]
	var area_accuracy: Array[int]  = [1, 2, 3, 4, 5]
	
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
		var continued_feedback: Callable = note_picker.hit_continued_feedback
		
		var _1: int = hit_feedback.connect(feedback)
		var _2: int = hit_feedback.connect(continued_feedback)
		
