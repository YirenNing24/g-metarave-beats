extends Node3D

# Preload the short_note_scene and long_note_scene scenes.
var short_note_scene: PackedScene = preload("res://GameComponents/Notes/short_note.tscn")
var long_note_scene: PackedScene = preload("res://GameComponents/Notes/long_note.tscn")

# Scale factor for the length of the notes.
var note_scale: float

# Array to store data for each musical bar.
var bar_data: Array

# Vector representing the speed of the notes in the 3D space.
var speed: Vector3

# Called when the node is ready.
func _ready() -> void:
	# Add musical notes to the scene.
	add_notes()

# Add musical notes to the scene based on the provided bar_data.
#
# This function iterates through each line's data in the bar_data array and adds individual notes to the scene.
#
# Parameters:
# - No explicit parameters are passed to this function.
#
# Example usage:
# ```gdscript
# add_notes()
# ```
func add_notes() -> void:
	# Initialize line variable to represent the musical staff lines.
	var line: int = 1
	
	# Iterate through each line's data in the bar_data array.
	for line_data: Dictionary in bar_data:
		# Get the notes data for the current line.
		var notes_data: Array = line_data.notes
		
		# Iterate through each note's data in the line.
		for note_data: Dictionary in notes_data:
			# Add the note to the scene.
			add_note(line, note_data)
		
		# Move to the next line.
		line += 1 

# Add an individual note to the scene.
#
# Parameters:
# - line: The musical staff line on which the note should be placed.
# - note_data: A dictionary containing information about the note.
#
# Example usage:
# ```gdscript
# add_note(line, note_data)
# ```
func add_note(line: int, note_data: Dictionary) -> void:
	# Determine whether to use the short_note_scene or long_note_scene based on note_data length.
	var note_scene: PackedScene
	var note_data_length: int = note_data.len
	if int(note_data_length) >= 400:
		note_scene = long_note_scene
	else:
		note_scene = short_note_scene
		
	# Instantiate the note from the chosen scene.
	var note: Node3D = note_scene.instantiate()
	
	# Set note properties based on note_data.
	note.line = line  # 1, 2, 3, 4, 5
	
	# Check if the note_data has a 'layer' property and set it if present.
	if note_data.has('layer'):
		note.layer = note_data.layer
	
	# Set note position, length, length_scale, and speed properties.
	var note_position: float = note_data.pos
	note.note_position = int(note_position)
	var note_length: float = note_data.len
	note.length = int(note_length)
	note.length_scale = note_scale
	note.speed = speed
	
	# Add the note as a child of this node.
	add_child(note)
