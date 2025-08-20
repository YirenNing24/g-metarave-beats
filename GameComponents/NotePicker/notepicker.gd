extends Node3D

signal position_notepicker(pos: float)

@export var line: int

@onready var fx_spinner: AnimatedSprite3D = $FXSpinner
@onready var fx_highlight: MeshInstance3D = $FXHighLight
@onready var fx_light_pillar: AnimatedSprite3D = $FXLightPillar
@onready var fx_spark: GPUParticles3D = $FXSpark

var note_collect: Node3D = null
var notepicker_position: Vector2
var combo: int = 0

var touch_positions: Dictionary = {}  # Store multiple touch points
var is_collecting: bool = false
var is_swiping: bool = false

var base_state: Dictionary[int, Vector2] = {}  # Stores initial touch positions
var curr_state: Dictionary[int, Vector2] = {}  # Stores ongoing touch positions

var active_touches: Dictionary = {}  # Dictionary to track which touch belongs to this instance

func _ready() -> void:
	set_process_input(true)
	notepicker_position = notepicker_3d_pos()
	position_notepicker.emit(notepicker_position.y)
	
	
func _physics_process(_delta: float) -> void:
	# If no touches for this instance, stop effects
	if active_touches.is_empty():
		is_collecting = false
		fx_spinner.visible = false
		
		
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			# Check if touch is inside this notepicker
			@warning_ignore("unsafe_call_argument")
			if get_touched_node(event.position):
				base_state[event.index] = event.position
				curr_state[event.index] = event.position
				active_touches[event.index] = true  # Track this touch for this instance
				is_collecting = true
				fx_highlight.visible = true
		else:
			# Remove touch only if it belongs to this instance
			if active_touches.has(event.index):
				var _j: bool = base_state.erase(event.index)
				var _k: bool = curr_state.erase(event.index)
				var _l: bool = active_touches.erase(event.index)

			# If no more touches left in this instance, reset states
			if active_touches.is_empty():
				is_collecting = false
				is_swiping = false
				note_collect = null
				fx_highlight.visible = false
				fx_spinner.visible = false  # Ensure spinner stops too
				
	elif event is InputEventScreenDrag:
		if curr_state.has(event.index):
			curr_state[event.index] = event.position
			@warning_ignore("unsafe_call_argument")
			if get_touched_node(event.position):
				is_swiping = true
				is_collecting = true
				fx_highlight.visible = true
			else:
				is_swiping = false
				is_collecting = false
				fx_highlight.visible = false
	
func get_touched_node(touch_pos: Vector2) -> bool:
	var picker_x: float = notepicker_position.x
	var picker_y: float = notepicker_position.y

	# Touch sensitivity
	var x_range: float = 83.5
	var y_range: float = 170

	return (touch_pos.x >= picker_x - x_range and touch_pos.x <= picker_x + x_range 
		and touch_pos.y >= picker_y - y_range and touch_pos.y <= picker_y + y_range)
	
	
# Get the 3D position of the notepicker in screen space.
func notepicker_3d_pos() -> Vector2:
	var camera: Camera3D = get_viewport().get_camera_3d()
	return camera.unproject_position(position)
	
	
func hit_feedback(_note_accuracy: int, short_line: int) -> void:
	if _note_accuracy == 5:
		pass
		#Input.vibrate_handheld(300)
		return  # Exit early to prevent other effects from triggering
	
	if line == short_line:
		# Emit spark if combo <= 20 or combo is in certain ranges (excluding accuracy 5)
		if combo <= 20 or combo % 10 == 0:
			emit_spark()

		# Emit light pillar for combos that are multiples of 10
		if combo % 10 == 0 and combo != 0:
			emit_light_pillar()

		# Handle FXGlobe animations based on combo ranges
		var combo_thresholds: Dictionary[int, String] = {
			20: "combo20",
			30: "combo30",
			40: "combo40",
			50: "combo50"  # Trigger combo50 for 50 and above
		}

		for threshold: int in combo_thresholds.keys():
			if (combo >= threshold and combo < threshold + 10) or (threshold == 50 and combo >= 50):
				emit_spark()
				%FXGlobe.visible = true
				%FXGlobe.play(combo_thresholds[threshold])
				break
	
	
# Handles feedback for continued collection of long notes.
func hit_continued_feedback(note_accuracy: int, note_line: int) -> void:
	if note_accuracy != 5:
		if note_line == line and is_collecting:
			fx_spinner.play('vortex')
			fx_highlight.visible = false
		else:
			fx_spinner.stop()
			fx_spinner.frame = 0
	

func combo_value(value: int) -> void:
	combo = value
	
	
func emit_spark() -> void:
	fx_spark.emitting = true
	
	
func emit_light_pillar() -> void:
	fx_light_pillar.visible = true
	fx_light_pillar.play()
	fx_light_pillar.frame = 0
	
	
func _on_fx_light_pillar_animation_finished() -> void:
	fx_light_pillar.frame = 0
	
	
func _on_fx_globe_animation_finished() -> void:
	%FXGlobe.frame = 0
	
