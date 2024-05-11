extends Control

signal card_equipped(value: bool)

var template_card_upgrade_slot: PackedScene = preload("res://Components/Inventory/card_upgrade_item_slot.tscn")
var inventory_slot_card: PackedScene = preload("res://Components/Inventory/card_inventory_slot.tscn")

@onready var beats_balance: Label = %BeatsBalance
@onready var native_balance: Label = %Native
@onready var gmr_balance: Label = %KMR
@onready var thump_balance: Label = %ThumpBalance

@onready var current_experience: Label = %CurrentExp
@onready var required_experience: Label = %RequiredExp
@onready var card_level_progress: TextureProgressBar = %CardLevelProgress

@onready var card_upgrade_container: GridContainer = %CardUpgradeContainer
@onready var background_texture: TextureRect = %BackgroundTexture
@onready var card_inventory_container: HBoxContainer = %CardInventoryContainer
@onready var equipped_card_button: TextureButton = %EquippedCardButton
@onready var card_progress_container: VBoxContainer = %CardProgressContainer

var equipped_card_data: Dictionary = {}

var card_level: int = 0
var card_experience_required: int = int(get_required_card_experience(card_level + 1))
var card_experience_total: int = 0
var card_experience: int

var card_scoreboost: int = 0
var card_healboost: int = 0



var card_level_tween: Tween


func _ready() -> void:
	signal_connect()
	BKMREngine.Inventory.open_card_inventory()
	BKMREngine.Inventory.open_card_upgrade_inventory()
	hud_data()

func signal_connect() -> void:
	BKMREngine.Inventory.get_card_upgrade_inventory_complete.connect(_on_get_card_upgrade_inventory_complete)
	BKMREngine.Inventory.get_card_inventory_complete.connect(card_inventory_open)

func hud_data() -> void:
	beats_balance.text = PLAYER.beats_balance
	native_balance.text = PLAYER.native_balance
	gmr_balance.text = PLAYER.gmr_balance

func _on_get_card_upgrade_inventory_complete(card_upgrade_data: Array) -> void:
	var card_upgrade_slot: Control 
	for upgrade_item: Dictionary in card_upgrade_data: 
		card_upgrade_slot = template_card_upgrade_slot.instantiate()
		
		card_upgrade_slot.card_upgrade_item_pressed.connect(_on_card_upgrade_item_button_pressed)
		if upgrade_item.has("tier"):
			if upgrade_item.tier == "tier1":
				var item_texture: Texture = load("res://UITextures/CardUpgrades/general_tier1.png")
				card_upgrade_slot.get_node("Panel/CardIcon").texture = item_texture
				
		var equip_card: Callable = card_upgrade_slot.card_equipped
		var _connect: int = card_equipped.connect(equip_card)
		card_upgrade_slot.slot_data(upgrade_item)
		card_upgrade_container.add_child(card_upgrade_slot)

func card_inventory_open(inventory_data: Array) -> void:
	var card_inventory_slot: Control
	for card_data: Dictionary in inventory_data[0]:
		card_inventory_slot = inventory_slot_card.instantiate()
		var uri: String = card_data.keys()[0]

		var card_name: String = card_data[uri]["name"].replace(" ", "_").to_lower()
		var card_texture: Texture = load("res://UITextures/Cards/" + card_name + ".png")
		
		card_inventory_slot.get_node('CardIcon').set_texture(card_texture)
		card_inventory_container.add_child(card_inventory_slot)
		card_inventory_container.move_child(card_inventory_slot, 0)
		
		card_inventory_slot.get_node('CardIcon').slot_data(card_data)
		card_inventory_slot.get_node('CardIcon').data_card.connect(_on_card_inventory_slot_pressed)
		
	var empty_card_inventory_slot: int = PLAYER.inventory_size - inventory_data[0].size()
	for _i: int in empty_card_inventory_slot:
		card_inventory_slot = inventory_slot_card.instantiate()
		card_inventory_container.add_child(card_inventory_slot)
		card_inventory_container.move_child(card_inventory_slot, 0)
		card_inventory_slot.get_node('CardIcon').slot_data()
		card_inventory_slot.get_node('CardIcon').data_card.connect(_on_card_inventory_slot_pressed)

func _on_card_inventory_slot_pressed(card_data: Dictionary, card_inventory_slot: Control) -> void:
	for label: Label in get_tree().get_nodes_in_group("CardValues"):
		var label_name: String = label.name
		if card_data.has(label_name):
			label.text = str(card_data[label_name])
	
	card_inventory_slot.equip_to_equip_slot()
	card_inventory_slot.cards_data["origin_item_id"] = null
	%CardImage.texture = card_data["origin_texture"]
	
	equipped_card_data = card_data
	
	card_level = int(equipped_card_data["Level"])
	card_experience = int(equipped_card_data["Experience"])

	card_progress_container.visible = true
	card_equipped.emit(true)
	
