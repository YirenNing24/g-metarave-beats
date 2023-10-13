extends Control

var template_card_slot:PackedScene = preload("res://Components/Store/cards.tscn")

@onready var beats_balance:Label = %BeatsBalance
@onready var native_balance:Label = %Native
@onready var kmr_balance:Label = %KMR
@onready var thump_balance:Label = %ThumpBalance
@onready var background_texture:TextureRect = %BackgroundTexture
@onready var animation_player:AnimationPlayer = %AnimationPlayer
@onready var hero_character:TextureRect = %HeroCharacter

@onready var card_slots = []
@onready var item_grid:GridContainer = %ItemGrid

var cards: Array = []
var packs: Array = []
var is_transaction:bool = false

signal session_check_done
# Called when the node enters the scene tree for the first time.
func _ready():
	beats_balance.text = PLAYER.beats_balance
	native_balance.text = PLAYER.native_balance
	kmr_balance.text = PLAYER.kmr_balance
	thump_balance.text = PLAYER.thump_balance
	
	BKMREngine.Store.connect("buy_card_complete",  card_store_open)
		
		
func _on_texture_button_6_pressed():
	for card in cards:
		var card_name:String = card.asset.name
		print(card_name)
		
		
func _on_cards_button_pressed():
	
	if !cards:
		card_store_open()
		animation_player.play("pulldown")
	else:
		return
		
		
func card_store_open():
	BKMREngine.Store.get_store_items('cards')
	await BKMREngine.Store.get_cards_complete
	cards = BKMREngine.Store.cards_for_sale
	
	for card in cards:
		card_slots = template_card_slot.instantiate()
		var card_name:String = card.asset.name
		var card_tier:String = card.asset.tier
		var remove_space:String = card_name.replace(" ", "_")
		var texture_name:String = (remove_space + '_' + card_tier + ".png").to_lower()
		var card_texture = load("UITextures/Cards/" + texture_name)

		card_slots.get_node('Panel/Icon').texture = card_texture
		card_slots.get_node('Panel/CardName').text = card_name
		card_slots.get_card_data(card)
		item_grid.add_child(card_slots)
	
	
func _on_close_button_pressed():
	BKMREngine.Auth.auto_login_player()
	
	if is_transaction:
		await BKMREngine.Auth.bkmr_session_check_complete
	###create session handler for Dictionary if the value is nil
	LOADER.previous_texture = background_texture.texture
	LOADER.next_texture = preload("res://UITextures/BGTextures/main.png")
	LOADER.load_scene(self, "res://UIScenes/main_screen.tscn")

