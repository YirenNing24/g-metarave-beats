extends TextureRect

signal data_card(card_data: Dictionary)

@onready var button: Button = %Button

var card_datas: Dictionary = {}


func slot_data(card_data: Dictionary) -> Dictionary:
	card_data["node_name"] = get_parent().get_name()
	card_data["origin_node"] = self
	card_data["origin_panel"] = "CardInventory"
	card_data["origin_item_id"] = card_data.uri
	card_data["origin_equipment_slot"] = card_data.slot
	
	card_data["Name"] = card_data.name
	card_data["Description"] = card_data.description
	card_data["Group"] = card_data.group
	card_data["Position"] = card_data.position
	card_data["Position2"] = card_data.position2
	card_data["Skill"] = card_data.skill
	card_data["Era"] = card_data.era
	card_data["Breakthrough"] = card_data.breakthrough
	
	card_data["Rarity"] = card_data.rarity
	card_data["Level"] = card_data.level
	card_data["Experience"] = card_data.experience

	card_data["Scoreboost"] = card_data.scoreBoost
	card_data["Healboost"] = card_data.healBoost
	card_data["BoostCount"] = card_data.boostCount
	card_data["AwakenCount"] = card_data.awakenCount

	card_data["Tier"] = card_data.tier
	card_data["Stars"] = card_data.stars
	card_data["origin_texture"] = texture
		
	if card_data.is_empty():
		card_data["node_name"] = get_parent().name
		card_data["origin_node"] = self
		card_data["origin_panel"] = "CardInventory"
		card_data["origin_item_id"] = null
		card_data["origin_equipment_slot"] = null
		
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
		return card_datas as Dictionary
		
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
