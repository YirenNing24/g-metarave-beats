extends Control



var card_upgrade_slot_data: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var button: TextureButton = get_node("Button")
	var _connect: int = button.pressed.connect(_on_button_pressed)

func slot_data(card_upgrade_data: Dictionary = {}) -> void:
	card_upgrade_data["Quantity"] = card_upgrade_data.supply

	card_upgrade_data["uri"] = card_upgrade_data.uri
	card_upgrade_data["tokenId"] = card_upgrade_data.tokenId
	card_upgrade_data["Tier"] = card_upgrade_data.metadata.tier
	card_upgrade_slot_data = card_upgrade_data
	set_texture()
	
	if !card_upgrade_data.is_empty():
		visible = true
		
func set_texture() -> void:
	var card_icon: TextureRect = get_node("Panel/CardIcon")
	card_icon.texture = card_upgrade_slot_data["Texture"]
	

func _on_button_pressed() -> void:
	if !card_upgrade_slot_data.is_empty():
		unequip_card_upgrade()
	
func unequip_card_upgrade() -> void:
	var quantity_label: Label = get_node("Quantity")
	var card_icon: TextureRect = get_node("Panel/CardIcon")
	for item: Control in get_tree().get_nodes_in_group("CardUpgradeItem"):
		var item_quantity_label: Label = item.get_node("Quantity")
		if item.visible == false:
			if item.upgrade_items_data.uri == card_upgrade_slot_data.uri:
				item.slot_data(card_upgrade_slot_data)
				item_quantity_label.text = quantity_label.text
				item.visible = true
				
				visible = false
				card_upgrade_slot_data = {}
				quantity_label.text = "0"
				card_icon.texture = null
				return
	
