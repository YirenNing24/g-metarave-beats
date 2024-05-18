extends Control


func load_card_collection(group: String, _card_collection: Array) -> void:
	print(group)
	visible = true

func _on_close_button_pressed() -> void:
	visible = false
