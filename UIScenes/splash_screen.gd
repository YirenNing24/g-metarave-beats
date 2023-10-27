extends Control

@onready var loading_wheel: TextureProgressBar = %LoadingWheel
@onready var loading_label: Label = %LoadingLabel
@onready var player: String
@onready var transition_texture: TextureRect = %TextureRect
  
var app_update: PackedScene = preload("res://Components/Popups/update_popup.tscn")
var tween: Tween

func _ready() -> void:
	fake_loader()
	
	var result: String = await BKMREngine.Auth.bkmr_version_check_complete
	if result == "Your app is up to date!":
		loading_label.text = result
		loading_wheel.value = 0
		session_check()
	elif result == "Please update your app":
		loading_label.text = result
		var update: Control = app_update.instantiate()
		add_child(update)
		update.get_child(0).set_visible(true)
		
func session_check() -> void:
	BKMREngine.Auth.auto_login_player()
	var session: Dictionary = await BKMREngine.Auth.bkmr_session_check_complete
	if session == {}:
		loading_label.text = "No logged in account found!"
		change_to_auth_scene()
	else:
		LOADER.previous_texture = transition_texture.texture
		var _load_scne: bool = await LOADER.load_scene(self, "res://UIScenes/main_screen.tscn")
		LOADER.next_texture = preload("res://UITextures/BGTextures/main.png")
		
	tween.kill()
		
func fake_loader() -> void:
	loading_wheel.value = 0
	tween = get_tree().create_tween()
	var _wheel_loader: PropertyTweener = tween.tween_property(loading_wheel, "value", 100, 3.0).set_trans(Tween.TRANS_LINEAR)
	var _loader_fake: CallbackTweener = tween.tween_callback(fake_loader)
	
func change_to_auth_scene()  -> void:
	await(get_tree().create_timer(1).timeout)
	tween.kill()
	var _load_scene : bool = await LOADER.load_scene(self, "res://UIScenes/auth_screen.tscn")
	LOADER.previous_texture = transition_texture.texture
	LOADER.next_texture = preload("res://UITextures/BGTextures/auth.png")
