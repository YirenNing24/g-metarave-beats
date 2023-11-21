extends Node3D

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
		else:
			is_pressed = false
			is_collecting = false
			note_collect = null

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
# Returns:
# - A Vector2 representing the screen space position of the notepicker.
#
# Example usage:
# ```gdscript
# var picker_position: Vector2 = notepicker_3d_pos()
# ```
func notepicker_3d_pos() -> Vector2:
	# Get the 3D position of the notepicker in screen space.
	var camera: Camera3D = get_viewport().get_camera_3d()
	var picker_position: Vector2 = camera.unproject_position(position)
	return picker_position
