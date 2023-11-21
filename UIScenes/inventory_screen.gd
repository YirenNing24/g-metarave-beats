extends Control

# Reference to the background texture.
@onready var background_texture: TextureRect = %TextureRect

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Callback function for the close button pressed signal.
func _on_close_button_pressed() -> void:
	# Attempt automatic login and wait for the session check to complete.
	BKMREngine.Auth.auto_login_player()
	await BKMREngine.Auth.bkmr_session_check_complete
	
	# Set the previous and next textures for scene transition.
	LOADER.previous_texture = background_texture.texture
	LOADER.next_texture = preload("res://UITextures/BGTextures/main.png")
	
	# Initiate the scene transition.
	var _change_scene: bool = await LOADER.load_scene(self, "res://UIScenes/main_screen.tscn")
