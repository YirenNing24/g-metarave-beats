extends Control

const pack_inventory_slot_scene: PackedScene = preload("res://Components/Inventory/pack_inventory_slot.tscn")

var pack_data: Dictionary


func _ready() -> void:
	connect_signals()
	BKMREngine.Inventory.open_card_pack_inventory()


func connect_signals() -> void:
	BKMREngine.Inventory.get_card_pack_inventory_complete.connect(_on_get_card_pack_inventory_complete)


func _on_get_card_pack_inventory_complete(card_pack_data: Array) -> void:
	var pack_inventory_slot: Control
	for card_pack: Dictionary in card_pack_data:
		pack_inventory_slot = pack_inventory_slot_scene.instantiate()
		
		pack_inventory_slot.pack_inventory_slot_data(card_pack)
		pack_inventory_slot.on_pack_inventory_button_pressed.connect(_on_pack_inventory_slot_pressed)
		
		%ItemContainer.add_child(pack_inventory_slot)


func _on_pack_inventory_slot_pressed(card_pack_data: Dictionary) -> void:
	pack_data = card_pack_data
	%FilterPanel.visible = true


func _on_yes_button_pressed() -> void:
	BKMREngine.Gacha.open_card_pack(pack_data)


func _on_no_button_pressed() -> void:
	%FilterPanel.visible = false
