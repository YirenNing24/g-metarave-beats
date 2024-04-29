extends Node3D

# Preload the short_note_scene and long_note_scene scenes.
var short_note_scene: PackedScene = preload("res://GameComponents/Notes/short_note.tscn")
var long_note_scene: PackedScene = preload("res://GameComponents/Notes/long_note.tscn")
var long_note_slanted: PackedScene = preload("res://GameComponents/Notes/long_note_slanted.tscn")

var note_scale: float
var bar_data: Array
var speed: Vector3
var bar_index: int


func _ready() -> void:
	add_notes()

# Add notes to the scene based on the provided bar_data.
func add_notes() -> void:
	# Initialize line variable to represent the road lines.
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
func add_note(line: int, note_data: Dictionary) -> void:
	# Determine whether to use the short_note_scene or long_note_scene based on note_data length.
	var note_scene: PackedScene
	var note_data_length: int = note_data.len

	if note_data.has("slanted"):
		note_scene = long_note_slanted
	elif int(note_data_length) >= 400:
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
	if note_data.has("uid"):
		note.uid = note_data.uid
		
	# Add the note as a child of this node.
	add_child(note)
	
	if note_data.has('slanted'):
		note.next_slanted_note_uid = note_data.next_slanted_note_uid
	
#func get_slanted_note_position(bar_line: int) -> float:
	#
	## Determine the z-coordinate based on the specified line.
	#var z: float
	#match bar_line:
		#1:
			#z = 0.895
		#2:
			#z = 0.445
		#3:
			#z = 0
		#4:
			#z = -0.445
		#5:
			#z = -0.895
	#return z
