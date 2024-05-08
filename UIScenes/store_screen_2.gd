extends Control

var template_card_slot_scene: PackedScene = preload("res://Components/Store/cards.tscn")
var template_card_upgrade_slot_scene: PackedScene = preload("res://Components/Store/card_upgrade.tscn")
var store_item_modal: Control = preload("res://Components/Popups/store_item_modal.tscn").instantiate()

@onready var beats_balance: Label = %BeatsBalance
@onready var native_balance: Label = %Native
@onready var gmr_balance: Label = %KMR
@onready var thump_balance: Label = %ThumpBalance
@onready var background_texture: TextureRect = %BackgroundTexture
#@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var hero_character: TextureRect = %HeroCharacter
@onready var card_slots: Node
@onready var item_grid: GridContainer = %ItemGrid
@onready var cursor_spark: GPUParticles2D = %CursorSpark

@onready var confirm_yes_button: TextureButton = %YesButton
@onready var confirm_label: Label = %ConfirmLabel

var is_transaction: bool = false


func _ready() -> void:
	signal_connect()
	add_child(store_item_modal)
	hud_data()
	store_item_modal.visible = false
	
func hud_data() -> void:
	beats_balance.text = PLAYER.beats_balance
	native_balance.text = PLAYER.native_balance
	gmr_balance.text = PLAYER.gmr_balance
	
func signal_connect() -> void:
	store_item_modal.store_item_buy_pressed.connect(_on_store_item_modal_buy_pressed)
	BKMREngine.Store.get_valid_cards_complete.connect(_on_get_valid_cards_complete)
	BKMREngine.Store.get_valid_card_upgrades_complete.connect(_on_get_valid_card_upgrades_complete)
	BKMREngine.Store.buy_card_upgrade_item_complete.connect(_on_buy_card_upgrades_complete)
	BKMREngine.Store.buy_card_complete.connect(_on_buy_card_complete)
	
func _on_get_valid_cards_complete(cards :Array) -> void:
	clear_grid()
	for card: Dictionary in cards:
		card_slots = template_card_slot_scene.instantiate()
		var card_name: String = card.name
		var remove_space: String = card_name.replace(" ", "_")
		var texture_name: String = (remove_space + ".png").to_lower()
		var card_texture: Resource = load("UITextures/Cards/" + texture_name)
		var price: int = card.pricePerToken
		
		# Set card slot properties.
		card_slots.show_item_store_modal.connect(_on_show_item_store_modal)
		card_slots.card_buy_button_pressed.connect(_on_card_slot_buy_button_pressed)
		card_slots.get_node('Panel2/Icon').texture = card_texture
		card_slots.get_node('BuyButton/HBoxContainer/Price').text = str(price)
		
		item_grid.add_child(card_slots)
		card_slots.get_card_data(card)
		
func _on_card_slot_buy_button_pressed(card_data: Dictionary) -> void:
	%FilterPanel.visible = true
	confirm_label.text = "Are you sure 
	you want to buy " + card_data.name.to_upper() + " " + str(card_data.pricePerToken) + " BEATS" + "?"
	var _connected: bool = confirm_yes_button.pressed.is_connected(_on_yes_button_pressed)
	if _connected == false:
		var _connect: int = confirm_yes_button.pressed.connect(_on_yes_button_pressed. bind(card_data, "Card"))

func _on_get_valid_card_upgrades_complete(upgrades: Array) -> void:
	clear_grid()
	for upgrade_item: Dictionary in upgrades:
		var template_card_upgrade_slot: Control = template_card_upgrade_slot_scene.instantiate()
		if upgrade_item.tier == "tier1":
			var item_texture: Texture = load("res://UITextures/CardUpgrades/general_tier1.png")
			template_card_upgrade_slot.get_node("Panel/CardupgradeIcon").texture = item_texture
		
		var price_per_token: int = upgrade_item.pricePerToken 
		var quantity: int = upgrade_item.quantity
		var price: int = int(price_per_token * quantity)
		template_card_upgrade_slot.get_node("BuyButton/HBoxContainer/Price").text = format_balance(str(price))
		template_card_upgrade_slot.get_node("Panel/Quantity").text = format_balance(str(quantity))
		template_card_upgrade_slot.card_upgrade_data(upgrade_item)
		
		template_card_upgrade_slot.buy_button_pressed.connect(_on_get_valid_cards_buy_button_pressed)
		item_grid.add_child(template_card_upgrade_slot)
		
func _on_get_valid_cards_buy_button_pressed(item_data: Dictionary, type: String) -> void:
	%FilterPanel.visible = true
	var _connected: bool = confirm_yes_button.pressed.is_connected(_on_yes_button_pressed)
	if _connected == false:
		var _connect: int = confirm_yes_button.pressed.connect(_on_yes_button_pressed. bind(item_data, type))

	confirm_label.text = "Are you sure you want to buy Card Upgrade " + item_data.tier.to_upper()
		
func _on_yes_button_pressed(item_data: Dictionary, item_type: String) -> void:
	
	match item_type:
		"CardUpgrade":
			buy_card_upgrade(item_data)
		"Card":
			pass
		
func buy_card(item_data: Dictionary) -> void:
	var listingId: int = item_data.ListingId
	BKMREngine.Store.buy_card(item_data.uri, listingId)
		
func _on_buy_card_complete() -> void:
	%LoadingPanel.tween_kill()

func _on_store_item_modal_buy_pressed() -> void:

	%LoadingPanel.fake_loader()

func buy_card_upgrade(item_data: Dictionary) -> void:
	var buy_card_data: Dictionary = {
		"uri": item_data.uri,
		"listingId": item_data.listingId,
		"quantity": str(item_data.quantity)
	}
	BKMREngine.Store.buy_card_upgrade(buy_card_data)
	%LoadingPanel.fake_loader()

func _on_no_button_pressed() -> void:
	%FilterPanel.visible = false

func _on_buy_card_upgrades_complete(_message: Dictionary) -> void:
	BKMREngine.Store.get_valid_card_upgrades()
	%LoadingPanel.tween_kill()

func _on_show_item_store_modal(card_data: Dictionary, texture: Texture) -> void:
	store_item_modal.set_data(card_data, texture)
	store_item_modal.visible = true
	
func _on_cards_button_pressed() -> void:
	BKMREngine.Store.get_valid_cards()
	
func _on_card_upgrade_button_pressed() -> void:
	BKMREngine.Store.get_valid_card_upgrades()

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

	if is_transaction:
		await BKMREngine.Auth.bkmr_session_check_complete
	
	# Update scene transition textures and load the main screen scene.
	LOADER.previous_texture = background_texture.texture
	LOADER.next_texture = preload("res://UITextures/BGTextures/main.png")
	var _change_scene: bool = await LOADER.load_scene(self, "res://UIScenes/main_screen.tscn")

func clear_grid() -> void:
	for items: Control in item_grid.get_children():
		items.queue_free()

func format_balance(value: String) -> String:
	var parts: Array = value.split(".")
	var wholePart: String = parts[0]
	
	# Add commas for every three digits in the whole part.
	var formattedWholePart: String = ""
	var digitCount: int = 0
	for i: int in range(wholePart.length() - 1, -1, -1):
		formattedWholePart = wholePart[i] + formattedWholePart
		digitCount += 1
		if digitCount == 3 and i != 0:
			formattedWholePart = "," + formattedWholePart
			digitCount = 0
	return formattedWholePart

func _on_filter_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		%FilterPanel.visible = false
