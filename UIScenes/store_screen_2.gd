extends Control

#TODO remove excess hud stuff

const template_card_slot_scene: PackedScene = preload("res://Components/Store/cards.tscn")
const template_card_upgrade_slot_scene: PackedScene = preload("res://Components/Store/card_upgrade.tscn")
const template_card_pack_slot_scene: PackedScene = preload("res://Components/Store/card_pack.tscn")
var store_item_modal: Control = preload("res://Components/Popups/store_item_modal.tscn").instantiate()

@onready var beats_balance: Label = %BeatsBalance
@onready var gmr_balance: Label = %GMR

@onready var background_texture: TextureRect = %BackgroundTexture
@onready var hero_character: TextureRect = %HeroCharacter
@onready var card_slots: Node
@onready var item_grid: GridContainer = %ItemGrid
@onready var cursor_spark: GPUParticles2D = %CursorSpark

@onready var confirm_yes_button: TextureButton = %YesButton
@onready var confirm_label: Label = %ConfirmLabel

var is_transaction: bool = false
var price_recent: int

var recharge_progress: float = 0.0
var time_until_next_recharge : int
var recharge_interval : int = 60 * 60 * 1000 # 1 hour in milliseconds


func _ready() -> void:
	signal_connect()
	add_child(store_item_modal)
	hud_data()
	store_item_modal.visible = false
	
	
func _process(delta: float) -> void:
	BKMREngine.Server.websocket.close()
	BKMREngine.Server.websocket.poll()
	
	if PLAYER.current_energy >= PLAYER.max_energy:
		# Max energy reached, hide recharge label
		%EnergyRecharge.visible = false
		return

	# Recharge countdown is active
	time_until_next_recharge -= int(delta * 1000)
	if time_until_next_recharge > 0:
		recharge_progress = 100.0 - (float(time_until_next_recharge) / float(recharge_interval)) * 100.0
		%EnergyRecharge.text = str(int(recharge_progress)) + "%"
		%EnergyRecharge.visible = true
	else:
		# Recharge complete: add energy and reset countdown
		PLAYER.current_energy += 1
		%Energy.text = str(PLAYER.current_energy) + " / " + str(PLAYER.max_energy)

		if PLAYER.current_energy < PLAYER.max_energy:
			time_until_next_recharge = recharge_interval
			%EnergyRecharge.text = "1%"
		else:
			# Energy is maxed out, hide recharge progress
			%EnergyRecharge.visible = false
	
	
func hud_data() -> void:
	BKMREngine.Energy.get_energy_drink()
	beats_balance.text = PLAYER.beats_balance
	gmr_balance.text = PLAYER.gmr_balance
	energy_hud()
	
	
func energy_hud() -> void:
	%Energy.text = str(PLAYER.current_energy) + " " + "/" + " " + str(PLAYER.max_energy)
	if PLAYER.time_until_next_recharge != 0:
		start_recharge_countdown(PLAYER.time_until_next_recharge)
	
	
func start_recharge_countdown(time_until_next: int) -> void:
	time_until_next_recharge = time_until_next
	recharge_progress = 0.0
	
	
func signal_connect() -> void:
	store_item_modal.store_item_buy_pressed.connect(_on_store_item_modal_buy_pressed)
	BKMREngine.Store.get_valid_cards_complete.connect(_on_get_valid_cards_complete)
	BKMREngine.Store.get_valid_card_upgrades_complete.connect(_on_get_valid_card_upgrades_complete)
	BKMREngine.Store.get_valid_card_packs_complete.connect(_on_get_valid_card_packs_complete)
	BKMREngine.Store.buy_card_upgrade_item_complete.connect(_on_buy_card_upgrades_complete)
	BKMREngine.Store.buy_card_complete.connect(_on_buy_card_complete)
	BKMREngine.Store.buy_card_pack_complete.connect(_on_buy_card_pack_complete)
	
	
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
	%LoadingPanel.tween_kill()
		
		
func _on_card_slot_buy_button_pressed(card_data: Dictionary) -> void:
	@warning_ignore("unsafe_call_argument")
	var afford: bool = check_cost_and_funds(card_data.pricePerToken)
	if not afford:
		return
		
	%FilterPanel.visible = true
	confirm_label.text = "Are you sure 
	you want to buy " + card_data.name.to_upper() + " " + str(card_data.pricePerToken) + " BEATS" + "?"
	var connected: bool = confirm_yes_button.pressed.is_connected(_on_yes_button_pressed)
	if not connected:
		var _connect: int = confirm_yes_button.pressed.connect(_on_yes_button_pressed.bind(card_data, "Card"))


func check_cost_and_funds(price: int) -> bool:
	if int(beats_balance.text) > price:
		return true
	else:
		%ErrorMessage.text = ("Not enough funds")
		%AnimationPlayer.play("ErrorMessage")
		return false
	
	
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
		
		
func _on_get_valid_card_packs_complete(card_packs: Array) -> void:
	clear_grid()
	var card_pack_slot: Control
	for card_pack: Dictionary in card_packs:
		card_pack_slot = template_card_pack_slot_scene.instantiate()
		var price_per_token: int = card_pack.pricePerToken 
		var quantity: int = card_pack.quantity

		card_pack_slot.get_node("BuyButton/HBoxContainer/Price").text = format_balance(str(price_per_token))
		card_pack_slot.get_node("Panel/Quantity").text = format_balance(str(quantity))
		card_pack_slot.card_pack_data(card_pack)
		card_pack_slot.buy_button_pressed.connect(_on_get_valid_card_packs_buy_button_pressed)
		item_grid.add_child(card_pack_slot)
		
		
