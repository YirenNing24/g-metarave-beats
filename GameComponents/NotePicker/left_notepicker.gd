extends Node3D

@export var line: int

@onready var fx_spinner: AnimatedSprite3D =  $FXSpinner
@onready var fx_highlight: MeshInstance3D = $FXHighLight
@onready var fx_light_pillar: MeshInstance3D = $FXLightPillar
@onready var fx_spark: GPUParticles3D = $FXSpark

var is_pressed: bool = false
var is_collecting: bool = false
var note_collect: Node3D = null
var note_name: String
var notepicker_position: Vector2

func _ready() -> void:
	set_process_input(true)
	notepicker_position = notepicker_3d_pos()
	call_deferred('connect_notes') 

func _process(_delta: float) -> void:
	if is_collecting == false:
		fx_spinner.visible = false

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			var position_event: Vector2 = event.position
			var touched_node: bool = get_touched_node(position_event)
			if touched_node != false:
				is_pressed = true
				is_collecting = true
				fx_highlight.visible = true
		else:
			is_pressed = false
			is_collecting = false
			note_collect = null
			fx_highlight.visible = false
	if event is InputEventScreenDrag:
		var position_event: Vector2 = event.position
		var touched_node: bool = get_touched_node(position_event)
		if touched_node != false:
			is_pressed = true
			is_collecting = true
			fx_highlight.visible = true
		else:
			is_pressed = false
			is_collecting = false
			note_collect = null
			fx_highlight.visible = false

func get_touched_node(touch_position: Vector2) -> bool:
	if name == str(line):
		
		#var picker_x: float = notepicker_position.x
		var picker_y: float = notepicker_position.y
		
		# Check if touch position is within the y-axis bounds of the node pile
		if touch_position.y >= picker_y - 398:
			return true
			# Check if touch position is within the x-axis bounds of a single node
			#if touch_position.x >= picker_x - 38.5 and touch_position.x <= picker_x + 38.5:
				#return true
		
		return false
	return false

	
func notepicker_3d_pos() -> Vector2:
	var camera: Camera3D = get_viewport().get_camera_3d()
	var picker_position: Vector2 = camera.unproject_position(position)
	return picker_position as Vector2

func connect_notes() -> void:
	for notes: Node3D in get_tree().get_nodes_in_group('ShortNote'):
		notes.hit_feedback.connect(hit_feedback)
		
	for notes: Node3D in get_tree().get_nodes_in_group('LongNote'):
		notes.hit_continued_feedback.connect(hit_continued_feedback)
		notes.hit_feedback.connect(hit_feedback)
		
func hit_feedback(note_accuracy: int, short_line: int) -> void:
	if line == short_line:
		if note_accuracy == 1:
			fx_spark.emitting = true
	
func hit_continued_feedback(note_accuracy: int, long_line: int ) -> void:
	if line == long_line:
		if note_accuracy == 1 and is_collecting == true:
			fx_spinner.visible = true
			fx_spinner.play()
