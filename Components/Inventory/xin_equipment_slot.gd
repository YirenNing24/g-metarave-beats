extends TextureRect

signal equipped_card_pressed(card_data: Dictionary)
signal unequipped

@onready var button: Button = get_parent().get_node("Button")
@onready var skill_icon1: TextureRect = %XinSkillIcon
@onready var skill_icon2: TextureRect = %XinSkillIcon2
@onready var skill_icon3: TextureRect = %XinSkillIcon3
@onready var inventory_scroll: ScrollContainer = %InventoryScroll

var cards_data: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var _connect: int = button.pressed.connect(_on_button_pressed)
	var _connection: int = BKMREngine.Inventory.update_equipped_item_complete.connect()
	var initialize_scrolling: Callable = inventory_scroll.initialize_scrolling
	var _connect_initialize_scrolling: int = unequipped.connect(initialize_scrolling)
	
func slot_data(card_data: Dictionary = {}) -> Dictionary:
	var equipment_slot: String = get_parent().name
	if !card_data.is_empty():
		var uri: String = card_data.keys()[0]
		if equipment_slot == card_data[uri].slot:
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
		
			card_data["Era"] = card_data[uri].era
			card_data["Rarity"] = card_data[uri].rarity
			card_data["Level"] = card_data[uri].level
			card_data["Experience"] = card_data[uri].experience

			card_data["Scoreboost"] = card_data[uri].scoreboost
			card_data["Healboost"] = card_data[uri].healboost
			card_data["BoostCount"] = card_data[uri].boostCount
			card_data["AwakenCount"] = card_data[uri].awakenCount
	else:
		default_texture()
		card_data["origin_item_id"] = null
		card_data["origin_panel"] = "CardSlot"
		card_data["origin_texture"] = texture
		cards_data = card_data
		return cards_data as Dictionary
		
	cards_data = card_data
	return cards_data as Dictionary

func slot_texture_set() -> void:
	var card_name: String = cards_data["Name"]
	card_name = card_name.replace(" ", "_").to_lower()
	var card_texture: Texture = load("res://UITextures/Cards/" + card_name + ".png")
	texture = card_texture
	
	cards_data["origin_texture"] = card_texture
	self_modulate = "ffffff"
	
func default_texture() -> void:
	var equipment_slot: String = get_parent().name
	var texture_name: String = equipment_slot.to_lower() + "_empty_slot_bg" + ".png"
	var texture_default: Texture = load("res://UITextures/BGTextures/Inventory/EmptySlot/" + texture_name)
	texture = texture_default
	
func _on_button_pressed() -> void:
	equipped_card_pressed.emit(cards_data)

func equip(origin_item_id: String, equipment_data: Dictionary) -> void:
	if cards_data["origin_equipment_slot"] == equipment_data["origin_equipment_slot"]:
		BKMREngine.Inventory.update_equipped_item(true, origin_item_id)
		var _equipment_slot_data: Dictionary = slot_data(equipment_data)

func unequip(origin_item_id: String, equipment_data: Dictionary = {}) -> void:
	BKMREngine.Inventory.update_equipped_item(false, origin_item_id)
	var _unequip: Dictionary = slot_data(equipment_data)
	#var equipment_slot: String = get_parent().name
	#for slots: TextureRect in get_tree().get_nodes_in_group('InventorySlot'):
		#if slots.card_data["origin_item_id"] == null or "":
			#slots.unequip_from_card_slot(cards_data["origin_item_id"], texture)
			#BKMREngine.Inventory.card_inventory.slotEquipment["IveEquip"][equipment_slot]["Item"] = ""
			#
			#var card_inventory: Dictionary = BKMREngine.Inventory.card_inventory
			#var _data: Dictionary = slot_data(card_inventory)
			#unequipped.emit()
			#return

#func set_skill_data(is_equipped: bool) -> bool:
	#var equipment_slot: String = get_parent().name
	#
	#var slot_equipment_ive: Dictionary = BKMREngine.Inventory.card_inventory.slotEquipment["IveEquip"]
	#var equipped_count: int = limit_toggled_skills(slot_equipment_ive)
	#if equipped_count >= 3:
		#return false
		#
	#BKMREngine.Inventory.card_inventory.slotEquipment["IveEquip"][equipment_slot]["Equipped"] = is_equipped
	#set_skill_texture()
	#return true
	
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
