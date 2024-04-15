extends Control

@onready var beats_balance:Label = %BeatsBalance
@onready var native_balance:Label = %Native
@onready var gmr_balance:Label = %KMR
@onready var background_texture:TextureRect = %BackgroundTexture

func _ready() -> void:
	hud_data()

func hud_data() -> void:
	beats_balance.text = PLAYER.beats_balance
	native_balance.text = PLAYER.native_balance
	gmr_balance.text = PLAYER.gmr_balance

func _on_card_inventory_pressed() -> void:
	LOADER.previous_texture = background_texture.texture
	LOADER.next_texture = preload("res://UITextures/BGTextures/main_city.png")
	var _change_scene: bool = await LOADER.load_scene(self, "res://UIScenes/card_inventory_screen.tscn")

func _on_close_button_pressed() -> void:
	BKMREngine.Auth.auto_login_player()
	await BKMREngine.Auth.bkmr_session_check_complete
	LOADER.previous_texture = background_texture.texture
	LOADER.next_texture = preload("res://UITextures/BGTextures/main.png")
	var _change_scene: bool = await LOADER.load_scene(self, "res://UIScenes/main_screen.tscn")
