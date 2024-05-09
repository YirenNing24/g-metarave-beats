extends Control

signal card_equipped(value: bool)

var template_card_upgrade_slot: PackedScene = preload("res://Components/Inventory/card_upgrade_item_slot.tscn")
var inventory_slot_card: PackedScene = preload("res://Components/Inventory/card_inventory_slot.tscn")

@onready var beats_balance: Label = %BeatsBalance
@onready var native_balance: Label = %Native
@onready var gmr_balance: Label = %KMR
@onready var thump_balance: Label = %ThumpBalance


@onready var card_upgrade_container: GridContainer = %CardUpgradeContainer
@onready var background_texture: TextureRect = %BackgroundTexture
@onready var card_inventory_container: HBoxContainer = %CardInventoryContainer
@onready var equipped_card_button: TextureButton = %EquippedCardButton

var equipped_card_data: Dictionary = {}

# Called when the node enters the scene tree for the first time.
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
	card_equipped.emit(true)
	
func _on_equipped_card_button_pressed() -> void:
	if !equipped_card_data.is_empty():
		card_equipped.emit(false)
		for slots: Control in get_tree().get_nodes_in_group("CardUpgradeSlot"):
			if !slots.card_upgrade_slot_data.is_empty():
				slots.unequip_card_upgrade()
			slots.visible = false
		for slots: TextureRect in get_tree().get_nodes_in_group('InventorySlot'):
			if slots.cards_data["origin_item_id"] == null or "":
				slots.unequip_from_equip_slot(equipped_card_data, %CardImage.texture)
				slot_data()
				return

			
func slot_data() -> void:
	for label: Label in get_tree().get_nodes_in_group("CardValues"):
		label.text = ""
	%CardImage.texture = null

func _on_card_upgrade_item_button_pressed(card_upgrade_slot_data: Dictionary) -> void:
	if !equipped_card_data.is_empty():
		for slot: Control in get_tree().get_nodes_in_group("CardUpgradeSlot"):
			if slot.card_upgrade_slot_data.is_empty():
				if slot.get_node("Quantity").text != "20":
						slot.slot_data(card_upgrade_slot_data)
						@warning_ignore("unsafe_call_argument")
						var current_quantity: int = int(slot.get_node("Quantity").text)
						slot.get_node("Quantity").text = str(current_quantity + 1)
						return
			else:
				if slot.get_node("Quantity").text != "20":
					if slot.card_upgrade_slot_data.id == card_upgrade_slot_data.id:
						@warning_ignore("unsafe_call_argument")
						var current_quantity: int = int(slot.get_node("Quantity").text)
						slot.get_node("Quantity").text = str(current_quantity + 1)
						return
				
func _on_close_button_pressed() -> void:
	BKMREngine.Auth.auto_login_player()
	LOADER.previous_texture = background_texture.texture
	LOADER.next_texture = preload("res://UITextures/BGTextures/main_city.png")
	var _change_scene: bool = await LOADER.load_scene(self, "res://UIScenes/main_screen.tscn")
