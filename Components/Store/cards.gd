extends Control
var store_item_modal:PackedScene = preload("res://Components/Popups/store_item_modal.tscn")

var card_data:Dictionary = {}
@onready var icon:TextureRect = %Icon


func get_card_data(data):
	card_data = data
	
	
func _on_texture_button_pressed():
	var item_store_modal:Node = store_item_modal.instantiate()
	get_node('/root/store_screen').add_child(item_store_modal)
	
	var texture:Texture = icon.texture
	item_store_modal.set_data(card_data, texture)

