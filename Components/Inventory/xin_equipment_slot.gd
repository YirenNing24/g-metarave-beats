extends TextureRect

signal equipped_card_pressed(card_data: Dictionary)
#signal create_card_inventory_slot


@onready var button: Button = get_parent().get_node("Button")
#@onready var skill_icon1: TextureRect = %XinSkillIcon
#@onready var skill_icon2: TextureRect = %XinSkillIcon2
#@onready var skill_icon3: TextureRect = %XinSkillIcon3

var cards_data: Dictionary = {}
var unequip_card_data: Dictionary


const inventory_tab_container: String = "/root/CardInventoryScreen/TextureRect/InventoryTabContainer"
const score_boost_value_path: String = "/Panel/TextureRect/HBoxContainer/CardSetStatsContainer/HBoxContainer/VBoxContainer/HBoxContainer/ScoreBoostValue"
const heal_boost_value_path: String = "/Panel/TextureRect/HBoxContainer/CardSetStatsContainer/HBoxContainer/VBoxContainer/HBoxContainer2/HealBoostValue"



func _ready() -> void:
	connect_signal()
	
	
func connect_signal() -> void:
	var _connect: int = button.pressed.connect(_on_button_pressed)
	var _connection: int = BKMREngine.Inventory.equip_item_complete.connect(_on_equip_item_complete)
	
	
func slot_data(card_data: Dictionary = {}) -> Dictionary:
	var equipment_slot: String = get_parent().get_name()
	if !card_data.is_empty():
		var uri: String = card_data.keys()[0]
		if equipment_slot.replace(" ", "").to_lower() == card_data[uri].slot.replace(" ", "").to_lower():
			card_data["origin_node"] = self
			card_data["origin_panel"] = "CardSlot"
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
			#card_data["SkillEquipped"] = card_data[uri].skillEquipped
			
			card_data["Tier"] = card_data[uri].tier
			card_data["Era"] = card_data[uri].era
			card_data["Rarity"] = card_data[uri].rarity
			card_data["Level"] = card_data[uri].level
			card_data["Experience"] = card_data[uri].experience

			card_data["Scoreboost"] = card_data[uri].scoreboost
			card_data["Healboost"] = card_data[uri].healboost
			card_data["BoostCount"] = card_data[uri].boostCount
			card_data["AwakenCount"] = card_data[uri].awakenCount
			cards_data = card_data
			slot_texture_set()
			
			@warning_ignore("unsafe_call_argument")
			update_card_boost_values(card_data["Scoreboost"], card_data["Healboost"], card_data["Group"], true)
			
			return cards_data
	else:
		default_texture()
		
		card_data["origin_item_id"] = null
		card_data["origin_panel"] = "CardSlot"
		card_data["origin_equipment_slot"] = equipment_slot
		card_data["origin_texture"] = texture
		cards_data = card_data
		return cards_data
		
	cards_data = card_data
	slot_texture_set()
	return cards_data
	
	
func slot_texture_set() -> void:
	if "Name" in cards_data:
		var card_name: String = cards_data["Name"]
		card_name = card_name.replace(" ", "_").to_lower()
		var card_texture: Texture = load("res://UITextures/Cards/" + card_name + ".png")
		texture = card_texture
		self_modulate = "ffffff"
		cards_data["origin_texture"] = card_texture
	

func default_texture() -> void:
	var equipment_slot: String = get_parent().name
	var texture_name: String = equipment_slot.to_lower() + "_empty_slot_bg" + ".png"
	var texture_default: Texture = load("res://UITextures/BGTextures/Inventory/EmptySlot/" + texture_name)
	texture = texture_default
	
	
func _on_button_pressed() -> void:
	print("ehhhhh: ", cards_data)
	if cards_data["origin_item_id"] != null:
		equipped_card_pressed.emit(cards_data)
	else:
		filter_card_slot()
	
	
func equip(origin_item_id: String, card_data: Dictionary, origin: String = "self") -> void:
	if cards_data["origin_equipment_slot"].replace(" ", "").to_lower() == card_data["origin_equipment_slot"].replace(" ", "").to_lower():
		var _equipment_slot_data: Dictionary = slot_data(card_data)
		if origin == "self":
			var group: String = card_data[origin_item_id].group
			var equip_item_data: Dictionary = { 
				"uri": card_data[origin_item_id].uri, 
				"tokenId": card_data[origin_item_id].id,
				"contractAddress": card_data[origin_item_id].contractAddress,
				"group": group,
				"slot": get_parent().name,
				"name": card_data[origin_item_id].name
				}
			BKMREngine.Inventory.equip_item([equip_item_data])
	%LoadingPanel.fake_loader()
	
	
