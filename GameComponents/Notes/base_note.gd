extends Node3D

#var pink_mat: Resource = preload("res://note/note1TXT.tres")
#var yellow_mat: Resource  = preload("res://note/note2TXT.tres")
#var blue_mat: Resource  = preload("res://note/note3TXT.tres")
#var green_mat: Resource  = preload("res://note/note4TXT.tres")
#var purple_mat: Resource  = preload("res://note/note5TXT.tres")

@export_range(1, 5) var line: int

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

@onready var note_body: MeshInstance3D = get_node("NoteMesh/NoteBody")
@onready var note_area: Area3D = %NoteArea

func _ready() -> void:
	_on_ready()


func _on_ready()  -> void:
	set_note_position() 
	note_area.add_to_group("note")
	var _connect: int = note_area.area_entered.connect(_on_area_entered)
	
func _process(_delta: float) -> void:
	if not picker or (picker.note_collect != null and picker.note_collect != self): 
		return
	_on_process(_delta)
	
func _on_process(_delta: float) -> void:
	pass
	
func collect(is_miss: bool = false) -> void:
	note_body.visible = false
	collected = true
	picker.is_collecting = false
		
	if accuracy != 5:
		collected = true
		note_body.visible = false
#
	if not is_miss:
		picker.note_collect = self
		
	print(accuracy)
	#game_ui.hit_feedback(accuracy, line)
	#game_ui.add_score()
	
	
#func set_material():
#
	#match line:
		#1:
			#cover.material_override = pink_mat
		#2:
			#cover.material_override = yellow_mat
		#3:
			#cover.material_override = blue_mat
		#4:
			#cover.material_override = green_mat
		#5:
			#cover.material_override = purple_mat
#
func set_note_position() -> void:
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
			
	position = Vector3( z, 0 , -note_position * length_scale )
	
func _on_area_entered(area: Area3D) -> void:
	if collected:
		return
		
	if area.is_in_group("perfect_area"):
		accuracy = 1
		is_colliding = true
		picker = area.get_parent().get_parent()

	elif area.is_in_group("verygood_area"):
		accuracy = 2
		is_colliding = true
		picker = area.get_parent().get_parent()

	elif area.is_in_group("good_area"):
		accuracy = 3
		is_colliding = true
		picker = area.get_parent().get_parent()

	elif area.is_in_group("bad_area"):
		accuracy = 4
		is_colliding = true
		picker = area.get_parent().get_parent()
		
	elif area.is_in_group("miss_area"):
		accuracy = 5
		is_colliding = false
		picker = area.get_parent().get_parent()
		collect(true)
		
