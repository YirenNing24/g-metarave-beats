extends Control

const BKMRLogger: Script = preload("res://BeatsKMREngine/utils/BKMRLogger.gd")
const error_list: PackedScene = preload("res://Components/Lists/auth_error.tscn")

#region Variables


@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var animation_player2: AnimationPlayer = %AnimationPlayer2

@onready var username_passkey: String = %UsernamePasskey.text
@onready var username_field: String = %Username.text
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


var passkey: Variant 	

#region Init Functions
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	signal_connect()
	init_visibility_control()
	#google_auth()
	
	if passkey == null && ClassDB.class_exists("Passkey"):
		passkey = ClassDB.instantiate("Passkey")
	else:
		print("wala pa po")
	
func signal_connect() -> void:
	#BEATS LOGIN
	BKMREngine.Auth.bkmr_registration_complete.connect(_on_registration_completed)
	BKMREngine.Auth.bkmr_login_complete.connect(_on_login_succeeded)
	BKMREngine.Auth.bkmr_google_login_complete.connect(_on_google_login_succeeded)
	#BKMREngine.Auth.bkmr_google_registration_complete.connect(_on_google_registration_completed)
	
	#REGISTRATION PASSKEY
	BKMREngine.Auth.bkmr_google_registration_passkey_complete.connect(let_me_verified)
	var _passkey_registration: int = BeatsPasskey.create_passkey_completed.connect(passkey_registration_insert_username)
	BKMREngine.Auth.bkmr_google_registration_passkey_verify_complete.connect(passkey_registration_verification_complete)
		
	#LOGIN PASSKEY
	BKMREngine.Auth.bkmr_google_login_passkey_verify_complete.connect(passkey_login_verification_complete)
	var _sign_in_passkey: int = BeatsPasskey.sign_in_passkey_completed.connect(passkey_authentication_insert_username)
	
	#var _connect: int = SignInClient.server_side_access_requested.connect(_on_google_token_generated)
	
	
func passkey_registration_verification_complete(message: Dictionary) -> void:
	if message.has("error"):
		error_logger([message.error])
		return
	
	
	%ErrorPanel.visible = false
	BKMREngine.session = true
	init_visibility_control()
	BKMRLogger.info("logged in as: " + str(BKMREngine.Auth.logged_in_player))
	loading_panel.tween_kill()
	init_visibility_control()
	
	
func passkey_login_verification_complete(_player_data: Dictionary) -> void:
	BKMREngine.session = true
	%ErrorPanel.visible = false
	
	init_visibility_control()
	BKMRLogger.info("logged in as: " + str(BKMREngine.Auth.logged_in_player))
	loading_panel.tween_kill()
	init_visibility_control()
	
	
func let_me_verified(result: Dictionary) -> void:
	%DebugLabel.text = str(result)


func passkey_registration_insert_username(result: String) -> void:
	%DebugLabel.text = str(result)
	if result != null or "":
		var json_result: Variant = JSON.parse_string(result)
		if json_result is Dictionary:
			json_result.username = %Username.text
			BKMREngine.Auth.beats_passkey_registration_response(json_result)
			loading_panel.fake_loader()
	
	
func passkey_authentication_insert_username(result: String) -> void:
	%DebugLabel.text = str(result)
	if result != null or "":
		var json_result: Variant = JSON.parse_string(result)
		if json_result is Dictionary:
			json_result.username = %UsernamePasskey.text
			BKMREngine.Auth.beats_passkey_login_response(json_result)
			loading_panel.fake_loader()
	
	
#func google_auth() -> void:
	#if BKMREngine.Auth.last_login_type == "google":
		#SignInClient.request_server_side_access(BKMREngine.google_server_client_id, true)
	
	
func init_visibility_control() -> void:
	if BKMREngine.session:
		start_container.visible = false
		login_modal_container.visible = false
		animation_player.play('switch_start_screen')
	else:
		%StartHeroTexture.visible = false
		start_container.visible = false
		login_modal_container.visible = true
		login_container.visible = true
		register_container.visible = false
#endregion


#region Login functions
# Event handler for login button press.
func _on_login_button_pressed() -> void:
	var userName: String = %UsernamePassword.text
	var passWord: String = %LoginPasswordField.text
	
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
#func google_authenticated(is_authenticated: bool) -> void:
	#if google_sign_in_retries > 0 and not is_authenticated:
		#if google_sign_in_retries > 0 and not is_authenticated:
			#SignInClient.sign_in()
			#google_sign_in_retries -= 1
			#
