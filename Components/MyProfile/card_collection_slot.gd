extends Control

var collection_card_data: Dictionary

signal card_collection_button_pressed(data: Dictionary)

func set_collection_card_data(card_data: Dictionary) -> void:
	collection_card_data = card_data
	set_display()

func set_display() -> void:
		var card_name: String = collection_card_data["name"].replace(" ", "_").to_lower()
		var card_texture: Texture = load("res://UITextures/Cards/" + card_name + ".png")
		%CardIcon.texture = card_texture
		%CardOwnedCount.text = "Owned: " + str(collection_card_data.count)
		
func _on_card_collection_button_pressed() -> void:
	card_collection_button_pressed.emit(collection_card_data)
