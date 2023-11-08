extends Control

@onready var background_texture:TextureRect = %TextureRect


func _ready() -> void:
	pass
	
func _on_close_button_pressed() -> void:
	BKMREngine.Auth.auto_login_player()
	await BKMREngine.Auth.bkmr_session_check_complete
	
	LOADER.previous_texture = background_texture.texture
	LOADER.next_texture = preload("res://UITextures/BGTextures/main.png")
	var _change_scene: bool = await LOADER.load_scene(self, "res://UIScenes/main_screen.tscn")
	 
