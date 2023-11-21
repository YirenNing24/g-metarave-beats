extends Control

# Reference to the loading wheel and label in the scene.
@onready var loading_wheel: TextureProgressBar = %LoadingWheel
@onready var loading_label: Label = %LoadingLabel
@onready var player: String  # Reference to a player (type not specified).
@onready var transition_texture: TextureRect = %TextureRect  # Reference to a transition texture.

# Reference to the update popup scene.
var app_update: PackedScene = preload("res://Components/Popups/update_popup.tscn")

# Tween object for animations.
var tween: Tween

# Ready function called when the node and its children are added to the scene.
func _ready() -> void:
	# Simulate a loading process.
	fake_loader()
	
	# Check for app updates.
	var result: String = await BKMREngine.Auth.bkmr_version_check_complete
	
	if result == "Your app is up to date!":
		loading_label.text = result
		loading_wheel.value = 0
		session_check()
	elif result == "Please update your app":
		loading_label.text = result
		var update: Control = app_update.instantiate()
		add_child(update)
		update.get_child(0).visible = true

# Check the user session status.
func session_check() -> void:
	BKMREngine.Auth.auto_login_player()
	var session: Dictionary = await BKMREngine.Auth.bkmr_session_check_complete
	print('session: ', session)
	
	if session == {}:
		loading_label.text = "No logged-in account found!"
		change_to_auth_scene()
	else:
		if session.success:
			# Load the main screen if the session is successful.
			LOADER.previous_texture = transition_texture.texture
			var _load_scene: bool = await LOADER.load_scene(self, "res://UIScenes/main_screen.tscn")
			LOADER.next_texture = preload("res://UITextures/BGTextures/main.png")
		
		if session.error:
			if session.error == "jwt expired":
				loading_label.text = "Session expired!"
			else:
				loading_label.text = str(session.error)
			change_to_auth_scene()
	
	# Stop the tween animation.
	tween.kill()

# Simulate a loading animation.
func fake_loader() -> void:
	loading_wheel.value = 0
	tween = get_tree().create_tween()
	
	# Animate the loading wheel value property.
	var _wheel_loader: PropertyTweener = tween.tween_property(loading_wheel, "value", 100, 3.0).set_trans(Tween.TRANS_LINEAR)
	
	# Schedule a callback for fake_loader after the animation completes.
	var _loader_fake: CallbackTweener = tween.tween_callback(fake_loader)

# Switch to the authentication scene after a delay.
func change_to_auth_scene() -> void:
	# Wait for 1 second using a timer.
	await(get_tree().create_timer(1).timeout)
	
	# Stop the tween animation.
	tween.kill()
	
	# Load the authentication scene.
	var _load_scene: bool = await LOADER.load_scene(self, "res://UIScenes/auth_screen.tscn")
	LOADER.previous_texture = transition_texture.texture
	LOADER.next_texture = preload("res://UITextures/BGTextures/auth.png")
