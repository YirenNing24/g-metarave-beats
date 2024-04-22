extends Control


signal show_item_store_modal(card_data: Dictionary, texture: Texture)

# Preload the store_item_modal scene.
var store_item_modal: PackedScene = preload("res://Components/Popups/store_item_modal.tscn")
@onready var card_button: TextureButton = %CardButton

# Onready variable for the icon TextureRect.
@onready var icon: TextureRect = %Icon

# Retrieve card data.
func get_card_data(card_data: Dictionary) -> void:
	var _connect: int = card_button.pressed.connect(_on_card_button_pressed.bind(card_data))
	
# Handle texture button press.
func _on_card_button_pressed(card_data: Dictionary) -> void:
	show_item_store_modal.emit(card_data, icon.texture)
