extends Node3D


signal hit_continued_feedback(accuracy: int, line: int)
signal hit_feedback(accuracy: int, line: int)
# Mesh instance representing the visual body of the note.
@onready var note_body: MeshInstance3D = get_node("NoteMesh/NoteBody")
# Area3D representing the collision area of the note.
@onready var note_area: Area3D = %NoteArea
# Node3D representing the beam visual effect of the note.
@onready var beam: Node3D = %Beam
# Node3D representing the entire note mesh.
@onready var note_mesh: Node3D = %NoteMesh
@onready var collision_shape: CollisionShape3D = %CollisionShape3D

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
var note_name: String = "slanted_long_note"

var note_position2: int
var bar2: int


func _ready() -> void:
	set_note_position() 
	note_area.add_to_group("note")
	var _note_connect: int = note_area.area_entered.connect(_on_area_entered)
	
	curr_length_in_m = max(100, length - 100) * 10
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
	
# Handle the process logic for the note.
func _process(delta: float) -> void:
	# Check if the picker is present or if the current note is being collected by another picker.
	if not picker or (picker.note_collect != null and picker.note_collect != self): 
		return

	# Check if the note is colliding.
	if is_colliding:
		# Check if the picker is collecting the note and the note has not been collected.
		if picker.is_collecting and not collected:
			print("yes1")
			collect()
			hold_started = true
			picker.note_collect = self
		# Check if the picker stopped collecting and the hold was started and the note has been collected.
		elif not picker.is_collecting and hold_started and collected:
			hold_canceled = true
			picker.note_collect = null
			picker.is_collecting = false
	else:
		# If the hold was started and not canceled, trigger long_note_hold.
		if hold_started and not hold_canceled:
			long_note_hold()
			hold_canceled = true  # Ensure it's only triggered once.

	# Check if the hold is started and not canceled.
	if hold_started and not hold_canceled:
		print("yes2")
		# Update the current length of the note.
		curr_length_in_m -= speed.z * delta
		note_collecting = true

		#beam.scale.z -= delta
		# Check if the note is still collecting and the current length is greater than 0.
		if note_collecting and curr_length_in_m > 0:
			# Update the time and trigger the long note hold if the time delay is reached.
			time += delta
			if time > time_delay:
				long_note_hold()
				time = 0
		else:
			note_collecting = false
# Handle the continued holding of a long note.
func long_note_hold() -> void:
	print(accuracy)
	hit_continued_feedback.emit(accuracy, line)
	# ui.hit_continued_feedback(accuracy, line)

# Collect the note and provide feedback.
func collect(is_miss: bool = false) -> void:
	#note_mesh.visible = false
	collected = true

	if is_miss and beam != null:
		pass
	hit_feedback.emit(accuracy, line)
		# "%Beam".get_node("Particles").hide()

	# ui.hit_feedback(accuracy, line)
	# ui.add_score()

# Handle the area entered signal of the note.
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

func draw_beam(bar_position: int, beam_layer: int, parent_note_position: int) -> void:
	var point1: Vector3 = Vector3(bar_position, beam_layer, parent_note_position)
	var point2: Vector3 = %NoteMesh.global_position
	#Draw a line from the position of the last point placed to the position of the second to last point placed
	var _line: MeshInstance3D = await path_line(point1, point2)


func path_line(pos1: Vector3, pos2: Vector3, color: Color = Color.WHITE_SMOKE, persist_ms: float = 0) -> MeshInstance3D:
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	var immediate_mesh: ImmediateMesh = ImmediateMesh.new()
	var material: ORMMaterial3D = ORMMaterial3D.new()

	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	immediate_mesh.surface_add_vertex(pos1)
	immediate_mesh.surface_add_vertex(pos2)
	immediate_mesh.surface_end()

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color

	return await final_cleanup(mesh_instance, persist_ms) as MeshInstance3D
	
## 1 -> Lasts ONLY for current physics frame
## >1 -> Lasts X time duration.
## <1 -> Stays indefinitely
func final_cleanup(mesh_instance: MeshInstance3D, persist_ms: float) -> MeshInstance3D:
	add_child(mesh_instance)
	if persist_ms == 1:
		await get_tree().physics_frame
		mesh_instance.queue_free()
	elif persist_ms > 0:
		await get_tree().create_timer(persist_ms).timeout
		mesh_instance.queue_free()
	else:
		return mesh_instance as MeshInstance3D
	return mesh_instance as MeshInstance3D
