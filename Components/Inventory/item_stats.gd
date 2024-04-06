extends Control

signal equip_unequip_pressed
signal close_item_stats_pressed

@onready var name_label: Label = %NameLabel
@onready var group_label: Label = %GroupLabel
@onready var position1_label: Label = %Position1Label
@onready var position2_label: Label = %Position2Label
@onready var scoreboost_label: Label = %ScoreboostLabel
@onready var healboost_label: Label = %HealboostLabel
@onready var tier_label: Label = %TierLabel
@onready var era_label: Label = %EraLabel
@onready var equip_label: Label = %EquipLabel

@onready var equipped_icon: TextureRect = %EquippedIcon
@onready var equip_unequip_button: TextureButton = %EquipUnequipButton
@onready var powerup_button: TextureButton = %PowerupButton
@onready var card_skill_button: TextureButton = %CardSkillButton
@onready var close_button: TextureButton = %CloseButton

var card_data: Dictionary
var is_open: bool = false

#region Set UI Variables
func _on_card_inventory_screen_item_stats_card_data(data_card: Dictionary) -> void:
	is_open = true
	card_data = data_card
	populate_card_labels()
	close_button.visible = true

func populate_card_labels() -> void:
	var origin_node: String = card_data["origin_panel"]
	if origin_node == "CardInventory":
		var card_name: String = card_data["Name"]
		var card_group: String = card_data["Group"]
		var card_position: String = card_data["Position"]
		var card_position2: String = card_data["Position2"]
		
		var card_scoreboost: String = card_data["Scoreboost"]
		var card_healboost: String = card_data["Healboost"]
		var card_tier: String = card_data["Tier"]
		var card_era: String = card_data["Era"]
		
		var card_texture: Texture = card_data["origin_texture"]
		
		set_labels(card_name, card_group, card_position, card_position2,
				   card_scoreboost, card_healboost, card_tier ,card_era,
				   card_texture)
		set_buttons(true, origin_node)
	elif origin_node == "CardSlot":
		if card_data["origin_item_id"] == null:
			var card_texture: Texture = card_data["origin_texture"]
			set_labels("", "", "", "", "", "", "", "", card_texture)
			set_buttons(false, origin_node)
		else:
			var card_name: String = card_data["Name"]
			var card_group: String = card_data["Group"]
			var card_position: String = card_data["Position"]
			var card_position2: String = card_data["Position2"]
			var card_scoreboost: String = card_data["Scoreboost"]
			var card_healboost: String = card_data["Healboost"]
			var card_tier: String = card_data["Tier"]
			var card_era: String = card_data["Era"]
			var card_texture: Texture = card_data["origin_texture"]
			set_labels(card_name, card_group, card_position, card_position2,
			   card_scoreboost, card_healboost, card_tier, card_era,
			   card_texture)
			set_buttons(true, origin_node)
			set_skill()
	
func set_labels(card_name: String, group: String, position1: String, position2: String,
				scoreboost: String, healboost: String, tier: String, era: String,
				texture: Texture) -> void:
					
	name_label.text = card_name
	group_label.text = group
	position1_label.text = position1
	position2_label.text = position2
	scoreboost_label.text = scoreboost
	healboost_label.text = healboost
	tier_label.text = tier
	era_label.text = era
	
	equipped_icon.texture = texture

func set_buttons(is_data: bool, origin: String) -> void:
	if origin == "CardSlot":
		if !is_data:
			equip_unequip_button.visible = false
			powerup_button.visible = false
		else:
			equip_unequip_button.visible = true
			equip_label.text = "Unequip"
			powerup_button.visible = true
			
	elif origin == "CardInventory":
		equip_unequip_button.visible = true
		equip_label.text = "Equip"
		powerup_button.visible = true

func _on_close_button_pressed() -> void:
	close_button.visible = false
	close_item_stats_pressed.emit()
	clear_variables()

func clear_variables() -> void:
	close_button.visible = false
	card_skill_button.texture_normal = null
#endregion

#region Item Equipped or Unequipped
func _on_equip_unequip_button_pressed() -> void:
	if card_data["origin_panel"] == "CardInventory":
		equip()
		equip_unequip_pressed.emit()
	elif card_data["origin_panel"] == "CardSlot":
		unequip()
	equip_unequip_pressed.emit()
	
func equip() -> void:
	var origin_node: TextureRect = card_data["origin_node"]
	var slots_name: String = card_data["Group"].capitalize() + "Slot"
	for slot: TextureRect in get_tree().get_nodes_in_group(slots_name):
		if slot.card_data["origin_equipment_slot"] == card_data["origin_equipment_slot"]:
			if slot.card_data["origin_item_id"] == null:
				var origin_item_id: String = origin_node.card_data["origin_item_id"]
				var inventory_data: Dictionary = await origin_node.equip()
				slot.equip(inventory_data, origin_item_id)
				
	is_open = true
	clear_variables()
	
func unequip() -> void:
	var slots_name: String = card_data["Group"].capitalize() + "Slot"
	for slot: TextureRect in get_tree().get_nodes_in_group(slots_name):
		if slot.card_data["origin_equipment_slot"] == card_data["origin_equipment_slot"]:
			slot.unequip()
	
	is_open = true
	clear_variables()
#endregion

#region Set Skill & Data
func set_skill() -> void:
	if card_data["Skill"] != null or "":
		var skill_name: String = card_data["Skill"].to_lower()
		var skill_texture: Texture = load("res://UITextures/Buttons/Skill/"+ skill_name + "_skill_texture" + ".png")
		card_skill_button.texture_normal = skill_texture
		card_skill_button.texture_pressed = skill_texture
		
		if card_data["SkillEquipped"] == false:
			card_skill_button.modulate = Color(1, 1, 1, 0.435)
			card_skill_button.button_pressed = false
		else:
			card_skill_button.modulate = "ffffff"
			card_skill_button.button_pressed = true

func _on_card_skill_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		var is_added: bool = set_skill_data(true)
		if !is_added:
			return
		card_skill_button.modulate = "ffffff"
	else:
		var _is_added: bool = set_skill_data(false)
		card_skill_button.modulate = Color(1, 1, 1, 0.435)

func set_skill_data(is_equipped: bool) -> bool:
	var slots_name: String = card_data["Group"].capitalize() + "Slot"
	for slot: TextureRect in get_tree().get_nodes_in_group(slots_name):
		if slot.card_data["origin_equipment_slot"] == card_data["origin_equipment_slot"]:
			var is_added: bool = slot.set_skill_data(is_equipped)
			return is_added
	return false
#endregion


	
