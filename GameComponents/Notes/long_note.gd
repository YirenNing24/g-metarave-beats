# Node representing a long musical note in a 3D space.
extends Node3D

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
var note_name: String = "long_note"

# Initialize the note when ready.
func _ready() -> void:
	# Set the position of the note and add it to the "note" group.
	set_note_position() 
	note_area.add_to_group("note")
	
	# Connect the _on_area_entered function to the area_entered signal.
	var _note_connect: int = note_area.area_entered.connect(_on_area_entered)
	
	# Calculate and set the current length of the note and update the beam scale.
	curr_length_in_m = max(100, length - 100) * length_scale
	beam.scale.z = curr_length_in_m

# Set the position of the note based on the specified line and layer.
func set_note_position() -> void:
	var z: float
	
	# Determine the z-coordinate based on the specified line.
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
	
	# Set the position of the note in 3D space.
	position = Vector3(z, layer, -note_position * length_scale)


# Handle the process logic for the note.
# Parameters:
# - _delta: The time elapsed since the last frame.
#
# Example usage:
# ```gdscript
# func _process(_delta: float) -> void:
#     handle_note_process(_delta)
# ```
func _process(_delta: float) -> void:
	# Check if the picker is present or if the current note is being collected by another picker.
	if not picker or (picker.note_collect != null and picker.note_collect != self): 
		return
	
	# Check if the note is colliding and not canceled.
	if is_colliding and not hold_canceled:
		# Check if the picker is collecting the note and the note has not been collected.
		if picker.is_collecting and not collected:
			collect()
			hold_started = true
			picker.note_collect = self
		# Check if the picker stopped collecting and the hold was started and the note has been collected.
		elif not picker.is_collecting and hold_started and collected:
			hold_canceled = true
			picker.note_collect = null
			picker.is_collecting = false
	
	# Check if the hold is started and not canceled.
	if hold_started and not hold_canceled:
		# Update the current length of the note.
		curr_length_in_m -= speed.z * _delta
		note_collecting = true
		
		# Check if the note is still collecting and the current length is greater than 0.
		if note_collecting and curr_length_in_m > 0:
			# Update the time and trigger the long note hold if the time delay is reached.
			time += _delta
			if time > time_delay:
				long_note_hold()
				time = 0
		else:
			note_collecting = false


# Handle the continued holding of a long note.
#
# Example usage:
# ```gdscript
# long_note_hold()
# ```
func long_note_hold() -> void:
	print(accuracy)
	pass
	# ui.hit_continued_feedback(accuracy, line)

# Collect the note and provide feedback.
#
# Parameters:
# - is_miss: A boolean indicating whether the note was missed (default is false).
#
# Example usage:
# ```gdscript
# collect(true)
# ```
func collect(is_miss: bool = false) -> void:
	note_mesh.visible = false
	collected = true

	if is_miss and beam != null:
		pass
		# "%Beam".get_node("Particles").hide()

	# ui.hit_feedback(accuracy, line)
	# ui.add_score()

# Handle the area entered signal of the note.
#
# Parameters:
# - area: An Area3D representing the area entered.
#
# Example usage:
# ```gdscript
# func _on_area_entered(area: Area3D) -> void:
#     handle_area_entered(area)
# ```
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
