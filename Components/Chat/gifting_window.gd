extends Control

var card_inventory_slot_scene: PackedScene = preload("res://Components/Inventory/card_inventory_slot.tscn")

@onready var loading_panel: Panel = %FilterPanel

@onready var card_inventory_container: GridContainer = %CardsContainer
@onready var yes_button: TextureButton = %YesButton
@onready var no_button: TextureButton = %NoButton
@onready var filter_panel: Panel = %FilterPanel

var picked_card: Dictionary

func _ready() -> void:
	BKMREngine.Inventory.get_card_inventory_complete.connect(card_inventory_open)
	BKMREngine.Inventory.open_card_inventory()

func _on_visibility_changed() -> void:
	if visible:
		pass
	else:
		for card: Control in card_inventory_container.get_children():
			card.queue_free()

func card_inventory_open(inventory_data: Array) -> void:
	var card_inventory_slot: Control
	for card_data: Dictionary in inventory_data[0]:
		card_inventory_slot = card_inventory_slot_scene.instantiate()
		var uri: String = card_data.keys()[0]

		var card_name: String = card_data[uri]["name"].replace(" ", "_").to_lower()
		var card_texture: Texture = load("res://UITextures/Cards/" + card_name + ".png")
		
		card_inventory_slot.get_node('CardIcon').set_texture(card_texture)
		card_inventory_container.add_child(card_inventory_slot)
		card_inventory_container.move_child(card_inventory_slot, 0)
		
		card_inventory_slot.get_node('CardIcon').slot_data(card_data)
		card_inventory_slot.get_node('CardIcon').data_card.connect(_on_inventory_card_pressed)

func _on_inventory_card_pressed(card_data: Dictionary, _card: Control) -> void:
	filter_panel.visible = true
	picked_card = card_data

func _on_filter_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if filter_panel.visible:
			filter_panel.visible = false

func _on_no_button_pressed() -> void:
	filter_panel.visible = false


func _on_yes_button_pressed() -> void:
	pass # Replace with function body.
