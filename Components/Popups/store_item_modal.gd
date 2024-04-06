extends Control

#UI Elements
@onready var viewport: Viewport = %SubViewport
@onready var card_texture: Sprite2D = %CardSprite
@onready var animation_player:AnimationPlayer = %AnimationPlayer
@onready var card_mesh: MeshInstance3D = %CardMesh
@onready var loading_filter: Panel = %Panel2
@onready var purchase_label: Label = %PurchaseLabel

@onready var card_name: Label = %CardName
@onready var score_boost: Label = %ScoreBoost
@onready var score_boost_progress: TextureProgressBar = %ScoreBoostProgress
@onready var heal_boost: Label = %HealBoost
@onready var heal_boost_progress: TextureProgressBar = %HealBoostProgress
@onready var rarity: Label = %Rarity
@onready var skill: Label = %Skill
@onready var price: Label = %Price
@onready var buy_button: TextureButton = %BuyButton

# Variables
var cards: Array = []
var card_description: String
var card_slot: String
var card_era: String
var card_rarity: String
var card_id: String
var card_price: String
var card_currency: String

var listing_id: String
var nft_name: String
	
	
# Handle initialization and setup when the node is ready.
func _ready() -> void:
	# Connect the "buy_card_complete" signal to the "_on_buy_completed" function
	var _connect: int = BKMREngine.Store.connect("buy_card_complete", _on_buy_completed)

	# Play the unwrap animation and wait for it to finish
	animation_player.play('unwrap')
	await animation_player.animation_finished
	
	# Play the halfspin animation
	animation_player.play('halfspin')

# Set data and texture for the card.
#
# This function takes a dictionary (data) containing information about the card and a texture
# to be displayed on the card. It updates the card's visual elements with the provided data.
#
# Parameters:
# - data: A dictionary containing information about the card.
# - texture: The texture to be displayed on the card.
#
# Example usage:
# ```gdscript
# set_data(card_data, card_texture)
# ```
func set_data(data: Dictionary, texture: Texture) -> void:
	# Set the albedo texture of the card mesh
	card_mesh.mesh.surface_get_material(0).set("albedo_texture", texture)

	# Extract relevant information from the data dictionary
	var currency_symbol: String = data.currencyValuePerToken.name
	var display_value: String = data.currencyValuePerToken.displayValue

	# Update UI elements with card information
	card_name.text = data.asset.name
	
	score_boost.text = data.asset.scoreBoost
	var score_boost_string: String = data.asset.scoreBoost
	score_boost_progress.value = float(score_boost_string)
	
	var heal_boost_string: String = data.asset.healBoost
	heal_boost.text = data.asset.healBoost
	heal_boost_progress.value = float(heal_boost_string)
	
	rarity.text = data.asset.rarity
	skill.text = data.asset.skill
	price.text = display_value + " " + currency_symbol

	# Set listing_id and nft_name for purchase
	listing_id = data.id
	nft_name = data.asset.name

	# Determine the currency and check player balance to enable/disable buy button
	var currency: String = currency_symbol.to_lower() + "_balance"
	if currency_symbol == "MATIC":
		currency = "native_balance"
	var player_balance: String = PLAYER.get(currency)

	if int(player_balance) == 0:
		buy_button.disabled = true
	elif int(player_balance) < int(display_value):
		buy_button.disabled = true

# Handle close button press.
#
# This function is triggered when the close button is pressed. It plays the "unwrap"
# animation in reverse, waits for the animation to finish, and then hides the control.
#
# Parameters:
# - No explicit parameters are passed to this function.
#
# Returns:
# - This function does not return a value; it operates by playing the animation and hiding the control.
#
# Example usage:
# ```gdscript
# _on_close_button_pressed()
# ```
func _on_close_button_pressed() -> void:
	# Play the "unwrap" animation in reverse
	animation_player.play_backwards("unwrap")
	
	# Wait for the animation to finish
	await animation_player.animation_finished
	
	# Hide the control
	visible = false

# Handle buy button press.
#
# This function is triggered when the buy button is pressed. It prints a test message,
# shows a loading filter, plays the "buy_loading" animation, and initiates the purchase
# of the card through the BKMREngine.Store.buy_card function.
#
# Parameters:
# - No explicit parameters are passed to this function.
#
# Returns:
# - This function does not return a value; it operates by displaying messages and initiating the purchase.
#
# Example usage:
# ```gdscript
# _on_buy_button_pressed()
# ```
func _on_buy_button_pressed() -> void:
	# Print a test message
	print("test")
	
	# Show the loading filter
	loading_filter.visible = true
	
	# Play the "buy_loading" animation
	animation_player.play("buy_loading")

	# Initiate the purchase of the card through the store
	BKMREngine.Store.buy_card(listing_id, nft_name, PLAYER.username)

# Handle buy completion.
#
# This function is triggered when the purchase of a card is completed. It stops the animation_player,
# and updates the purchase_label text based on the success or failure of the purchase.
#
# Parameters:
# - data: A dictionary containing information about the completion status of the purchase.
#
# Returns:
# - This function does not return a value; it operates by stopping the animation and updating the purchase_label.
#
# Example usage:
# ```gdscript
# _on_buy_completed(data)
# ```
func _on_buy_completed(data: Dictionary) -> void:
	# Stop the animation player
	animation_player.stop()
	
	# Check if the purchase was successful
	if data.success:
		# Update the purchase label for a successful purchase
		purchase_label.text = "Purchase Completed"
	else:
		# Update the purchase label with the error message for a failed purchase
		purchase_label.text = data.error

# Handle close transaction button press.
#
# This function is triggered when the close transaction button is pressed. It plays the animation_player
# backwards, awaits the animation to finish, and hides the control.
#
# Parameters:
# - No explicit parameters are passed to this function.
#
# Returns:
# - This function does not return a value; it operates by playing the animation and hiding the control.
#
# Example usage:
# ```gdscript
# _on_close_transaction_pressed()
# ```
func _on_close_transaction_pressed() -> void:
	# Play the animation player backwards
	animation_player.play_backwards("unwrap")
	
	# Wait for the animation to finish
	await animation_player.animation_finished
	
	# Hide the control
	visible = false
