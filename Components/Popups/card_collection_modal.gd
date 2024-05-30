extends Control

var x_in: Array = ["Nova No Doubt Star", "Esha No Doubt Star", "Hannah No Doubt Star", "Aria No Doubt Star", "Nizz No Doubt Star"]


var card_collection_slot_scene: PackedScene = preload("res://Components/MyProfile/card_collection_slot.tscn")

@onready var card_artist_modal: Control = $CardArtistModal
@onready var genesis_container: GridContainer = %GenesisContainer


func load_card_collection(group: String, card_collection: Array) -> void:
	var card_collection_slot: Control
	var group_name: String = group.to_lower().replace(":", "_").replace(" ", "_")
	for card: Dictionary in card_collection:
		card_collection_slot = card_collection_slot_scene.instantiate()
		var modulate_card: bool = true  # Assume the card needs to be modulated
		for member_name: String in get(group_name):
			if card.name == member_name:
				modulate_card = false  # Card name found in member_name, no modulation needed
				break
		if modulate_card:
			card_collection_slot.modulate = Color(1, 1, 1, 0.298)  # ffffff4c in RGBA (white with 30% opacity)
			
		# Add card_collect_slot to the scene or to a parent node
		card_collection_slot.set_collection_card_data(card)
		card_collection_slot.card_collection_button_pressed.connect(_on_card_collection_slot_pressed)
		genesis_container.add_child(card_collection_slot)
	visible = true

func _on_card_collection_slot_pressed(card_data: Dictionary) -> void:
	card_artist_modal.card_data(card_data)

func _on_close_button_pressed() -> void:
	visible = false
	for card: Control in genesis_container.get_children():
		card.queue_free()
