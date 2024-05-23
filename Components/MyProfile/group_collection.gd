extends Control

signal on_open_collection_button_pressed(group: String)

var group: String


func _on_open_collection_button_pressed() -> void:
	on_open_collection_button_pressed.emit(group)
