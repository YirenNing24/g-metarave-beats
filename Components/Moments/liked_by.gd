extends Control

var liker_slot_scene: PackedScene = preload("res://Components/Moments/liker_slot.tscn")


func populate_likers(profile_pics: Array) -> void:
	var liker_slot: Control
	for picture: Dictionary in profile_pics:
		
		liker_slot = liker_slot_scene.instantiate()
		liker_slot.slot_data(picture, "FanMoments")
		
	%LikeContainer.add_child(liker_slot)
	visible = true

func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if visible:
			visible = false
		
func _on_visibility_changed() -> void:
	if visible == false:
		for liker: Control in %LikeContainer.get_children():
			liker.queue_free()
