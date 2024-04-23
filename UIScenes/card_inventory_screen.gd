extends Control
#TODO loading effect while waiting for card inventory retrieval to finish
#TODO cards are getting clipped on the left side

signal item_stats_card_data

var inventory_slot_card: PackedScene = preload("res://Components/Inventory/card_inventory_slot.tscn")

@onready var item_stats: Control = %ItemStats
@onready var animation_player: AnimationPlayer = %AnimationPlayer

@onready var background_texture: TextureRect = %TextureRect
@onready var card_inventory_container: HBoxContainer = %CardInventoryContainer
@onready var filter_panel: Panel = %FilterPanel
@onready var equipment_slot_container: HBoxContainer = %EquipmentSlotContainer

var is_loading : bool = false

func _ready() -> void:
	BKMREngine.Inventory.open_card_inventory()
	BKMREngine.Inventory.get_card_inventory_complete.connect(card_inventory_open)
	BKMREngine.Inventory.get_card_inventory_complete.connect(equipment_slot_open)

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
		card_inventory_slot.get_node('CardIcon').data_card.connect(_on_inventory_card_pressed)
		
	var empty_card_inventory_slot: int = PLAYER.inventory_size - inventory_data[0].size()
	for _i: int in empty_card_inventory_slot:
		card_inventory_slot = inventory_slot_card.instantiate()
		card_inventory_container.add_child(card_inventory_slot)
		card_inventory_container.move_child(card_inventory_slot, 0)
		card_inventory_slot.get_node('CardIcon').slot_data()
		card_inventory_slot.get_node('CardIcon').data_card.connect(_on_inventory_card_pressed)
		
func equipment_slot_open(inventory_data: Array) -> void:
	for cardslots: TextureRect in get_tree().get_nodes_in_group('CardSlot'):
		cardslots.equipped_card_pressed.connect(_on_equipped_card_pressed)
		cardslots.slot_data()
		
	for card_data: Dictionary in inventory_data[1]:
		var uri: String = card_data.keys()[0]
		match card_data[uri].group:
			"X:IN":
				x_in_equipped(uri, card_data)
				
# Handle equipped cards with group "X:IN"
func x_in_equipped(uri: String, card_data: Dictionary) -> void:
	card_data.origin_equipment_slot = card_data[uri].slot
	for cardslots: TextureRect in get_tree().get_nodes_in_group("X:INSlot"):
		cardslots.equip(uri, card_data, "init")
		
# Callback function for the close button pressed signal.
func _on_close_button_pressed() -> void:
	# Attempt automatic login and wait for the session check to complete.
	BKMREngine.Auth.auto_login_player()
	#BKMREngine.Inventory.update_inventory()


	# Set the previous and next textures for scene transition.
	LOADER.previous_texture = background_texture.texture
	LOADER.next_texture = preload("res://UITextures/BGTextures/main.png")
	
	# Initiate the scene transition.
	var _change_scene: bool = await LOADER.load_scene(self, "res://UIScenes/main_screen.tscn")

func _on_inventory_card_pressed(card_data: Dictionary) -> void:
	if item_stats.is_open == false:
		animation_player.play("item_stats_slide")
		await animation_player.animation_finished
	item_stats_card_data.emit(card_data)

func _on_equipped_card_pressed(card_data: Dictionary) -> void:
	if item_stats.is_open == false:
		animation_player.play("item_stats_slide")
		await animation_player.animation_finished
	item_stats_card_data.emit(card_data)

func _on_item_stats_equip_unequip_pressed() -> void:
	if item_stats.is_open:
		animation_player.play_backwards("item_stats_slide")
		await animation_player.animation_finished
		is_loading = false
		item_stats.is_open = false

func _on_item_stats_close_item_stats_pressed() -> void:
	item_stats.is_open = false
	animation_player.play_backwards("item_stats_slide")
