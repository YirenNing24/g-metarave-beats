extends Control

signal loading_finished


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.





func _on_visibility_changed() -> void:
	if visible:
		pass
	else:
		pass


func _on_loading_finished() -> void:
	loading_finished.emit()
