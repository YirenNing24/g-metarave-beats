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
	# Set the position of the note and add it to the "note" group.
	set_note_position() 
	
	# Connect the _on_area_entered function to the area_entered signal.
	var _note_connect: int = note_area.area_entered.connect(_on_area_entered)
	
	# Calculate and set the current length of the note and update the beam scale.
	curr_length_in_m = max(100, length - 100) * length_scale
	beam.scale.z = curr_length_in_m
	
# Set the position of the note based on the specified line and layer.
func set_note_position() -> void:
	
	# Determine the z-coordinate based on the specified line.
	var z: float
	match line:
		1:
			z = -1.79
		2:
			z = -0.89
		3:
			z = 0
		4:
			z = 0.89
		5:
			z = 1.79
	
	# Set the position of the note in 3D space.
	position = Vector3(z, layer, -note_position * length_scale)
	#var position_abs: Vector3= position.abs()
	#print("long: ", position_abs)
	#print("global: ", global_position)

# Handle the process logic for the note.
func _process(delta: float) -> void:
	# Check if the picker is present or if the current note is being collected by another picker.
	if not picker or (picker.note_collect != null and picker.note_collect != self): 
		return

	# Check if the note is colliding.
	if is_colliding:
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
	else:
		# If the hold was started and not canceled, trigger long_note_hold.
		if hold_started and not hold_canceled:
			long_note_hold()
			hold_canceled = true  # Ensure it's only triggered once.

	# Check if the hold is started and not canceled.
	if hold_started and not hold_canceled:
		# Update the current length of the note.
		curr_length_in_m -= speed.z * delta
		note_collecting = true

		#beam.scale.z -= delta
		# Check if the note is still collecting and the current length is greater than 0.
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
	# ui.hit_continued_feedback(accuracy, line)

# Collect the note and provide feedback.
func collect(is_miss: bool = false) -> void:
	note_mesh.visible = false
	collected = true

	if is_miss and beam != null:
		pass
	hit_feedback.emit(accuracy, line)
		# "%Beam".get_node("Particles").hide()

	# ui.hit_feedback(accuracy, line)
	# ui.add_score()

# Handle the area entered signal of the note.
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
