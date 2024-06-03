extends Control

# TODO: Loading wheel when logging-in should be continous until login is completed or not 

#region Variables
const BKMRLogger: Script = preload("res://BeatsKMREngine/utils/BKMRLogger.gd")
const error_list: PackedScene = preload("res://Components/Lists/auth_error.tscn")
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var animation_player2: AnimationPlayer = %AnimationPlayer2
@onready var username_field: String = %UsernameField.text
@onready var password_field: String = %PasswordField.text
@onready var login_container: VBoxContainer = %LoginContainer
@onready var register_container: VBoxContainer = %RegisterContainer
@onready var error_container: VBoxContainer = %ErrorContainer
@onready var background_texture: TextureRect = %BackgroundTexture
@onready var login_modal_container: VBoxContainer = %LoginModalContainer
@onready var start_container: VBoxContainer = %StartContainer
@onready var cursor_spark: GPUParticles2D = %CursorSpark

@onready var loading_panel: Panel = %LoadingPanel

var username: String
var password: String
var animation_played: bool = false

var registration_success: bool = false
var google_registration_success: bool = false
var google_register_pressed: bool = false

var google_sign_in_retries: int = 5
#endregion


#region Init Functions
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	signal_connect()
	init_visibility_control()
	google_auth()
	
func signal_connect() -> void:
	BKMREngine.Auth.bkmr_registration_complete.connect(_on_registration_completed)
	BKMREngine.Auth.bkmr_login_complete.connect(_on_login_succeeded)
	BKMREngine.Auth.bkmr_google_login_complete.connect(_on_google_login_succeeded)
	BKMREngine.Auth.bkmr_google_registration_complete.connect(_on_google_registration_completed)
	var _connect: int = SignInClient.server_side_access_requested.connect(_on_google_token_generated)
	
func google_auth() -> void:
	if BKMREngine.Auth.last_login_type == "google":
		SignInClient.request_server_side_access(BKMREngine.google_server_client_id, true)

func init_visibility_control() -> void:
	if BKMREngine.session:
		start_container.visible = false
		login_modal_container.visible = false
		animation_player.play('switch_start_screen')
	else:
		start_container.visible = false
		login_modal_container.visible = true
		login_container.visible = true
		register_container.visible = false
#endregion

#region Login functions
# Event handler for login button press.
func _on_login_button_pressed() -> void:
	var userName: String = username
	var passWord: String = password
	if userName == "":
		animation_player2.play("error_container")
		error_logger([{"error": "Username is required"}])
	elif passWord == "":
		animation_player2.play("error_container")
		error_logger([{"error": "Password is required"}])
	else:
		BKMREngine.Auth.login_player(userName, passWord)
		loading_panel.fake_loader()

#Callback for login result
func _on_login_succeeded(result: Dictionary) -> void:
	if result.has("error"):
		error_logger([{"error": result.error}]) 
		loading_panel.tween_kill()
	else:
		%ErrorPanel.visible = false
		BKMREngine.session = true
		init_visibility_control()
		BKMRLogger.info("logged in as: " + str(BKMREngine.Auth.logged_in_player))
		registration_success = false
	loading_panel.tween_kill()

#Callback for google login
func _on_google_login_succeeded(result: Dictionary) -> void:
	if result.has("error"):
		error_logger([{"error": result.error}])  
		google_registration_success = false
		loading_panel.tween_kill()
	else:
		%TextureProgressBar.visible = false
		BKMREngine.session = true
		start_container.visible = false
		login_modal_container.visible = false
		animation_player.play('switch_start_screen')
		google_registration_success = false
	loading_panel.tween_kill()
		
#endregion

#region Google Auth
func google_authenticated(is_authenticated: bool) -> void:
	if google_sign_in_retries > 0 and not is_authenticated:
		if google_sign_in_retries > 0 and not is_authenticated:
			SignInClient.sign_in()
			google_sign_in_retries -= 1
			
func _on_google_register_button_pressed() -> void:
	google_register_pressed = true
	SignInClient.request_server_side_access(BKMREngine.google_server_client_id, true)
	loading_panel.fake_loader()
	
#endregion

func _on_google_token_generated(token: String) -> void:
	if google_registration_success == false and google_register_pressed == true:
		BKMREngine.Auth.register_google(token)
		
	elif google_registration_success == true or BKMREngine.Auth.last_login_type == "google":
		BKMREngine.Auth.google_login_player(token)
		
#region Registration functions

#Callback for native registration status
func _on_registration_completed(result: Dictionary) -> void:
	# Check if there is an error in the registration result.
	if result.has("error"):
		# If an error is present, play the error animation and log the error message.
		animation_player2.play("error_container")
		registration_success = false
		error_logger([{"error": result.error}]) 
	else:
		registration_success = true
		BKMREngine.Auth.login_player(username, password)

