extends Control
#TODO loading effect while waiting for card inventory retrieval to finish
#TODO cards are getting clipped on the left side

signal item_stats_card_data

var inventory_slot_card: PackedScene = preload("res://Components/Inventory/card_inventory_slot.tscn")

@onready var item_stats: Control = %ItemStats
@onready var animation_player: AnimationPlayer = %AnimationPlayer

@onready var background_texture: TextureRect = %TextureRect
@onready var card_inventory_container: HBoxContainer = %CardInventoryContainer
@onready var inventory_scroll: ScrollContainer = %InventoryScroll
@onready var filter_panel: Panel = %FilterPanel
@onready var equipment_slot_container: HBoxContainer = %EquipmentSlotContainer

var is_loading : bool = false

func _ready() -> void:
	BKMREngine.Inventory.open_card_inventory()
	BKMREngine.Inventory.get_card_inventory_complete.connect(card_inventory_open)
	BKMREngine.Inventory.get_card_inventory_complete.connect(equipment_slot_open)
	
func card_inventory_open(inventory_data: Array) -> void:
	var card_inventory_slot: Control
	for card_data: Dictionary in inventory_data:
		card_inventory_slot = inventory_slot_card.instantiate()
		var uri: String = card_data.keys()[0]

		var card_name: String = card_data[uri]["name"].replace(" ", "_").to_lower()
		var card_texture: Texture = load("res://UITextures/Cards/" + card_name + ".png")
		
		card_inventory_slot.get_node('CardIcon').set_texture(card_texture)
		card_inventory_container.add_child(card_inventory_slot)
		card_inventory_container.move_child(card_inventory_slot, 0)
		
		card_inventory_slot.get_node('CardIcon').slot_data(card_data)
		card_inventory_slot.get_node('CardIcon').data_card.connect(_on_card_pressed)

	#Initialize the scroll animation in the card container once all cards have been added
	inventory_scroll.initialize_scrolling()

func equipment_slot_open(inventory_data: Array) -> void:
	for cardslots: TextureRect in get_tree().get_nodes_in_group('CardSlot'):
		cardslots.data_card.connect(_on_equipment_pressed)
		
	for card_data: Dictionary in inventory_data:
		for cardslots: TextureRect in get_tree().get_nodes_in_group('CardSlot'):
			cardslots.slot_data(card_data)

# Callback function for the close button pressed signal.
func _on_close_button_pressed() -> void:
	# Attempt automatic login and wait for the session check to complete.
	BKMREngine.Auth.auto_login_player()
	#BKMREngine.Inventory.update_inventory()
	await BKMREngine.Auth.bkmr_session_check_complete

	# Set the previous and next textures for scene transition.
	LOADER.previous_texture = background_texture.texture
	LOADER.next_texture = preload("res://UITextures/BGTextures/main.png")
	
	# Initiate the scene transition.
	var _change_scene: bool = await LOADER.load_scene(self, "res://UIScenes/main_screen.tscn")

func _on_card_pressed(card_data: Dictionary) -> void:
	
	print(card_data)
	if item_stats.is_open == false:
		animation_player.play("item_stats_slide")
		await animation_player.animation_finished
		
	item_stats_card_data.emit(card_data)

func _on_equipment_pressed(card_data: Dictionary) -> void:
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
