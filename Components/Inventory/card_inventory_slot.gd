extends TextureRect

signal data_card(card_data: Dictionary)

@onready var button: Button = %Button

var cards_data: Dictionary = {}


func slot_data(card_data: Dictionary = {}) -> Dictionary:
	if !card_data.is_empty():
		var uri: String = card_data.keys()[0]
		card_data["node_name"] = get_parent().get_name()
		card_data["origin_node"] = self
		card_data["origin_panel"] = "CardInventory"
		card_data["origin_item_id"] = uri
		card_data["card_id"] = card_data[uri].id
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
	else:
		card_data["node_name"] = get_parent().get_name()
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

	cards_data = card_data
	return cards_data as Dictionary
	
	
func equip_to_equip_slot() -> void:
	var _card_data: Dictionary = slot_data({})
	
	
func unequip_from_equip_slot(card_data: Dictionary, equip_slot_texture: Texture) -> void:
	var _inv_slot: String = get_parent().name
	texture = equip_slot_texture
	var _card: Dictionary = slot_data(card_data)
	
	get_parent().visible = true
	
	
func _on_button_pressed() -> void:
	data_card.emit(cards_data, self)
	
	
func filter_cards() -> void:
	pass
