extends TextureRect

signal data_card(card_data: Dictionary)

@onready var button: Button = %Button

var card_datas: Dictionary = {}


func slot_data(card_data: Dictionary) -> Dictionary:
	var uri: String = card_data.keys()[0]
	card_data["node_name"] = get_parent().get_name()
	card_data["origin_node"] = self
	card_data["origin_panel"] = "CardInventory"
	card_data["origin_item_id"] = uri
	card_data["origin_equipment_slot"] = card_data[uri].slot
	
	card_data["Name"] = card_data[uri].name
	card_data["Description"] = card_data[uri].description
	card_data["Group"] = card_data[uri].group
	card_data["Position"] = card_data[uri].position
	card_data["Position2"] = card_data[uri].position2
	card_data["Skill"] = card_data[uri].skill
	card_data["Era"] = card_data[uri].era
	card_data["Breakthrough"] = card_data[uri].breakthrough
	
	card_data["Rarity"] = card_data[uri].rarity
	card_data["Level"] = card_data[uri].level
	card_data["Experience"] = card_data[uri].experience

	card_data["Scoreboost"] = card_data[uri].scoreboost
	card_data["Healboost"] = card_data[uri].healboost
	card_data["BoostCount"] = card_data[uri].boostCount
	card_data["AwakenCount"] = card_data[uri].awakenCount

	card_data["Tier"] = card_data[uri].tier
	card_data["Stars"] = card_data[uri].stars
	card_data["origin_texture"] = texture
	
	if card_data.is_empty():
		card_data["node_name"] = get_parent().get_name()
		card_data["origin_node"] = self
		card_data["origin_panel"] = "CardInventory"

		card_data["Name"] = null
		card_data["Group"] = null
		card_data["Position"] = null
		card_data["Position2"] = null
		card_data["Skill"] = null
		card_data["Era"] = null
		card_data["Breakthrough"] = null
		
		card_data["Rarity"] = null
		card_data["Level"] = null
		card_data["Experience"] = null
		card_data["Experience_required"] = null
		card_data["Scoreboost"] = null
		card_data["Healboost"] = null
		card_data["BoostCount"] = null
		card_data["AwakenCount"] = null
		
		card_data["Tier"] = null
		card_data["origin_texture"] = null
			
		get_parent().visible = false
		card_datas = card_data
		return card_datas as Dictionary
	
	card_datas = card_data
	return card_datas as Dictionary
	
func equip() -> Dictionary:
	#BKMREngine.Inventory.card_inventory.inventoryCard[inv_slot]["Item"] = null
	
	var card_inventory: Dictionary = BKMREngine.Inventory.card_inventory
	var _card_data: Dictionary = slot_data(card_inventory)
	
	return card_inventory as Dictionary
	
func unequip_from_card_slot(item_id: String, equip_slot_texture: Texture) -> void:
	var inv_slot: String = get_parent().name
	BKMREngine.Inventory.card_inventory.inventoryCard[inv_slot]["Item"] = item_id
	
	var card_inventory: Dictionary = BKMREngine.Inventory.card_inventory
	var _card_data: Dictionary = slot_data(card_inventory)
	texture = equip_slot_texture
	get_parent().visible = true
	
func _on_button_pressed() -> void:
	data_card.emit(card_datas)

func filter_cards() -> void:
	pass
