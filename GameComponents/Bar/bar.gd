extends Node3D

# Preload the short_note_scene and long_note_scene scenes.
var short_note_scene: PackedScene = preload("res://GameComponents/Notes/short_note.tscn")
var long_note_scene: PackedScene = preload("res://GameComponents/Notes/long_note.tscn")
var short_swipe_note_scene: PackedScene = preload("res://GameComponents/Notes/swipe_note.tscn")

var note_scale: float
var bar_data: Array
var speed: Vector3
var bar_index: int

func _ready() -> void:
	add_notes()
	

# Add notes to the scene based on the provided bar_data.
func add_notes() -> void:
	# Iterate through the indexed `bar_data` to eliminate unnecessary variable assignments.
	for line: int in bar_data.size():
		var line_data: Dictionary = bar_data[line]
		# Check if "notes" exists and is non-empty before processing
		if line_data.has("notes") and not line_data.notes.is_empty():
			# Directly iterate over notes to reduce array access overhead
			for note_data: Dictionary in line_data.notes:
				add_note(line + 1, note_data)  # Use index directly to avoid extra variable


# Add an individual note to the scene.
func add_note(line: int, note_data: Dictionary) -> void:
	# Determine the appropriate scene based on note_data properties.
	var note_scene: PackedScene
	var note_length: int = note_data["len"]
	
	if note_length >= 400:
		note_scene = long_note_scene
	elif note_data.swipe == true:
		note_scene = short_swipe_note_scene
	else:
		note_scene = short_note_scene
		
	# Instantiate the note from the chosen scene.
	var note: Node3D = note_scene.instantiate()

	# Set note properties based on note_data.
	note.line = line  # 1 to 15
	
	# Check if the note_data has a 'layer' property and set it if present.
	if note_data.has("layer"):
		note.layer = note_data["layer"]
	
	# Set note position, length, length_scale, and speed properties.
	note.note_position = note_data["pos"]
	note.length = note_length
	note.length_scale = note_scale
	note.speed = speed
	
	# Check if note_data has 'uid' property and set it if present.
	if note_data.has("uid"):
		note.uid = note_data["uid"]
	
	# Add the note as a child of this node.
	add_child(note)
