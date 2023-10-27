extends Node3D

var short_note_scene: PackedScene = preload("res://GameComponents/Notes/short_note.tscn")
var long_note_scene: PackedScene = preload("res://GameComponents/Notes/long_note.tscn")

var note_scale: float
var bar_data: Array 
var speed: Vector3

func _ready() -> void:
	add_notes()

func add_notes() -> void:
	var line: int = 1
	for line_data: Dictionary in bar_data:
		var notes_data: Array = line_data.notes
		for note_data: Dictionary in notes_data:
			add_note(line, note_data)
		line += 1 
		
func add_note(line: int, note_data: Dictionary) -> void:
	var note_scene: PackedScene
	var note_data_length: int = note_data.len
	if int(note_data_length) >= 400:
		note_scene = long_note_scene
	else:
		note_scene = short_note_scene
		
	var note: Node3D = note_scene.instantiate()
	note.line = line # 1 2 3 4 5
	
	if note_data.has('layer'):
		note.layer = note_data.layer
	var note_position: float = note_data.pos
	note.note_position = int(note_position)
	var note_length: float = note_data.len
	note.length = int(note_length)
	note.length_scale = note_scale
	note.speed = speed
	add_child(note)
