extends Control

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

var username: String
var password: String
var animation_played: bool = false

func _ready() -> void:
	login_container.show()
	register_container.hide()
	play_animations() 
	var _complete_registration: Error = BKMREngine.Auth.connect("bkmr_registration_complete",  _on_registration_completed)
	var _login_succeeded: Error = BKMREngine.Auth.connect("bkmr_login_complete",  _on_login_succeeded)
	
func play_animations() -> void:
	await(animation_player.animation_finished)
	animation_player.play("hero_bg")

func _on_login_succeeded(result: Dictionary) -> void:
	if "error" in result:
		await animation_player2.animation_finished
		animation_player2.play("error_container")
		error_logger([result.message]) 
		return
	else:
		BKMRLogger.info("logged in as: " + str(BKMREngine.Auth.logged_in_player))
		LOADER.previous_texture = background_texture.texture
		LOADER.next_texture = preload("res://UITextures/BGTextures/main.png")
		var _change_scene:bool = await LOADER.load_scene(self, "res://UIScenes/main_screen.tscn")
		
func _on_registration_completed(result: Dictionary) -> void:
	if "error" in result:
		animation_player2.play("error_container")
		error_logger([result.error])
		return
	animation_player2.play("registration_loading")
	await(animation_player2.animation_finished)
	animation_player2.play("success")
	BKMREngine.Auth.login_player(username, password)
	
func _on_login_button_pressed() -> void:
	var userName: String = username
	var passWord: String = password
	if userName == "":
		animation_player2.play("error_container")
		error_logger(["Username is required"])
		return
	elif passWord == "":
		animation_player2.play("error_container")
		error_logger(["Password is required"])
		return
	else:
		BKMREngine.Auth.login_player(userName, passWord)
		animation_player2.play("registration_loading")
		
func _on_username_field_text_changed(new_text: String) -> void:
	username = new_text

func _on_password_field_text_changed(new_text: String) -> void:
	password = new_text

func _on_password_field_text_submitted(_new_text: String) -> void:
	var userName:String = username
	var passWord:String = password
	BKMREngine.Auth.login_player(userName, passWord)
	animation_player2.play("registration_loading")
	
func _on_register_toggle_pressed() -> void:
	animation_player2.play("login_container")
	
func _on_login_toggle_pressed() -> void:
	animation_player2.play("register_container")

func _on_register_button_pressed() -> void:
	var errors:Array = []
	
	var found_empty_field: bool = false
	var password: String = ""
	var confirmPassword: String = ""
	var firstName: String = ""
	var lastName: String = ""
	
	var valid_firstname: String = ""
	var valid_lastname: String = ""
	var valid_email: String = ""
	var valid_username: String = ""
	var valid_password: String = ""
	
	for fields: LineEdit in get_tree().get_nodes_in_group("reg_field"):
		if fields.text == "":
			if fields.name != "FirstName" and fields.name != "LastName":
				var empty_fields: String = fields.name
				errors.append(empty_fields + " is required")
				found_empty_field = true
		else:
			if fields.name == "FirstName":
				firstName = fields.text
				if not is_valid_name(firstName):
					errors.append("Invalid first name format")
					error_logger(errors)
					return
				else:
					valid_firstname = fields.text
			if fields.name == "LastName":
				lastName = fields.text
				if not is_valid_name(lastName):
					errors.append("Invalid last name format")
					error_logger(errors)
					return
				else:
					valid_lastname = fields.text
			if fields.name == "Email":
				if not is_valid_email(fields.text):
					errors.append("Invalid email format")
					error_logger(errors)
					return
				else:
					valid_email = fields.text
			if fields.name == "Username":
				username = fields.text
				if not is_valid_username(username):
					errors.append("Invalid username format")
					error_logger(errors)
					return
				else:
					valid_username = fields.text
			if fields.name == "Password":
				password = fields.text
				if not is_valid_password(password):
					errors.append("Invalid password format")
					error_logger(errors)
					return
			if fields.name == "ConfirmPassword":
				confirmPassword = fields.text
				
	if found_empty_field:
		error_logger(errors)
		return
	if password != confirmPassword:
		errors.append("Password doesn't match")
		error_logger(errors)
	else:
		valid_password = password
		
	if valid_email and valid_username and valid_password != "":
		for child: Control in error_container.get_children():
			error_container.remove_child(child)
			child.queue_free()
			
		on_submit_registration(valid_email, valid_username, valid_password, valid_firstname, valid_lastname)
		animation_played = false
		animation_player2.play_backwards("error_container")

func is_valid_name(name: String) -> bool:
	var name_pattern: String = "^[a-zA-Z]{2,30}$"
	var regex: RegEx = RegEx.new()
	var _pattern_name: Error =regex.compile(name_pattern)
	return regex.search(name) != null
		
func is_valid_username(username: String) -> bool:
	var username_pattern: String = "^[a-zA-Z0-9_]{3,16}$"
	var regex: RegEx = RegEx.new()
	var _pattern_username: Error = regex.compile(username_pattern)
	return regex.search(username) != null
	
func is_valid_email(email: String) -> bool:
	var email_pattern: String = "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"
	var regex: RegEx = RegEx.new()
	var _pattern_email: Error = regex.compile(email_pattern)
	return regex.search(email) != null

func is_valid_password(password: String) -> bool:
	var password_pattern: String = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[^a-zA-Z\\d\\s]).{8,}$"
	var regex: RegEx = RegEx.new()
	var _pattern_password: Error = regex.compile(password_pattern)
	return regex.search(password) != null

func error_logger(errors: Array) -> void:
	if animation_played == false:
		animation_player2.play("error_container")
		animation_played = true
	
	var unique_errors: Array= []
	var list_error: Control
	
	for child: Control in error_container.get_children():
		error_container.remove_child(child)
		child.queue_free()
	for error: String in errors:
		if error not in unique_errors:
			unique_errors.append(error)
	for err: String in unique_errors:
		list_error = error_list.instantiate()
		if err == "ConfirmPassword is required":
			list_error.get_node("Label").set_text("Please confirm your password")
			error_container.add_child(list_error)
		if err != "ConfirmPassword is required":
			list_error.name = err
			list_error.get_node("Label").set_text(err)
			error_container.add_child(list_error)
	
func on_submit_registration(val_email: String, val_username: String, val_password: String, namefirst: String, namelast: String)  -> void:
	password = val_password
	username = val_username
	BKMREngine.Auth.register_player(val_email, val_username, val_password, namefirst, namelast)
