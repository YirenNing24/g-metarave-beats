extends Control

@onready var beats_balance:Label = %BeatsBalance
@onready var native_balance:Label = %Native
@onready var kmr_balance:Label = %KMR
@onready var thump_balance:Label = %ThumpBalance
@onready var background_texture:TextureRect = %BackgroundTexture

func _ready():
	hud_data()


func hud_data():
	beats_balance.text = PLAYER.beats_balance
	native_balance.text = PLAYER.native_balance
	kmr_balance.text = PLAYER.kmr_balance
	thump_balance.text = PLAYER.thump_balance


func _on_card_inventory_pressed():
	LOADER.previous_texture = background_texture.texture
	LOADER.next_texture = preload("res://UITextures/BGTextures/inventory_bg.png")
	LOADER.load_scene(self, "res://UIScenes/inventory_screen.tscn")


func _on_close_button_pressed():
	BKMREngine.Auth.auto_login_player()
	await BKMREngine.Auth.bkmr_session_check_complete
	
	LOADER.previous_texture = background_texture.texture
	LOADER.next_texture = preload("res://UITextures/BGTextures/main.png")
	LOADER.load_scene(self, "res://UIScenes/main_screen.tscn")