func _on_equipped_card_button_pressed() -> void:
	if !equipped_card_data.is_empty():
		var _scene: Error = get_tree().change_scene_to_file("res://UIScenes/card_upgrade.tscn")
		#reset_card_upgrade_var()
		#card_equipped.emit(false)
		#for slots: Control in get_tree().get_nodes_in_group("CardUpgradeSlot"):
			#if !slots.card_upgrade_slot_data.is_empty():
				#slots.unequip_card_upgrade()
			#slots.visible = false
		#for slots: TextureRect in get_tree().get_nodes_in_group('InventorySlot'):
			#if slots.cards_data["origin_item_id"] == null or "":
				#slots.unequip_from_equip_slot(equipped_card_data, %CardImage.texture)
				#slot_data()
				#card_progress_container.visible = false
				#equipped_card_data = {}
				#return

#func reset_card_upgrade_var() -> void:
	#card_level = 0
	#card_experience_required = 0
	#card_experience_total = 0
	#card_experience = 0
	#required_experience.text = ""
	#current_experience.text = ""
	#card_level_progress.max_value = 0
	#card_level_progress.value = 0
	
	#card_gain_experience(0)

func slot_data() -> void:
	for label: Label in get_tree().get_nodes_in_group("CardValues"):
		label.text = ""
	%CardImage.texture = null

func get_required_card_experience(level: int) -> int:
	return round (pow(level, 1.8) + level * 4)

func card_gain_experience(amount: int) -> void:
	card_experience_total += amount
	card_experience += amount
	card_level_progress.max_value = card_experience_required
	while card_experience >= card_experience_required:
		card_experience -= card_experience_required
		level_up()
		


	current_experience.text = str("Current EXP: ", card_experience)
	required_experience.text = str("Required EXP: ", card_experience_required)
	

	
	card_level_tween = get_tree().create_tween()
	var _tween_property: PropertyTweener = card_level_tween.tween_property(
		card_level_progress, 
		"value", 
		card_experience, 
		0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_LINEAR)

func level_up() -> void:
	card_level += 1
	card_scoreboost += 1
	card_healboost += 1
	card_experience_required = get_required_card_experience(card_level + 1)
	
	%NewLevel.text = str("+ ", card_level - 1)
	%NewScoreBoost.text = str("+ ",card_scoreboost)
	%NewHealboost.text = str("+ ",card_healboost)

func _on_card_upgrade_item_button_pressed(card_upgrade_slot_data: Dictionary) -> void:
	if !equipped_card_data.is_empty():
		for slot: Control in get_tree().get_nodes_in_group("CardUpgradeSlot"):
			if slot.card_upgrade_slot_data.is_empty():
				if slot.get_node("Quantity").text != "20":
						slot.slot_data(card_upgrade_slot_data)
						var current_quantity: int = int(slot.get_node("Quantity").text)
						slot.get_node("Quantity").text = str(current_quantity + 1)
						card_gain_experience(card_upgrade_slot_data.experience - 49)
						return
			else:
				if slot.get_node("Quantity").text != "20":
					if slot.card_upgrade_slot_data.id == card_upgrade_slot_data.id:
						var current_quantity: int = int(slot.get_node("Quantity").text)
						slot.get_node("Quantity").text = str(current_quantity + 1)
						card_gain_experience(card_upgrade_slot_data.experience - 49)
						return

func _on_close_button_pressed() -> void:
	BKMREngine.Auth.auto_login_player()
	LOADER.previous_texture = background_texture.texture
	LOADER.next_texture = preload("res://UITextures/BGTextures/main_city.png")
	var _change_scene: bool = await LOADER.load_scene(self, "res://UIScenes/main_screen.tscn")

func _on_card_upgrade_submit_pressed() -> void:
	var card_upgrade: Array = []
	for slot: Control in get_tree().get_nodes_in_group("CardUpgradeSlot"):
		if !slot.card_upgrade_slot_data.is_empty():
			var card_upgrade_item: Dictionary = {
				"uri": slot.card_upgrade_slot_data.uri,
				"id": slot.card_upgrade_slot_data.id,
				"quantityConsumed": int(slot.get_node("Quantity").text)
			}
			card_upgrade.append(card_upgrade_item)
	print(card_upgrade)
	#if !equipped_card_data.is_empty():
		#var _card_upgrade_submit_data: Dictionary = {
			#"cardUri": equipped_card_data.uri,
			#"cardUpgrade": [{
				#"cardUpgradeUri":
			#}
				#
			#]
		#}