func unequip(_equipment_data: Dictionary = {}) -> void:
	for slots: TextureRect in get_tree().get_nodes_in_group('InventorySlot'):
		if slots.cards_data["origin_item_id"] == null or "":
			slots.unequip_from_equip_slot(cards_data, texture)
			var uri: String = cards_data.keys()[0]
			var unequip_data: Dictionary = { 
				"uri": cards_data["origin_item_id"], 
				"tokenId": cards_data[uri].id, 
				"contractAddress": cards_data[uri].contractAddress,
				"group": cards_data[uri].group,
				"slot": get_parent().name,
				"name": cards_data[uri].name
				}
			@warning_ignore("unsafe_call_argument")
			update_card_boost_values(cards_data[uri].scoreboost, cards_data[uri].healboost, cards_data[uri].group, false)
			BKMREngine.Inventory.unequip_item([unequip_data])
			self_modulate = "92929287"
			var _unequip: Dictionary = slot_data({})
			return
	
	
func update_card_boost_values(score_boost: String, heal_boost: String, group: String, equip_card: bool) -> void:
	var group_node: String = group_to_node_name(group)
	var group_equip_container: String = group_node + "Equip"
	
	# Paths to labels
	var score_boost_label_path: String = inventory_tab_container + "/" + group_node + "/" + group_equip_container + score_boost_value_path
	var health_boost_label_path: String = inventory_tab_container + "/" + group_node + "/" + group_equip_container + heal_boost_value_path

	# Convert boost values
	var score_boost_value: int = int(score_boost)
	var heal_boost_value: int = int(heal_boost)

	# Update score boost label directly
	if has_node(score_boost_label_path):
		var score_label: Label = get_node(score_boost_label_path)

		# Ensure label has a valid number
		var current_score: int = int(score_label.text) if score_label.text.is_valid_int() else 0

		# Adjust score
		var new_score: int = current_score + score_boost_value if equip_card else max(0, current_score - score_boost_value)
		score_label.text = str(new_score)

	# Update heal boost label directly
	if has_node(health_boost_label_path):
		var heal_label: Label = get_node(health_boost_label_path)

		# Ensure label has a valid number
		var current_heal: int = int(heal_label.text) if heal_label.text.is_valid_int() else 0

		# Adjust heal boost
		var new_heal: int = current_heal + heal_boost_value if equip_card else max(0, current_heal - heal_boost_value)
		heal_label.text = str(new_heal)

	
func group_to_node_name(group: String) -> String:
	match group:
		"X:IN":
			return "X_IN"
		"ICU":
			return "ICU"
		"Great Guys":
			return "GREAT_GUYS"
		"Irohm":
			return "IROHM"
	return ""
	
	
func limit_toggled_skills(equipment_slot: Dictionary) -> int:
	var equipped_count: int = 0
	for slot: String in equipment_slot.keys():
		if equipment_slot[slot]["Equipped"]:
			equipped_count += 1
	return equipped_count as int
	
	
func set_skill_texture() -> void:
	var skill_name: String = cards_data["Skill"].to_lower()
	var skill_texture: Texture = load("res://UITextures/Buttons/Skill/"+ skill_name + "_skill_texture" + ".png")
	for skill_icon: TextureRect in get_tree().get_nodes_in_group('IveSkill'):
		if skill_icon.texture == null:
			skill_icon.texture = skill_texture
			return
	
	
func _on_equip_item_complete(_message: Dictionary) -> void:
	%LoadingPanel.tween_kill()
	
	
func filter_card_slot() -> void:
	for card: Control in get_tree().get_nodes_in_group("InventorySlot"):
		if card.cards_data["origin_item_id"] != null:
			if card.cards_data["origin_equipment_slot"].replace(" ", "").to_lower() != cards_data["origin_equipment_slot"].replace(" ", "").to_lower():
				card.get_parent().visible = false
			else:
				card.get_parent().visible = true
	%CloseFilterButton.visible = true
