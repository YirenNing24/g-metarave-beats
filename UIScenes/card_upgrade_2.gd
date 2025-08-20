extends Control


var template_card_upgrade_slot: PackedScene = preload("res://Components/Upgrade/card_upgrade.tscn")
var inventory_slot_card: PackedScene = preload("res://Components/Inventory/card_inventory_slot.tscn")

var card_level: int = 0
var card_experience_required: int = int(get_required_card_experience(card_level + 1))
var card_experience_total: int = 0
var card_experience: int

var card_scoreboost: int = 0
var card_healboost: int = 0

var old_level: int


var card_level_tween: Tween
var equipped_card_data: Dictionary = {}


func _ready() -> void:
	connect_signals()
	BKMREngine.Inventory.open_card_inventory()
	BKMREngine.Inventory.open_card_upgrade_inventory()
	
	
func connect_signals() -> void:
	BKMREngine.Inventory.get_card_inventory_complete.connect(card_inventory_open)
	BKMREngine.Upgrade.upgrade_card_complete.connect(_on_upgrade_card_complete)
	BKMREngine.Inventory.get_card_upgrade_inventory_complete.connect(_on_get_card_upgrade_inventory_complete)
	
	
func card_inventory_open(inventory_data: Array) -> void:
	var card_inventory_slot: Control
	for card_data: Dictionary in inventory_data[0]:
		card_inventory_slot = inventory_slot_card.instantiate()
		var uri: String = card_data.keys()[0]

		var card_name: String = card_data[uri]["name"].replace(" ", "_").to_lower()
		var card_texture: Texture = load("res://UITextures/Cards/" + card_name + ".png")
		
		card_inventory_slot.get_node('CardIcon').set_texture(card_texture)
		%CardInventoryContainer.add_child(card_inventory_slot)
		%CardInventoryContainer.move_child(card_inventory_slot, 0)
		
		card_inventory_slot.get_node('CardIcon').slot_data(card_data)
		card_inventory_slot.get_node('CardIcon').data_card.connect(_on_card_inventory_slot_pressed)
		
	var empty_card_inventory_slot: int = PLAYER.inventory_size - inventory_data[0].size()
	for _i: int in empty_card_inventory_slot:
		card_inventory_slot = inventory_slot_card.instantiate()
		%CardInventoryContainer.add_child(card_inventory_slot)
		%CardInventoryContainer.move_child(card_inventory_slot, 0)
		card_inventory_slot.get_node('CardIcon').slot_data()
		card_inventory_slot.get_node('CardIcon').data_card.connect(_on_card_inventory_slot_pressed)
	
	
func _on_get_card_upgrade_inventory_complete(card_upgrade_data: Array) -> void:
	var card_upgrade_slot: Control 
	for upgrade_item: Dictionary in card_upgrade_data: 
		card_upgrade_slot = template_card_upgrade_slot.instantiate()
		
		card_upgrade_slot.card_upgrade_item_pressed.connect(_on_card_upgrade_item_button_pressed)
		if upgrade_item.has("tier"):
			if upgrade_item.tier == "tier1":
				var item_texture: Texture = preload("res://UITextures/CardUpgrades/card_upgrade.png")
				card_upgrade_slot.get_node("Panel/CardIcon").texture = item_texture
				

		card_upgrade_slot.slot_data(upgrade_item)
		%CardUpgradeContainer.add_child(card_upgrade_slot)
	
	
func _on_card_upgrade_item_button_pressed(card_upgrade_slot_data: Dictionary) -> void:
	if !equipped_card_data.is_empty():
		for slot: Control in get_tree().get_nodes_in_group("CardUpgradeSlot"):
			if slot.card_upgrade_slot_data.is_empty():
				if slot.get_node("Quantity").text != "20":
						slot.slot_data(card_upgrade_slot_data)
						@warning_ignore("unsafe_call_argument")
						var current_quantity: int = int(slot.get_node("Quantity").text)
						slot.get_node("Quantity").text = str(current_quantity + 1)
						@warning_ignore("unsafe_call_argument")
						card_gain_experience(card_upgrade_slot_data.metadata.experience)
						return
			else:
				if slot.get_node("Quantity").text != "20":
					print("tae: ", slot.card_upgrade_slot_data )
					print("ihi: ", card_upgrade_slot_data)
					if slot.card_upgrade_slot_data.metadata.id == card_upgrade_slot_data.metadata.id:
						
						@warning_ignore("unsafe_call_argument")
						var current_quantity: int = int(slot.get_node("Quantity").text)
						slot.get_node("Quantity").text = str(current_quantity + 1)
						@warning_ignore("unsafe_call_argument")
						card_gain_experience(card_upgrade_slot_data.metadata.experience)
						return
	
	
func _on_card_inventory_slot_pressed(card_data: Dictionary, _card_inventory_slot: Control) -> void:
	for label: Label in get_tree().get_nodes_in_group("CardValues"):
		var label_name: String = label.name
		if card_data.has(label_name):
			label.text = str(card_data[label_name])
	equipped_card_data = card_data
	var level: String = equipped_card_data["Level"]
	var experience: String = equipped_card_data["Experience"]
	var texture_card: Texture = card_data["origin_texture"]
	
	%CardImage.texture = texture_card
	card_level = int(level)
	old_level = int(level)
	card_experience = int(experience)
	set_progress_bar_values()
	%UpgradeContainer.visible = true
	
	
func set_progress_bar_values() -> void:
	%CardLevelProgress.value = card_experience
	%CardLevelProgress.max_value = get_required_card_experience(old_level)
	
	
func _on_upgrade_card_complete(_message: Dictionary) -> void:
	%LoadingPanel.tween_kill()
	var level_new: String = %NewLevel.text
	var current_level: String = %Level.text
	
	var new_level: int = int(level_new)
	var level: int = int(current_level)
	%Level.text = str(new_level + level)
	%NewLevel.text = ""
	
	
func get_required_card_experience(level: int) -> int:
	return round (pow(level, 1.8) + level * 4)
	
	
func card_gain_experience(amount: int) -> void:
	
	print("tae: ", amount)
	card_experience_total += amount
	card_experience += amount
	%CardLevelProgress.max_value = card_experience_required
	while card_experience >= card_experience_required:
		card_experience -= card_experience_required
		level_up()
	#current_experience.text = str("Current EXP: ", card_experience)
	#required_experience.text = str("Required EXP: ", card_experience_required)
	card_level_tween = get_tree().create_tween()
	var _tween_property: PropertyTweener = card_level_tween.tween_property(
		%CardLevelProgress, 
		"value", 
		card_experience, 
		0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_LINEAR)
	
	
func level_up() -> void:
	card_level += 1
	card_scoreboost += 1
	card_healboost += 1
	card_experience_required = get_required_card_experience(card_level + 1)
	
	var yes: int = card_level - old_level
	%NewLevel.text = str("+ ", yes)
	%NewScoreBoost.text = str("+ ", card_scoreboost)
	%NewHealboost.text = str("+ ", card_healboost)
	
	
func _on_close_button_pressed() -> void:
	BKMREngine.Auth.auto_login_player()
	LOADER.previous_texture = %BackgroundTexture.texture
	LOADER.next_texture = preload("res://UITextures/BGTextures/main_city.png")
	var _change_scene: bool = await LOADER.load_scene(self, "res://UIScenes/main_inventory.tscn")
	
	
func _on_equipped_card_button_pressed() -> void:
	%UpgradeContainer.visible = false
