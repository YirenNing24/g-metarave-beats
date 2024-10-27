extends Control

signal store_item_buy_pressed


#UI Elements
@onready var viewport: Viewport = %SubViewport
@onready var card_texture: Sprite2D = %CardSprite
@onready var animation_player:AnimationPlayer = %AnimationPlayer
@onready var loading_filter: Panel = %FilterPanel

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
var card_uri: String
var card_price: String
var card_currency: String

var listing_id: String
var nft_name: String
	
	
# Handle initialization and setup when the node is ready.
func _ready() -> void:
	# Play the halfspin animation
	animation_player.play('halfspin')

# Set data and texture for the card.
func set_data(card_data: Dictionary, texture: Texture) -> void:
	# Set the albedo texture of the card mesh
	%CardMesh.mesh.surface_get_material(0).set("albedo_texture", texture)

	var currency_symbol: String = card_data.currencyName
	var display_value: String = str(card_data.pricePerToken)

	# Update UI elements with card information
	card_name.text = card_data.name
	
	var score_boost_string: String = card_data.scoreboost
	score_boost.text = score_boost_string
	score_boost_progress.value = float(score_boost_string)
	
	var heal_boost_string: String = card_data.healboost
	heal_boost.text =  heal_boost_string
	heal_boost_progress.value = float(heal_boost_string)
	
	rarity.text = card_data.rarity
	skill.text = card_data.skill
	price.text = display_value + " " + currency_symbol
	
	card_uri = card_data.uri
	
	# Set listing_id and nft_name for purchase
	var listing_id_string: String = str(card_data.listingId)
	listing_id = listing_id_string
	nft_name = card_data.name

# Determine the currency and check player balance to enable/disable buy button
func _on_close_button_pressed() -> void:
	visible = false

# Handle buy button press.
func _on_buy_button_pressed() -> void:
	BKMREngine.Store.buy_card(card_uri, int(listing_id))
	store_item_buy_pressed.emit(price.text)

# Handle close transaction button press.
func _on_close_transaction_pressed() -> void:
	visible = false