#func _on_google_register_button_pressed() -> void:
	#google_register_pressed = true
	#SignInClient.request_server_side_access(BKMREngine.google_server_client_id, true)
	#loading_panel.fake_loader()
	
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
#func _on_google_registration_completed(result: Dictionary) -> void:
	## Check if there is an error in the registration result.
	#if result.has("error"):
		#google_registration_success = false
		#error_logger([{"error": result.error}]) 
		#if result.error == "An account already exists":
			#error_logger([{"error": "You already have an account"}])
			#google_registration_success = true
			#SignInClient.request_server_side_access(BKMREngine.google_server_client_id, true)
			#loading_panel.fake_loader()
		#loading_panel.tween_kill()
	#else:
		#error_container.visible = false
		#SignInClient.request_server_side_access(BKMREngine.google_server_client_id, true)
		#google_registration_success = true
		#loading_panel.tween_kill()
		
		
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




	
	
# Event handler for register toggle button press.
func _on_register_toggle_pressed() -> void:
	%LoginPasswordContainer.visible = false
	animation_player2.play("login_container")
	
	
# Event handler for login toggle button press.
func _on_login_toggle_pressed() -> void:
	%UsernamePasskey.visible = true
	animation_player2.play("register_container")
	
	
func _on_start_button_pressed() -> void:
	LOADER.previous_texture = background_texture.texture
	LOADER.next_texture = preload("res://UITextures/BGTextures/main_city.png")
	var _change_scene:bool = await LOADER.load_scene(self, "res://UIScenes/main_screen.tscn")


# Function to check the validity of a username.
func is_valid_username(valid_username: String) -> bool:
	if valid_username.is_empty():
		return false
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
		if typeof(error.error) != TYPE_STRING:
			error.error = "Unknown server errror"
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
#endregions


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
	
	
func _on_audio_stream_player_finished() -> void:
	$AudioStreamPlayer.play()
	
	
func _on_other_registration_button_pressed() -> void:
	%Username.visible = false
	%UsernamePasskey.visible = false
	%Label5.visible = false
	
	%Label5.visible = false
	%Password.visible = false
	%Label3.visible = false
	%ConfirmPassword.visible = false
	%PasswordField.visible = false
	
	#%RegisterPlaystore.visible = true
	%RegisterPassword.visible = true
	%RegisterPasskeyButton.visible = true 
	%HBoxContainer3.visible = true 
	
	
func _on_register_passkey_button_pressed() -> void:
	if %Username.visible == false:
		%Username.visible = true
		%Label5.visible = true
		
		%Label2.visible = false
		%RegisterPlaystore.visible = false
		%RegisterPassword.visible = false
		return
	
	var errors: Array = []
	var valid_username: String = ""
	
	username = %Username.text
	
	if is_valid_username(username) == false:
		errors.append({"error": "Invalid username or empty"})
		error_logger(errors)
		return
	else:
		valid_username = %Username.text
	BKMREngine.Auth.register_google_passkey(valid_username)
	
	
func _on_register_password_pressed() -> void:
	if %Password.visible == false:
		%RegisterPasskeyButton.visible = false
		%RegisterPlaystore.visible = false
		%HBoxContainer3.visible = false
		
		%Label5.visible = true
		%Label2.visible = true
		%Password.visible = true
		%Username.visible = true
		%Password.visible = true
		%Label3.visible = true
		%ConfirmPassword.visible = true
	else:
		register_with_password() 
		
		
func register_with_password() -> void:
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
						errors.append({"error": "Invalid or empty username"})
						error_logger(errors)
						return
					else:
						valid_username = fields.text
				"Password":
					reg_password = fields.text
					if not is_valid_password(reg_password):
						errors.append({"error": "Invalid or empty password"})
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
	
	
func _on_pass_key_login_pressed() -> void:
	var username_pass: String = %UsernamePasskey.text
	if not is_valid_username(username_pass):
		error_logger([{"error": "Invalid or empty username"}])
		return
	BKMREngine.Auth.login_player_google_passkey(%UsernamePasskey.text)
	
	
func _on_other_login_button_pressed() -> void:
	%LoginChoiceContainer.visible = true
	%LoginContainer.visible = false 
	%LoginPasswordContainer.visible = false
	
	
func _on_choose_pass_key_login_pressed() -> void:
	%LoginChoiceContainer.visible = false
	%LoginContainer.visible = true
	
	
func _on_choose_password_login_pressed() -> void:
	%LoginChoiceContainer.visible = false
	%LoginPasswordContainer.visible = true
	
	
func _on_login_password_field_text_submitted(_new_text: String) -> void:
	var userName:String = %UsernamePassword.text
	var passWord:String = %LoginPasswordField.text
	BKMREngine.Auth.login_player(userName, passWord)
	loading_panel.fake_loader()


func _on_password_field_text_submitted(_new_text: String) -> void:
	pass
