extends Control

signal card_upgrade_item_pressed(data: Dictionary)

var upgrade_items_data: Dictionary = {}


func _ready() -> void:
	$Button.pressed.connect(_on_button_pressed)
	
	
func slot_data(upgrade_item_data: Dictionary) -> void:
	upgrade_item_data["Texture"] = %CardIcon.texture
	upgrade_item_data["Quantity"] = upgrade_item_data.quantityOwned
	upgrade_item_data["uri"] = upgrade_item_data.metadata.uri
	upgrade_item_data["tokenId"] = upgrade_item_data.metadata.id
	upgrade_item_data["Tier"] = upgrade_item_data.metadata.tier

	upgrade_items_data = upgrade_item_data
	set_label() 
	
func set_label() -> void:
	%Quantity.text = str(upgrade_items_data["Quantity"])
	
	
func _on_button_pressed() -> void:
	on_pressed()
	
	
func on_pressed() -> void:
	@warning_ignore("unsafe_call_argument")
	var current_value: int = int($Quantity.text)
	var new_value: String = str(current_value - 1)
	card_upgrade_item_pressed.emit(upgrade_items_data)
	if new_value == "0":
		visible = false
		return
	$Quantity.text = new_value
	
	
#func card_equipped(equipped: bool) -> void:
	#is_equipped = equipped
	#if is_equipped:
		#modulate = "ffffff"
	#else:
		#modulate = "626262"