#Callback for google registration status
func _on_google_registration_completed(result: Dictionary) -> void:
	# Check if there is an error in the registration result.
	if result.has("error"):
		google_registration_success = false
		error_logger([{"error": result.error}]) 
		if result.error == "An account already exists":
			error_logger([{"error": "You already have an account"}])
			google_registration_success = true
			SignInClient.request_server_side_access(BKMREngine.google_server_client_id, true)
			loading_panel.fake_loader()
		loading_panel.tween_kill()
	else:
		error_container.visible = false
		SignInClient.request_server_side_access(BKMREngine.google_server_client_id, true)
		google_registration_success = true
		loading_panel.tween_kill()
		
# Function to submit user registration.
func on_submit_registration(val_username: String, val_password: String)  -> void:
	password = val_password
	username = val_username
	BKMREngine.Auth.register_player(val_username, val_password)
	loading_panel.fake_loader()
	
func _on_register_button_pressed() -> void:
	var errors: Array = []
	
	var found_empty_field: bool = false
	var reg_password: String = ""
	var confirmPassword: String = ""

	var valid_username: String = ""
	var valid_password: String = ""

	for fields: LineEdit in get_tree().get_nodes_in_group("reg_field"):
			match fields.name:
				"Username":
					username = fields.text
					if not is_valid_username(username):
						errors.append({"error": "Invalid username format"})
						error_logger(errors)
						return
					else:
						valid_username = fields.text
				"Password":
					reg_password = fields.text
					if not is_valid_password(reg_password):
						errors.append({"error": "Invalid password format"})
						error_logger(errors)
						return
					else:
						password = fields.text
				"ConfirmPassword":
					confirmPassword = fields.text
				
	if found_empty_field:
		error_logger(errors)
		return
		
	if password != confirmPassword:
		errors.append({"error":"Password doesn't match"})
		error_logger(errors) 
	else:
		valid_password = reg_password
	
	if valid_username and valid_password != "":
		for child: Control in error_container.get_children():
			error_container.remove_child(child)
			child.queue_free()
			
		on_submit_registration(valid_username, valid_password)
		animation_played = false
		error_container.visible = false
	
#endregion

#region event callback and utility functions
# Event handler for username field text change.
func _on_username_field_text_changed(new_text: String) -> void:
	username = new_text

# Event handler for password field text change.
func _on_password_field_text_changed(new_text: String) -> void:
	password = new_text

# Event handler for password field text submission.
func _on_password_field_text_submitted(_new_text: String) -> void:
	var userName:String = username
	var passWord:String = password
	BKMREngine.Auth.login_player(userName, passWord)
	loading_panel.fake_loader()
	
# Event handler for register toggle button press.
func _on_register_toggle_pressed() -> void:
	animation_player2.play("login_container")
	
# Event handler for login toggle button press.
func _on_login_toggle_pressed() -> void:
	animation_player2.play("register_container")
	
func _on_start_button_pressed() -> void:
	LOADER.previous_texture = background_texture.texture
	LOADER.next_texture = preload("res://UITextures/BGTextures/main_city.png")
	var _change_scene:bool = await LOADER.load_scene(self, "res://UIScenes/main_screen.tscn")

# Function to check the validity of a username.
func is_valid_username(valid_username: String) -> bool:
	var username_pattern: String = "^[a-zA-Z0-9_]{3,16}$"
	var regex: RegEx = RegEx.new()
	var _pattern_username: Error = regex.compile(username_pattern)
	return regex.search(valid_username) != null

# Function to check the validity of a password.
func is_valid_password(valid_password: String) -> bool:
	var password_pattern: String = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[^a-zA-Z\\d\\s]).{8,}$"
	var regex: RegEx = RegEx.new()
	var _pattern_password: Error = regex.compile(password_pattern)
	return regex.search(valid_password) != null

# Function to log errors and play animation if not played.
func error_logger(errors: Array) -> void:
	if animation_played == false:
		animation_player2.play("error_container")
		animation_played = true
	
	var unique_errors: Array= []
	var list_error: Control
	
	for child: Control in error_container.get_children():
		error_container.remove_child(child)
		child.queue_free()
	for error: Dictionary in errors:
		
		print("yeah: ", error)
		var errors_string: String = error.error
		if errors_string not in unique_errors:
			unique_errors.append(error)
	for err: Dictionary in unique_errors:
		list_error = error_list.instantiate()
		if err.error == "ConfirmPassword is required":
			list_error.get_node("Label").set_text("Please confirm your password")
			error_container.add_child(list_error)
		elif err.error != "ConfirmPassword is required":
			list_error.name = err.error
			list_error.get_node("Label").set_text(err.error)
			error_container.add_child(list_error)
#endregion

func _input(event: InputEvent) -> void:
	# Handle screen touch events.
	if event is InputEventScreenTouch:
		if event.pressed:
			# Check if the touch event is within the bounds of the notepicker node.
			var position_event: Vector2 = event.position
			cursor_spark.position = position_event
			cursor_spark.emitting = true
	elif event is InputEventScreenDrag:
		var position_event: Vector2 = event.position
		cursor_spark.position = position_event
		cursor_spark.emitting = true
