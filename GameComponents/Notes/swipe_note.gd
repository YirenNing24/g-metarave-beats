extends Node3D

signal hit_feedback(accuracy: int, line: int)
signal boost_feedback

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

var hold_started: bool = false
var hold_canceled: bool = false
var note_collecting: bool = true
var boost_applied: bool = false

var uid: int = -1

# Flag indicating whether the note is currently colliding with the picker.
var is_colliding: bool = false
# Flag indicating whether the note has been collected.
var collected: bool = false
# Reference to the picker (player) node that collects the note.
var picker: Node3D = null


func _ready() -> void:
	set_note_position()
	connect_notes()
	var _note_connect: int = note_area.area_entered.connect(_on_area_entered)
	set_note_position()
	
	
func connect_notes() -> void:
	for note_picker: Node3D in get_tree().get_nodes_in_group('Picker'):
		var feedback: Callable = note_picker.hit_feedback
		var _1: int = hit_feedback.connect(feedback)
	for user_hud: Control in get_tree().get_nodes_in_group("UserHUD"):
		var feedback: Callable = user_hud.hit_feedback
		var add_score: Callable = user_hud.add_score
		var boost: Callable = user_hud.boost_feedback
		var _1: int = hit_feedback.connect(feedback)
		var _2: int = hit_feedback.connect(add_score)
		var _3: int = boost_feedback.connect(boost)
	
	
func _process(_delta: float) -> void:
	# Check if the picker is present or if the current note is being collected by another picker.
	if not picker or (picker.note_collect != null and picker.note_collect != self):
		return

	# Handle note collision.
	if is_colliding:
		if picker.is_collecting and not collected:
			collect()
			hold_started = true
			picker.note_collect = self
		elif not picker.is_collecting and hold_started and collected:
			hold_canceled = true
			picker.note_collect = null
	else:
		# Trigger long_note_hold if the hold was started and not canceled.
		if hold_started and not hold_canceled:
			hold_canceled = true  # Ensure it's only triggered once.

	# Check if the hold is started and not canceled.
	if hold_started:
		note_collecting = true
		if picker.is_swiping and not boost_applied:
			note_collecting = is_inside_tree()
			swipe_boost()
	
func swipe_boost() -> void:
	boost_applied = true
	boost_feedback.emit(true)

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
	var z_values: Array[float] = [-1.79, -0.89, 0, 0.89, 1.79]
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
