extends Node3D


signal position_notepicker(pos: float)


@export var line: int

@onready var fx_spinner: AnimatedSprite3D = $FXSpinner
@onready var fx_highlight: MeshInstance3D = $FXHighLight
@onready var fx_light_pillar: AnimatedSprite3D = $FXLightPillar
@onready var fx_spark: GPUParticles3D = $FXSpark


var note_collect: Node3D = null
var note_name: String
var notepicker_position: Vector2
var combo: int = 0

@export var touch_position: Vector2 = Vector2.ZERO
@export var is_pressed: bool = false
@export var is_collecting: bool = false
@export var is_swiping: bool = false

var peer_id: int


func _ready() -> void:
	set_process_input(true)
	notepicker_position = notepicker_3d_pos()
	position_notepicker.emit(notepicker_position.y)
	
	
func set_peer_id(_id_peer: int) -> void:
	set_multiplayer_authority(1)


func _process(_delta: float) -> void:
	if is_collecting == false:
		fx_spinner.visible = false
	
	
@rpc
func _server_input(pos: Vector2, pressed: bool) -> void:
	# Handle the input on the server side
	print("Input received from client: ", pos, pressed)
	# You can add server-side logic here
	
	
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_position = event.position
			var _r: Error = rpc_id(1, "_server_input", touch_position, true)
			var touched_node: bool = get_touched_node(touch_position)
			if touched_node:
				is_pressed = true
				is_collecting = true
				fx_highlight.visible = true
				# Synchronize with server
		else:
			is_pressed = false
			is_swiping = false
			is_collecting = false
			note_collect = null
			fx_highlight.visible = false
			# Synchronize with server
			var _r: Error = rpc_id(1, "_server_input", touch_position, false)
	if event is InputEventScreenDrag:
		touch_position = event.position
		var touched_node: bool = get_touched_node(touch_position)
		if touched_node:
			is_swiping = true
			is_pressed = true
			is_collecting = true
			fx_highlight.visible = true
			# Synchronize with server
		else:
			is_swiping = false
			is_pressed = false
			is_collecting = false
			note_collect = null
			fx_highlight.visible = false
			# Synchronize with server
			var _r: Error = rpc_id(1, "_server_input", touch_position, false)
	
	
func get_touched_node(touch_pos: Vector2) -> bool:
	var picker_x: float = notepicker_position.x
	var picker_y: float = notepicker_position.y

	if touch_pos.x >= picker_x - 83.5 and touch_pos.x <= picker_x + 83.5 and touch_pos.y >= picker_y - 83.5 and touch_pos.y <= picker_y + 83.5:
		return true
	return false
	
	
func notepicker_3d_pos() -> Vector2:
	var camera: Camera3D = get_viewport().get_camera_3d()
	var picker_position: Vector2 = camera.unproject_position(position)
	return picker_position
	
	
func hit_feedback(_note_accuracy: int, short_line: int) -> void:
	if line == short_line:
		# Check if note_accuracy is neither 4-bad nor 5-miss
		if combo <= 20:
			emit_spark()
		if combo % 10 == 0:
			emit_light_pillar()
	
	
func combo_value(value: String ) -> void:
	combo = value.to_int()
	
	
func hit_continued_feedback(_note_accuracy: int, long_line: int) -> void:
	if line == long_line:
		fx_spinner.visible = true
		fx_spinner.play()
	
	
func emit_spark() -> void:
	fx_spark.emitting = true
	
	
func emit_light_pillar() -> void:
	fx_light_pillar.play()
	
	
func _on_fx_light_pillar_animation_finished() -> void:
	fx_light_pillar.frame = 0
	
	
@rpc
func hit_feedback_short(note_accuracy: int, short_line: int) -> void:
	hit_feedback(note_accuracy, short_line)
	
	
@rpc
func hit_feedback_long(note_accuracy: int, short_line: int) -> void:
	hit_continued_feedback(note_accuracy, short_line)
