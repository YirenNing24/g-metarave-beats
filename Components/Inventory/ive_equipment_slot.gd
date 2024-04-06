extends TextureRect

signal data_card(card_data: Dictionary)
signal unequipped

@onready var button: Button = get_parent().get_node("Button")
@onready var skill_icon1: TextureRect = %IVESkillIcon
@onready var skill_icon2: TextureRect = %IVESkillIcon2
@onready var skill_icon3: TextureRect = %IVESkillIcon3
@onready var inventory_scroll: ScrollContainer = %InventoryScroll

var card_data: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var _connect: int = button.pressed.connect(_on_button_pressed.bind(card_data))
	
	var initialize_scrolling: Callable = inventory_scroll.initialize_scrolling
	var _connect_initialize_scrolling: int = unequipped.connect(initialize_scrolling)
	
func slot_data(equipment_data: Dictionary) -> Dictionary:
	var equipment_slot: String = get_parent().name
	if equipment_data.slotEquipment["IveEquip"][equipment_slot]["Item"] != null or "":
		var item_uri: String = equipment_data.slotEquipment["IveEquip"][equipment_slot]["Item"]
		
		card_data["origin_node"] = self
		card_data["origin_panel"] = "CardSlot"
		card_data["origin_item_id"] = item_uri

		card_data["Name"] = equipment_data.cardsData[equipment_data.slotEquipment["IveEquip"][equipment_slot]["Item"]]["name"]
		card_data["Group"] = equipment_data.cardsData[equipment_data.slotEquipment["IveEquip"][equipment_slot]["Item"]]["group"]
		card_data["Position"] = equipment_data.cardsData[equipment_data.slotEquipment["IveEquip"][equipment_slot]["Item"]]["position"]
		card_data["Position2"] = equipment_data.cardsData[equipment_data.slotEquipment["IveEquip"][equipment_slot]["Item"]]["position2"]
		
		card_data["Skill"] = equipment_data.cardsData[equipment_data.slotEquipment["IveEquip"][equipment_slot]["Item"]]["skill"]
		card_data["SkillEquipped"] = equipment_data.slotEquipment["IveEquip"][equipment_slot]["Equipped"]
		
		card_data["Era"] = equipment_data.cardsData[equipment_data.slotEquipment["IveEquip"][equipment_slot]["Item"]]["era"]
		card_data["Rarity"] = equipment_data.cardsData[equipment_data.slotEquipment["IveEquip"][equipment_slot]["Item"]]["rarity"]
		card_data["Level"] = equipment_data.cardsData[equipment_data.slotEquipment["IveEquip"][equipment_slot]["Item"]]["level"]
		card_data["Experience"] = equipment_data.cardsData[equipment_data.slotEquipment["IveEquip"][equipment_slot]["Item"]]["experience"]

		card_data["Scoreboost"] = equipment_data.cardsData[equipment_data.slotEquipment["IveEquip"][equipment_slot]["Item"]]["scoreboost"]
		card_data["Healboost"] = equipment_data.cardsData[equipment_data.slotEquipment["IveEquip"][equipment_slot]["Item"]]["healboost"]
		card_data["BoostCount"] = equipment_data.cardsData[equipment_data.slotEquipment["IveEquip"][equipment_slot]["Item"]]["boostcount"]
		card_data["AwakenCount"] = equipment_data.cardsData[equipment_data.slotEquipment["IveEquip"][equipment_slot]["Item"]]["awakencount"]

		card_data["Tier"] = equipment_data.cardsData[equipment_data.slotEquipment["IveEquip"][equipment_slot]["Item"]]["tier"]
		card_data["origin_equipment_slot"] = equipment_slot
		
		slot_texture_set()
	else:
		card_data["origin_node"] = self
		card_data["origin_panel"] = "CardSlot"
		card_data["origin_item_id"] = null
		card_data["origin_equipment_slot"] = equipment_slot
		
		card_data["Name"] = null
		card_data["Group"] = null
		card_data["Position"] = null
		card_data["Position2"] = null
		card_data["Era"] = null
		
		card_data["Skill"] = null
		card_data["SkillEquipped"] = false
		
		card_data["Rarity"] = null
		card_data["Level"] = null
		card_data["Experience"] = null
		card_data["Experience_required"] = null
		card_data["Scoreboost"] = null
		card_data["Healboost"] = null
		card_data["BoostCount"] = null
		card_data["AwakenCount"] = null
		
		card_data["Tier"] = null
		self_modulate = Color(0.729, 0.729, 0.729)
		default_texture()
		card_data["origin_texture"] = texture
		
	return card_data as Dictionary

func slot_texture_set() -> void:
	var card_name: String = card_data["Name"]
	card_name = card_name.replace(" ", "_").to_lower()
	var card_tier: String = card_data["Tier"].to_lower()
	var card_texture: Texture = load("res://UITextures/Cards/" + card_name + "_" + card_tier + ".png")
	texture = card_texture
	
	card_data["origin_texture"] = card_texture
	self_modulate = "ffffff"
	
func default_texture() -> void:
	var equipment_slot: String = get_parent().name
	var texture_name: String = equipment_slot.to_lower() + "_empty_slot_bg" + ".png"
	var texture_default: Texture = load("res://UITextures/BGTextures/Inventory/EmptySlot/" + texture_name)
	texture = texture_default
	
func _on_button_pressed(data: Dictionary) -> void:
	data_card.emit(data)

func equip(equipment_data: Dictionary, origin_item_id: String) -> void:
	var equipment_slot: String = get_parent().name
	
	equipment_data.slotEquipment["IveEquip"][equipment_slot]["Item"] = origin_item_id
	var _equipment_slot_data: Dictionary = slot_data(equipment_data)

func unequip() -> void:
	var equipment_slot: String = get_parent().name
	for slots: TextureRect in get_tree().get_nodes_in_group('InventorySlot'):
		if slots.card_data["origin_item_id"] == null or "":
			slots.unequip_from_card_slot(card_data["origin_item_id"], texture)
			BKMREngine.Inventory.card_inventory.slotEquipment["IveEquip"][equipment_slot]["Item"] = ""
			
			var card_inventory: Dictionary = BKMREngine.Inventory.card_inventory
			var _data: Dictionary = slot_data(card_inventory)
			unequipped.emit()
			return

func set_skill_data(is_equipped: bool) -> bool:
	var equipment_slot: String = get_parent().name
	
	var slot_equipment_ive: Dictionary = BKMREngine.Inventory.card_inventory.slotEquipment["IveEquip"]
	var equipped_count: int = limit_toggled_skills(slot_equipment_ive)
	if equipped_count >= 3:
		return false
		
	BKMREngine.Inventory.card_inventory.slotEquipment["IveEquip"][equipment_slot]["Equipped"] = is_equipped
	set_skill_texture()
	return true
	
func limit_toggled_skills(equipment_slot: Dictionary) -> int:
	var equipped_count: int = 0
	for slot: String in equipment_slot.keys():
		if equipment_slot[slot]["Equipped"]:
			equipped_count += 1
	return equipped_count as int
	
func set_skill_texture() -> void:
	var skill_name: String = card_data["Skill"].to_lower()
	var skill_texture: Texture = load("res://UITextures/Buttons/Skill/"+ skill_name + "_skill_texture" + ".png")
	for skill_icon: TextureRect in get_tree().get_nodes_in_group('IveSkill'):
		if skill_icon.texture == null:
			skill_icon.texture = skill_texture
			return
