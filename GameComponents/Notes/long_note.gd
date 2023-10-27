extends Node3D

@onready var note_body: MeshInstance3D = get_node("NoteMesh/NoteBody")
@onready var note_area: Area3D = %NoteArea
@onready var beam: Node3D = %Beam
@onready var note_mesh: Node3D = %NoteMesh

var line: int
var layer: float
var note_position: int = 0
var length: int
var length_scale: float
var speed: Vector3
var accuracy: int
var multiplier: int = 1

var is_colliding: bool = false
var collected: bool = false
var picker: Node3D = null
var concurrent: Array = []

var curr_length_in_m: float
var hold_started: bool = false
var hold_canceled: bool = false
var note_collecting: bool = false
var time_delay: float = 0.1
var time: float = 0
var hold: int = 0
var captured: bool = false
var note_name: String = "long_note"

func _ready() -> void:
	set_note_position() 
	note_area.add_to_group("note")
	var _note_connect: int = note_area.area_entered.connect(_on_area_entered)
	
	curr_length_in_m = max(100, length - 100) * length_scale
	beam.scale.z = curr_length_in_m
	
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
	position = Vector3( z, layer , -note_position * length_scale )
	
func _process(_delta: float) -> void:
	if not picker or (picker.note_collect != null and picker.note_collect != self): 
		return
		
	if is_colliding and not hold_canceled:
		if picker.is_collecting and not collected:
			collect()
			hold_started = true
			picker.note_collect = self
		elif !picker.is_collecting and hold_started and collected:
			hold_canceled = true
			picker.note_collect = null
			picker.is_collecting = false
			#$"%Beam".get_node("Particles").hide()
	if hold_started and not hold_canceled:
		curr_length_in_m -= speed.z * _delta
		note_collecting = true
		if note_collecting == true and curr_length_in_m > 0:
			time += _delta
			if time > time_delay:
				long_note_hold()
				time = 0
		else:
			note_collecting = false

func long_note_hold() -> void:
	print(accuracy)
	pass
	#ui.hit_continued_feedback(accuracy, line)
	
func collect(is_miss: bool = false) -> void:
	note_mesh.visible = false
	collected = true

	if is_miss and beam != null:
		pass
		#$"%Beam".get_node("Particles").hide()
	#ui.hit_feedback(accuracy, line)
	#ui.add_score()
	
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
