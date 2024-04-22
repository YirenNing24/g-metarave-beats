extends Control

var template_card_slot: PackedScene = preload("res://Components/Store/cards.tscn")
var store_item_modal: Control = preload("res://Components/Popups/store_item_modal.tscn").instantiate()

@onready var beats_balance: Label = %BeatsBalance
@onready var native_balance: Label = %Native
@onready var kmr_balance: Label = %KMR
@onready var thump_balance: Label = %ThumpBalance
@onready var background_texture: TextureRect = %BackgroundTexture
#@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var hero_character: TextureRect = %HeroCharacter
@onready var card_slots: Node
@onready var item_grid: GridContainer = %ItemGrid
@onready var cursor_spark: GPUParticles2D = %CursorSpark

var is_transaction: bool = false


func _ready() -> void:
	signal_connect()
	add_child(store_item_modal)
	store_item_modal.visible = false
	
func signal_connect() -> void:
	BKMREngine.Store.get_valid_cards_complete.connect(_on_get_valid_cards_complete)

func _on_get_valid_cards_complete(cards :Array) -> void:
	for items: Control in item_grid.get_children():
		items.queue_free()
	
	
	for card: Dictionary in cards:
		card_slots = template_card_slot.instantiate()
		var card_name: String = card.name
		var remove_space: String = card_name.replace(" ", "_")
		var texture_name: String = (remove_space + ".png").to_lower()
		var card_texture: Resource = load("UITextures/Cards/" + texture_name)
		# Set card slot properties.
		card_slots.get_node('Panel/Icon').texture = card_texture
		card_slots.get_node('Panel/CardName').text = card_name
		card_slots.show_item_store_modal.connect(_on_show_item_store_modal)
		
		item_grid.add_child(card_slots)
		card_slots.get_card_data(card)

func _on_show_item_store_modal(card_data: Dictionary, texture: Texture) -> void:
	store_item_modal.set_data(card_data, texture)
	store_item_modal.visible = true
	
func _on_cards_button_pressed() -> void:
	BKMREngine.Store.get_valid_cards()
	
func _input(event: InputEvent) -> void:
	# Handle screen touch events.
	if event is InputEventScreenTouch:
		if event.pressed:
			# Check if the touch event is within the bounds of the notepicker node.
			var position_event: Vector2 = event.position
			cursor_spark.position = position_event
			cursor_spark.emitting = true
	elif event is InputEventScreenDrag:
		var position_event: Vector2 = event.position
		cursor_spark.position = position_event
		cursor_spark.emitting = true


func _on_close_button_pressed() -> void:
	# Perform actions on close button press.
	BKMREngine.Auth.auto_login_player()

	# If a transaction is ongoing, wait for session check to complete.
	if is_transaction:
		await BKMREngine.Auth.bkmr_session_check_complete
	
	# Update scene transition textures and load the main screen scene.
	LOADER.previous_texture = background_texture.texture
	LOADER.next_texture = preload("res://UITextures/BGTextures/main.png")
	var _change_scene: bool = await LOADER.load_scene(self, "res://UIScenes/main_screen.tscn")
