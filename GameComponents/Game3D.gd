extends Node


func draw_beam(bar_position: int, beam_layer: int, parent_note_position: int) -> void:
	var point1: Vector3 = Vector3(bar_position, beam_layer, parent_note_position)
	var point2: Vector3 = %NoteMesh.position.abs()
	#Draw a line from the position of the last point placed to the position of the second to last point placed
	var _line: MeshInstance3D = await path_line(point2, point1)


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
		return mesh_instance
	return mesh_instance
