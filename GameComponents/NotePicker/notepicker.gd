extends Node3D

var is_pressed: bool = false
var is_collecting: bool = false
var note_collect: Node3D = null
var note_name: String
var notepicker_position: Vector2

func _ready() -> void:
	set_process_input(true)
	notepicker_position = notepicker_3d_pos()
	
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			var position_event: Vector2 = event.position
			var touched_node: bool = get_touched_node(position_event)
			if touched_node != false:
				is_pressed = true
				is_collecting = true
		else:
			is_pressed = false
			is_collecting = false
			note_collect = null

func get_touched_node(touch_position: Vector2) -> bool:
	var picker_x: float = notepicker_position.x  # X-coordinate of the node
	var picker_y: float = notepicker_position.y  # Y-coordinate of the node
	
	# Check if the touch event is within the bounds of the node
	if touch_position.x >= picker_x - 167.0/2.0 and touch_position.x <= picker_x + 167.0/2.0 and touch_position.y >= picker_y - 167/2.0 and touch_position.y <= picker_y + 167/2.0:
		return true
	return false

func notepicker_3d_pos() -> Vector2:
	var camera: Camera3D = get_viewport().get_camera_3d()
	var picker_position: Vector2 = camera.unproject_position(position)
	return picker_position
