extends Control

# Reference to the card slot scene.
var template_card_slot: PackedScene = preload("res://Components/Store/cards.tscn")

# UI elements
@onready var beats_balance: Label = %BeatsBalance
@onready var native_balance: Label = %Native
@onready var kmr_balance: Label = %KMR
@onready var thump_balance: Label = %ThumpBalance
@onready var background_texture: TextureRect = %BackgroundTexture
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var hero_character: TextureRect = %HeroCharacter
@onready var card_slots: Node
@onready var item_grid: GridContainer = %ItemGrid
@onready var cursor_spark: GPUParticles2D = %CursorSpark

# Arrays to store card and pack data.
var cards: Array = []
var packs: Array = []

# Flag to track ongoing transactions.
var is_transaction: bool = false

# Signal emitted when the session check is done.
#signal session_check_done

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Initialize UI with player balances.
	beats_balance.text = PLAYER.beats_balance
	native_balance.text = PLAYER.native_balance
	kmr_balance.text = PLAYER.kmr_balance
	thump_balance.text = PLAYER.thump_balance
	#BKMREngine.Store.get_valid_cards_complete.connect(_on_get_cards_complete)

# Callback function when the "Texture Button 6" is pressed.
func _on_texture_button_6_pressed() -> void:
	# Iterate through available cards and print their names.
	for card: Dictionary in cards:
		var card_name: String = card.asset.name
		print(card_name)

# Callback function when the "Cards Button" is pressed.
func _on_cards_button_pressed() -> void:
	# Open the card store if no cards are currently loaded.
	if !cards:
		animation_player.play("pulldown")
	else:
		return

# Function to handle getting cards.
func _on_get_cards_complete(card_data: Array) -> void:
	BKMREngine.Store.get_cards()
	for card: Dictionary in card_data:
		card_slots = template_card_slot.instantiate()
		var card_name: String = card.name
		var card_tier: String = card.tier
		var remove_space: String = card_name.replace(" ", "_")
		var texture_name: String = (remove_space + '_' + card_tier + ".png").to_lower()
		var card_texture: Resource = load("UITextures/Cards/" + texture_name)

		# Set card slot properties.
		card_slots.get_node('Panel/Icon').texture = card_texture
		card_slots.get_node('Panel/CardName').text = card_name
		card_slots.get_card_data(card)
		item_grid.add_child(card_slots)

# Callback function when the "Close Button" is pressed.
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
