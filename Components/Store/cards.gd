extends Control

# Preload the store_item_modal scene.
var store_item_modal: PackedScene = preload("res://Components/Popups/store_item_modal.tscn")

# Dictionary to store card data.
var card_data: Dictionary = {}

# Onready variable for the icon TextureRect.
@onready var icon: TextureRect = %Icon

# Retrieve card data.
#
# Parameters:
# - data: A dictionary containing information about the card.
#
# Example usage:
# ```gdscript
# get_card_data(data)
# ```
func get_card_data(data: Dictionary) -> void:
	card_data = data

# Handle texture button press.
#
# This function is triggered when the texture button is pressed. It instantiates the store_item_modal,
# sets data and texture, and adds it to the store_screen node.
#
# Parameters:
# - No explicit parameters are passed to this function.
#
# Returns:
# - This function does not return a value; it operates by creating and adding the store_item_modal to the scene.
#
# Example usage:
# ```gdscript
# _on_texture_button_pressed()
# ```
func _on_texture_button_pressed() -> void:
	# Instantiate the store_item_modal
	var item_store_modal: Node = store_item_modal.instantiate()
	
	# Add the item_store_modal to the store_screen node
	get_node('/root/store_screen').add_child(item_store_modal)
	
	# Get the texture from the icon
	var texture: Texture = icon.texture
	
	# Set data and texture for the item_store_modal
	item_store_modal.set_data(card_data, texture)