func _on_get_valid_cards_buy_button_pressed(item_data: Dictionary, type: String) -> void:
	%FilterPanel.visible = true
	var _connected: bool = confirm_yes_button.pressed.is_connected(_on_yes_button_pressed)
	if _connected == false:
		var _connect: int = confirm_yes_button.pressed.connect(_on_yes_button_pressed. bind(item_data, type))
	confirm_label.text = "Are you sure you want to buy Card Upgrade " + item_data.tier.to_upper()
		
		
func _on_get_valid_card_packs_buy_button_pressed(item_data: Dictionary, type: String)  -> void:
	%FilterPanel.visible = true
	var _connected: bool = confirm_yes_button.pressed.is_connected(_on_yes_button_pressed)
	if _connected == false:
		var _connect: int = confirm_yes_button.pressed.connect(_on_yes_button_pressed. bind(item_data, type))
	confirm_label.text = "Are you sure you want to buy Card pack " + item_data.name.to_upper()
		
		
func _on_yes_button_pressed(item_data: Dictionary, item_type: String) -> void:
	match item_type:
		"CardUpgrade":
			buy_card_upgrade(item_data)
		"Card":
			buy_card(item_data)
		"CardPack":
			buy_card_pack(item_data)
		
		
func buy_card(item_data: Dictionary) -> void:
	@warning_ignore("unsafe_call_argument")
	var listingId: int = int(item_data.listingId)
	price_recent = item_data.pricePerToken
	BKMREngine.Store.buy_card(item_data.uri, listingId, str(price_recent))
	%LoadingPanel.fake_loader()
		
		
func _on_buy_card_complete(_message: Dictionary) -> void:
	if store_item_modal.visible:
		store_item_modal.visible = false
	%LoadingPanel.tween_kill()
	%FilterPanel.visible = false
	
	var current_beats_balance: int = beats_balance.text.to_int()
	if not _message.has("error"):
		if current_beats_balance != 0:
			beats_balance.text = format_balance(str(current_beats_balance - price_recent))
			
	confirm_yes_button.pressed.disconnect(_on_yes_button_pressed)
	%LoadingPanel.fake_loader()
	BKMREngine.Store.get_valid_cards()

	
func _on_store_item_modal_buy_pressed(recent_price: String) -> void:
	price_recent = recent_price.to_int()
	%LoadingPanel.fake_loader()


func buy_card_upgrade(item_data: Dictionary) -> void:
	var buy_card_data: Dictionary = {
		"uri": item_data.uri,
		"listingId": item_data.listingId,
		"quantity": str(item_data.quantity)
	}
	BKMREngine.Store.buy_card_upgrade(buy_card_data)
	%LoadingPanel.fake_loader()


func buy_card_pack(item_data: Dictionary) -> void:
	var listingId: int = item_data.listingId
	price_recent = item_data.pricePerToken
	BKMREngine.Store.buy_card_pack(item_data.uri, listingId)
	%LoadingPanel.fake_loader()
		
		
func _on_buy_card_pack_complete(_message: Dictionary) -> void:
	if store_item_modal.visible:
		store_item_modal.visible = false
	%LoadingPanel.tween_kill()
	%FilterPanel.visible = false
	var current_beats_balance: int = int(beats_balance.text)
	
	if not _message.has("error"):
		if current_beats_balance != 0:
			beats_balance.text = format_balance(str(current_beats_balance - price_recent))
	BKMREngine.Store.get_valid_card_packs()
	
	
func _on_no_button_pressed() -> void:
	%FilterPanel.visible = false


func _on_buy_card_upgrades_complete(_message: Dictionary) -> void:
	if not _message.has("error"):
		pass
	BKMREngine.Store.get_valid_card_upgrades()
	%LoadingPanel.tween_kill()


func _on_show_item_store_modal(card_data: Dictionary, texture: Texture) -> void:
	store_item_modal.set_data(card_data, texture)
	store_item_modal.visible = true
	
	
func _on_cards_button_pressed() -> void:
	%LoadingPanel.fake_loader()
	BKMREngine.Store.get_valid_cards()
	
	
func _on_card_pack_button_pressed() -> void:
	BKMREngine.Store.get_valid_card_packs()
	
	
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
	BKMREngine.Auth.auto_login_player()
	if is_transaction:
		await BKMREngine.Auth.bkmr_session_check_complete
	# Update scene transition textures and load the main screen scene.
	LOADER.previous_texture = background_texture.texture
	LOADER.next_texture = preload("res://UITextures/BGTextures/main_city.png")
	var _change_scene: bool = await LOADER.load_scene(self, "res://UIScenes/main_screen.tscn")


func clear_grid() -> void:
	for items: Control in item_grid.get_children():
		items.queue_free()


func format_balance(value: String) -> String:
	var parts: Array = value.split(".")
	var whole_part: String = parts[0]
	var formatted_whole_part: String = ""
	var digit_count: int = 0

	for i: int in range(whole_part.length() - 1, -1, -1):
		formatted_whole_part = whole_part[i] + formatted_whole_part
		digit_count += 1
		if digit_count == 3 and i != 0:
			formatted_whole_part = "," + formatted_whole_part
			digit_count = 0

	return formatted_whole_part


func _on_filter_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		%FilterPanel.visible = false


func _on_energy_button_pressed() -> void:
	pass # Replace with function body.
