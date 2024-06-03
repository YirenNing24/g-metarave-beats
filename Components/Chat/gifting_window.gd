extends Control

signal gift_card_data(card_data: Dictionary)

var card_inventory_slot_scene: PackedScene = preload("res://Components/Inventory/card_inventory_slot.tscn")

@onready var loading_panel: Panel = %FilterPanel2

@onready var yes_button: TextureButton = %YesButton
@onready var no_button: TextureButton = %NoButton
@onready var filter_panel: Panel = %FilterPanel

var picked_card: Dictionary

func _ready() -> void:
	connect_signal()
	BKMREngine.Inventory.open_card_inventory()
	
func connect_signal() -> void:
	BKMREngine.Inventory.get_card_inventory_complete.connect(_card_inventory_open)
	BKMREngine.Social.gift_card_complete.connect(_on_gift_card_complete)

func _on_visibility_changed() -> void:
	if visible:
		BKMREngine.Inventory.open_card_inventory()

func _card_inventory_open(inventory_data: Array) -> void:
	for card: Control in %CardsContainer.get_children():
		card.queue_free()
	var card_inventory_slot: Control
	for card_data: Dictionary in inventory_data[0]:
		card_inventory_slot = card_inventory_slot_scene.instantiate()
		var uri: String = card_data.keys()[0]

		var card_name: String = card_data[uri]["name"].replace(" ", "_").to_lower()
		var card_texture: Texture = load("res://UITextures/Cards/" + card_name + ".png")
		
		card_inventory_slot.get_node('CardIcon').set_texture(card_texture)
		%CardsContainer.add_child(card_inventory_slot)
		%CardsContainer.move_child(card_inventory_slot, 0)
		
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
	loading_panel.fake_loader()
	
	var uri: String = picked_card.keys()[0]
	var gift_data: Dictionary = {
		"cardName": picked_card[uri].name,
		"id": picked_card[uri].id,
	}
	gift_card_data.emit(gift_data)

func _on_gift_card_complete(_message: Dictionary) -> void:
	loading_panel.tween_kill()
	
func _on_close_button_pressed() -> void:
	visible = false
