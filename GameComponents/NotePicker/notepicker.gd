extends Node3D

#TODO: Tapping by sliding should be allowed without lifting finger


@export var line: int

#region note picker effects
@onready var fx_spinner: AnimatedSprite3D =  %FXSpinner
@onready var fx_highlight: MeshInstance3D = %FXHighLight
@onready var fx_light_pillar: MeshInstance3D = %FXLightPillar
@onready var fx_spark: GPUParticles3D = %FXSpark
@onready var fx_god_ray: GPUParticles3D = %FXGodRay
#endregion

# Variable to track whether the screen is being touched.
var is_pressed: bool = false
# Variable to track whether the note is being collected.
var is_collecting: bool = false
# Node representing the collected note.
var note_collect: Node3D = null

# Name of the note.
var note_name: String

# Position of the notepicker in 3D space.
var notepicker_position: Vector2

func _ready() -> void:
	# Enable input processing for the node.
	set_process_input(true)
	
	# Get the initial position of the notepicker in 3D space.
	notepicker_position = notepicker_3d_pos()
	
	call_deferred('connect_notes') 

func _process(_delta: float) -> void:
	if is_collecting == false:
		fx_spinner.stop()
		fx_spinner.frame = 0
		
		await fx_spark.finished
		fx_spark.emitting = false

#func connect_notes() -> void:
	#for notes: Node3D in get_tree().get_nodes_in_group('ShortNote'):
		#notes.hit_feedback.connect(hit_feedback)
		#
	#for notes: Node3D in get_tree().get_nodes_in_group('LongNote'):
		#notes.hit_continued_feedback.connect(hit_continued_feedback)

# Handle screen touch events and update state variables.
# Parameters:
# - event: An InputEvent representing the input event.
#
# Example usage:
# ```gdscript
# func _input(event: InputEvent) -> void:
#     handle_touch_event(event)
# ```
func _input(event: InputEvent) -> void:
	# Handle screen touch events.
	if event is InputEventScreenTouch:
		if event.pressed:
			# Check if the touch event is within the bounds of the notepicker node.
			var position_event: Vector2 = event.position
			var touched_node: bool = get_touched_node(position_event)
			
			# Update state variables based on touch status.
			if touched_node != false:
				is_pressed = true
				is_collecting = true
				fx_highlight.visible = true
				
		else:
			is_pressed = false
			is_collecting = false
			note_collect = null
			fx_highlight.visible = false

			
# Check if a touch event is within the bounds of the notepicker node.
# Parameters:
# - touch_position: A Vector2 representing the screen space position of the touch event.
# Returns:
# - A boolean indicating whether the touch event is within the bounds of the notepicker node.
#
# Example usage:
# ```gdscript
# var is_touched: bool = get_touched_node(touch_position)
# ```
func get_touched_node(touch_position: Vector2) -> bool:
	# Check if the touch event is within the bounds of the notepicker node.
	var picker_x: float = notepicker_position.x
	var picker_y: float = notepicker_position.y
	
	if touch_position.x >= picker_x - 167.0/2.0 and touch_position.x <= picker_x + 167.0/2.0 and touch_position.y >= picker_y - 167/2.0 and touch_position.y <= picker_y + 167/2.0:
		return true
	return false
	
# Get the 3D position of the notepicker in screen space.
func notepicker_3d_pos() -> Vector2:
	# Get the 3D position of the notepicker in screen space.
	var camera: Camera3D = get_viewport().get_camera_3d()
	var picker_position: Vector2 = camera.unproject_position(position)
	return picker_position as Vector2

#func hit_feedback(note_accuracy: int, note_line: int) -> void:
	#if note_accuracy != 5:
		#if note_line == line:
			##fx_spark.emitting = true
			##fx_god_ray.emitting = true
			##fx_highlight.visible = false
		#else:
			#fx_spark.emitting = false
			#fx_god_ray.emitting = false
	
#func hit_continued_feedback(note_accuracy: int, note_line: int) -> void:
	#if note_accuracy != 5:
		#if note_line == line and is_collecting:
			#fx_spinner.play('vortex')
			#fx_highlight.visible = false
		#else:
			#fx_spinner.stop()
			#fx_spinner.frame = 0
#
#func combo_fx(_combo: int) -> void:
	##fx_light_pillar.visible = true
	#fx_spark.emitting = true
	
	#await get_tree().create_timer(0.4).timeout
	#fx_light_pillar.visible = false
