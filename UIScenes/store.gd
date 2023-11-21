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

# Arrays to store card and pack data.
var cards: Array = []
var packs: Array = []

# Flag to track ongoing transactions.
var is_transaction: bool = false

# Signal emitted when the session check is done.
signal session_check_done

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Initialize UI with player balances.
	beats_balance.text = PLAYER.beats_balance
	native_balance.text = PLAYER.native_balance
	kmr_balance.text = PLAYER.kmr_balance
	thump_balance.text = PLAYER.thump_balance

	# Connect the buy_card_complete signal to the card_store_open function.
	var _connect: int = BKMREngine.Store.connect("buy_card_complete",  card_store_open)

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
		card_store_open()
		animation_player.play("pulldown")
	else:
		return

# Function to handle card store opening.
func card_store_open() -> void:
	# Retrieve and display available cards in the store.
	BKMREngine.Store.get_store_items('cards')
	await BKMREngine.Store.get_cards_complete
	cards = BKMREngine.Store.cards_for_sale
	
	for card: Dictionary in cards:
		card_slots = template_card_slot.instantiate()
		var card_name: String = card.asset.name
		var card_tier: String = card.asset.tier
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
