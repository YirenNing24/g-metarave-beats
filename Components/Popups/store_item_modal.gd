extends Control

@onready var viewport: Viewport = %SubViewport
@onready var card_texture: Sprite2D = %CardSprite
@onready var animation_player:AnimationPlayer = %AnimationPlayer
@onready var card_mesh: MeshInstance3D = %CardMesh
@onready var loading_filter: Panel = %Panel2
@onready var purchase_label: Label = %PurchaseLabel

var cards: Array = []
var card_description: String
var card_slot: String
var card_era: String
var card_rarity: String
var card_id: String
var card_price: String
var card_currency: String

@onready var card_name: Label = %CardName
@onready var score_boost: Label = %ScoreBoost
@onready var score_boost_progress: TextureProgressBar = %ScoreBoostProgress
@onready var heal_boost: Label = %HealBoost
@onready var heal_boost_progress: TextureProgressBar = %HealBoostProgress
@onready var rarity: Label = %Rarity
@onready var skill: Label = %Skill
@onready var price: Label = %Price
@onready var buy_button: TextureButton = %BuyButton

var listing_id: String
var nft_name: String
	
	
func _ready() -> void:
	var _connect : int = BKMREngine.Store.connect("buy_card_complete",  _on_buy_completed)
	
	animation_player.play('unwrap')
	await animation_player.animation_finished
	animation_player.play('halfspin')
	
	
func set_data(data: Dictionary, texture: Texture) -> void:
	card_mesh.mesh.surface_get_material(0).set("albedo_texture", texture)
	
	var currency_symbol:String = data.currencyValuePerToken.name
	var display_value:String = data.currencyValuePerToken.displayValue
	
	card_name.text = data.asset.name
	score_boost.text  = data.asset.scoreBoost
	
	var card_score_boost: String = data.asset.scoreBoost
	score_boost_progress.value = float(card_score_boost)
	
	heal_boost.text  = data.asset.healBoost
	var card_heal_boost: String = data.asset.healBoost
	heal_boost_progress.value = float(card_heal_boost)
	rarity.text = data.asset.rarity
	skill.text = data.asset.skill
	price.text = display_value + " " + currency_symbol
	
	listing_id = data.id
	nft_name = data.asset.name
	
	var currency:String = currency_symbol.to_lower() + "_balance"
	if currency_symbol == "MATIC":
		currency = "native_balance"
	var player_balance:String = PLAYER.get(currency)
	
	if int(player_balance) == 0:
		buy_button.disabled = true
	elif int(player_balance) < int(display_value):
		buy_button.disabled = true
		


func _on_close_button_pressed() -> void:
	animation_player.play_backwards("unwrap")
	await animation_player.animation_finished
	hide()
	
	
func _on_buy_button_pressed() -> void:
	print("test")
	loading_filter.show()
	animation_player.play("buy_loading")

	BKMREngine.Store.buy_card(listing_id, nft_name, PLAYER.username )
	
	
func _on_buy_completed(data: Dictionary) -> void:
	animation_player.stop()
	if data.success:
		purchase_label.text = "Purchase Completed"
	else:
		purchase_label.text = data.error 
		
		
func _on_close_transaction_pressed() -> void:
	animation_player.play_backwards("unwrap")
	await animation_player.animation_finished
	hide()
