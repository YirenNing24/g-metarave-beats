extends Control

signal equip_unequip_pressed
signal close_item_stats_pressed
signal chosen_card_group

@onready var name_label: Label = %NameLabel
@onready var scoreboost_label: Label = %ScoreBoost
@onready var healboost_label: Label = %HealBoost
@onready var tier_rarity_era_label: Label = %TierRarityEraLabel
@onready var equip_label: Label = %EquipLabel

@onready var equipped_icon: TextureRect = %EquippedIcon
@onready var equip_unequip_button: TextureButton = %EquipUnequipButton
@onready var powerup_button: TextureButton = %PowerupButton


var card_data: Dictionary
var is_open: bool = false


#region Set UI Variables
func _on_card_inventory_screen_item_stats_card_data(data_card: Dictionary) -> void:
	clear_variables()
	card_data = data_card
	
	populate_card_labels()
	
	
func populate_card_labels() -> void:
	
	var origin_node: String = card_data["origin_panel"]
	if origin_node == "CardInventory":
		var card_name: String = card_data["Name"]
		var card_scoreboost: String = card_data["Scoreboost"]
		var card_healboost: String = card_data["Healboost"]
		
		var card_level: String = str(card_data["Level"])
		#var card_tier: String = card_data["Tier"]
		#var card_era: String = card_data["Era"]
		
		var card_texture: Texture = card_data["origin_texture"]
		
		set_labels(card_name, card_scoreboost, card_healboost, card_level, card_texture)
		set_buttons(true, origin_node)
	elif origin_node == "CardSlot":
		if card_data["origin_item_id"] == null:
			var card_texture: Texture = card_data["origin_texture"]
			set_labels("", "", "", "", card_texture)
			set_buttons(false, origin_node)
		else:
			var card_name: String = card_data["Name"]
			var card_scoreboost: String = card_data["Scoreboost"]
			var card_healboost: String = card_data["Healboost"]
			var card_level: String = str(card_data["Level"])
			#var card_era: String = card_data["Era"]
			var card_texture: Texture = card_data["origin_texture"]
			set_labels(card_name, card_scoreboost, card_healboost, card_level, card_texture)
			set_buttons(true, origin_node)
			#set_skill()
	visible = true
	
	
func set_labels(card_name: String, scoreboost: String, healboost: String, level: String, texture: Texture) -> void:
	name_label.text = card_name
	scoreboost_label.text = scoreboost
	healboost_label.text = healboost
	%Level.text = level
	
	%EquippedIcon.texture = texture
	%BackgroundIcon.texture = texture
	

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
	close_item_stats_pressed.emit()
	clear_variables()
	
	
func clear_variables() -> void:
	card_data = {}
	equipped_icon.texture = null
	%BackgroundIcon.texture = null
	visible = false
#endregion
	
	
#region Item Equipped or Unequipped
func _on_equip_unequip_button_pressed() -> void:
	if card_data["origin_panel"] == "CardInventory":
		equip()
	elif card_data["origin_panel"] == "CardSlot":
		unequip()
	equip_unequip_pressed.emit()
	
	
func equip() -> void:
	show_all_cards()
	
	# Store frequently accessed properties in variables for efficiency
	var inv_slot_node: TextureRect = card_data["origin_node"]
	var group_name: String = card_data["Group"].to_upper()
	var slots_name: String = group_name + "Slot"
	var slot_group_name: String = slots_name.replace(" ", "")
	var card_equipment_slot: String = card_data["origin_equipment_slot"].replace(" ", "").to_lower()
	
	# Emit the chosen card's group
	chosen_card_group.emit(card_data["Group"])

	# Iterate over slots and equip if conditions are met
	for slot: TextureRect in get_tree().get_nodes_in_group(slot_group_name):
		if slot.cards_data["origin_equipment_slot"].replace(" ", "").to_lower() == card_equipment_slot:
			if slot.cards_data["origin_item_id"] == null:
				slot.equip(card_data["origin_item_id"], card_data)
				inv_slot_node.equip_to_equip_slot()
				break  # Assuming only one slot needs to be equipped, exit the loop

	# Reset is_open state and clear variables
	is_open = false
	clear_variables()

	# Hide the filter button
	var filter_button: TextureButton = get_parent().get_node("TextureRect/VBoxContainer/Panel/HBoxContainer/HBoxContainer/CloseFilterButton")
	filter_button.visible = false

	
	
func unequip() -> void:
	var slots_name: String = card_data["Group"].to_upper() + "Slot"
	var slot_group_name: String = slots_name.replace(" ", "")
	for slot: TextureRect in get_tree().get_nodes_in_group(slot_group_name):
		if slot.cards_data["origin_item_id"] != null:
			if slot.cards_data["origin_equipment_slot"].replace(" ", "").to_lower() == card_data["origin_equipment_slot"].replace(" ", "").to_lower():
				slot.unequip(card_data)
				
	is_open = true
	clear_variables()
#endregion
	
	
#region Set Skill & Data
#func set_skill() -> void:
	#if card_data["Skill"] != null or "":
		#var skill_name: String = card_data["Skill"].to_lower()
		#var skill_texture: Texture = load("res://UITextures/Buttons/Skill/"+ skill_name + "_skill_texture" + ".png")
		#card_skill_button.texture_normal = skill_texture
		#card_skill_button.texture_pressed = skill_texture
		#
		#if card_data["SkillEquipped"] == false:
			#card_skill_button.modulate = Color(1, 1, 1, 0.435)
			#card_skill_button.button_pressed = false
		#else:
			#card_skill_button.modulate = "ffffff"
			#card_skill_button.button_pressed = true

func _on_card_skill_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		var is_added: bool = set_skill_data(true)
		if !is_added:
			return
	else:
		var _is_added: bool = set_skill_data(false)
	
	
func set_skill_data(is_equipped: bool) -> bool:
	var slots_name: String = card_data["Group"].capitalize() + "Slot"
	for slot: TextureRect in get_tree().get_nodes_in_group(slots_name):
		if slot.card_data["origin_equipment_slot"] == card_data["origin_equipment_slot"]:
			var is_added: bool = slot.set_skill_data(is_equipped)
			return is_added
	return false
#endregion
	
	
func show_all_cards() -> void:
	for card: Control in get_tree().get_nodes_in_group("InventorySlot"):
		if card.cards_data["Name"] != null or "":
			card.get_parent().visible = true
	
	
func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		visible = false
		is_open = false
