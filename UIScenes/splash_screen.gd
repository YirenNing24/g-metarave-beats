extends Control

# Reference to the loading wheel and label in the scene.
#@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var loading_wheel: TextureProgressBar = %LoadingWheel
@onready var loading_label: Label = %LoadingLabel
@onready var player: String  # Reference to a player (type not specified).
@onready var transition_texture: TextureRect = %TextureRect  # Reference to a transition texture.
#@onready var cursor_spark: GPUParticles2D = %CursorSpark

# Reference to the update popup scene.
#var app_update: PackedScene = preload("res://Components/Popups/update_popup.tscn")
var google_sign_in_retries: int = 5
# Tween object for animations.
var tween: Tween

# Ready function called when the node and its children are added to the scene.
func _ready() -> void:
	fake_loader()
	#google_auth()
	
	BKMREngine.Auth.bkmr_session_check_complete.connect(_on_session_check)
	%LoadingLabel2.text = BKMREngine.Auth.last_login_type
	# Create and start a timer for the delay
	var _timer: int = get_tree().create_timer(3.0).timeout.connect(_on_timer_timeout)


# Callback to handle the timer timeout
func _on_timer_timeout() -> void:
	BKMREngine.Auth.auto_login_player()
	
	

#func google_auth() -> void: 
	#var _token: int = SignInClient.server_side_access_requested.connect(_on_google_token_generated)
	#var _connect: int = SignInClient.user_authenticated.connect(google_authenticated)
	#
#func google_authenticated(is_authenticated: bool) -> void:
	#if google_sign_in_retries > 0 and not is_authenticated:
		#if is_authenticated:
			#pass
		#elif google_sign_in_retries > 0 and not is_authenticated:
			#SignInClient.sign_in()
			#google_sign_in_retries -= 1
	
func _on_google_token_generated(token: String) -> void:
	BKMREngine.Auth.google_login_player(token)
	
# Check the user session status.
func _on_session_check(session: Dictionary) -> void:
	if session.is_empty():
		BKMREngine.session = false
		loading_label.text = "No logged-in account found!"
		change_to_auth_scene()
	else:
		# Load the main screen if the session is successful.
		if session.has("success"):
			BKMREngine.session = true
			change_to_auth_scene()
		elif session.has("error"):
			BKMREngine.session = false
			if session.error == "jwt expired":
				loading_label.text = "Session expired!"
			else:
				loading_label.text = str(session.error)
			change_to_auth_scene()
	# Stop the tween animation.
	loading_wheel.visible = false
	tween.kill()
	
# Switch to the authentication scene after a delay.
func change_to_auth_scene() -> void:
	#await get_tree().create_timer(3.0).timeout
	# Stop the tween animation.
	tween.kill()
	# Load the authentication scene.
	var _load_scene: bool = await LOADER.load_scene(self, "res://UIScenes/auth_screen.tscn")
	LOADER.previous_texture = transition_texture.texture
	LOADER.next_texture = preload("res://UITextures/BGTextures/blue_gradient.png")

# Simulate a loading animation.
func fake_loader() -> void:
	loading_wheel.value = 0
	tween = get_tree().create_tween()
	
	# Animate the loading wheel value property.
	var _wheel_loader: PropertyTweener = tween.tween_property(loading_wheel, "value", 100, 3.0).set_trans(Tween.TRANS_LINEAR)
	
	# Schedule a callback for fake_loader after the animation completes.
	var _loader_fake: CallbackTweener = tween.tween_callback(fake_loader)

#func _input(event: InputEvent) -> void:
	## Handle screen touch events.
	#if event is InputEventScreenTouch:
		#if event.pressed:
			## Check if the touch event is within the bounds of the notepicker node.
			#var position_event: Vector2 = event.position
			#cursor_spark.position = position_event
			#cursor_spark.emitting = true
	#elif event is InputEventScreenDrag:
		#var position_event: Vector2 = event.position
		#cursor_spark.position = position_event
		#cursor_spark.emitting = true
