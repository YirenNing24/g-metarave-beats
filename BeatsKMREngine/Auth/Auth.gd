extends Node

# Constants for utility scripts
const BKMRLocalFileStorage: Script = preload("res://BeatsKMREngine/utils/BKMRLocalFileStorage.gd")
const BKMRUtils: Script = preload("res://BeatsKMREngine/utils/BKMRUtils.gd")
const BKMRLogger: Script = preload("res://BeatsKMREngine/utils/BKMRLogger.gd")
const UUID: Script = preload("res://BeatsKMREngine/utils/UUID.gd")

# Signals for various authentication and server interactions
signal bkmr_login_complete
signal bkmr_logout_complete
signal bkmr_registration_complete
signal bkmr_registration_user_pwd_complete
signal bkmr_email_verif_complete
signal bkmr_resend_conf_code_complete
signal bkmr_session_check_complete
signal bkmr_request_password_reset_complete
signal bkmr_reset_password_complete
signal bkmr_get_player_details_complete
signal bkmr_version_check_complete

# Variables to store authentication and session information
var tmp_username: String
var logged_in_player: String
var logged_in_player_email: String
var logged_in_anon: bool = false
var bkmr_access_token: String
var bkmr_id_token: String

# Server host URL
var host: String = BKMREngine.host

# HTTPRequest instances for server communication
var VersionCheck: HTTPRequest
var RegisterPlayer: HTTPRequest
var VerifyEmail: String
var ResendConfCode: String
var LoginPlayer: HTTPRequest
var ValidateSession: HTTPRequest

# Weak references to prevent circular references
var bkmrVersionCheck:Object = null
var bkmrValidateSession: WeakRef

var bkmrRegisterPlayer: WeakRef
var bkmrLoginPlayer: WeakRef

# Timer variables for login timeout and session check wait
var login_timeout: int = 0
var login_timer: Timer
var complete_session_check_wait_timer: Timer

# Function to check the game version with the server.
# Parameters:
# - config: A Dictionary containing configuration information for the version check.
# Returns: The calling Node (self).
func check_version(config: Dictionary) -> Node:
	# Prepare HTTP request
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	VersionCheck = prepared_http_req.request
	bkmrVersionCheck = prepared_http_req.weakref
	
	# Connect the signal for handling version check completion
	var _signal_version_check: int = VersionCheck.request_completed.connect(_on_VersionCheck_request_completed)
	
	# Log version check initiation
	BKMRLogger.info("Calling BKMRServer to check game version")
	
	# Prepare payload and send a POST request
	var payload: Dictionary = config
	var request_url: String = host + "/api/version-check/beats"
	BKMREngine.send_post_request(VersionCheck, request_url, payload)
	
	return self


# Callback function when version check request is completed
func _on_VersionCheck_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check HTTP response status
	var _status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	var json_body: String = body.get_string_from_utf8()
	
	# Emit signal with the server response
	bkmr_version_check_complete.emit(json_body)

	
#func register_player_anon(player_name: String = "") -> Node:
	#var user_local_id: String = get_anon_user_id()
	#var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	#RegisterPlayer = prepared_http_req.request
	#bkmrRegisterPlayer = prepared_http_req.weakref
	#RegisterPlayer.request_completed.connect(_on_RegisterPlayer_request_completed)
	#BKMRLogger.info("Calling BKMRServer to register an anonymous player")
	#var payload: Dictionary = { "apiId": BKMREngine.config.apiId, "anon": true, "player_name": player_name, "user_local_id": user_local_id }
	#var request_url: String = host + "/api/register"
	#BKMREngine.send_post_request(RegisterPlayer, request_url, payload)
	#return self

# Function to register a player with the server.
# Parameters:
# - email: The email address of the player.
# - username: The desired username for the player.
# - password: The password for the player's account.
# - firstname: The first name of the player.
# - lastname: The last name of the player.
# Returns: The calling Node (self).
func register_player(email: String, username: String, password: String, firstname: String, lastname: String) -> Node:
	# Prepare HTTP request
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	RegisterPlayer = prepared_http_req.request
	bkmrRegisterPlayer = prepared_http_req.weakref
	
	# Connect the signal for handling registration completion
	var _register_signal: int = RegisterPlayer.request_completed.connect(_on_RegisterPlayer_request_completed)
	
	# Log registration initiation
	BKMRLogger.info("Calling BKMRServer to register a player")
	
	# Prepare payload and send a POST request
	var payload: Dictionary = { 
		"anon": false, 
		"email": email,  
		"userName": username, 
		"password": password, 
		"firstName": firstname, 
		"lastName": lastname 
	}
	var request_url: String = host + "/api/register/beats"
	BKMREngine.send_post_request(RegisterPlayer, request_url, payload)
	
	return self


# Callback function triggered upon completion of the player registration request
func _on_RegisterPlayer_request_completed(_result: Dictionary, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Free the HTTP request resources
	BKMREngine.free_request(bkmrRegisterPlayer, RegisterPlayer)
	
	# Parse the JSON body of the response
	var json_body: Dictionary = JSON.parse_string(body.get_string_from_utf8())
	var _bkmr_result: Dictionary
	
	# Check if the registration was successful
	if status_check:
		# Log the successful registration and emit a signal
		_bkmr_result = {"success": str(json_body.username)}
		BKMRLogger.info("BKMREngine register player success, username: " + json_body.username)
		bkmr_registration_complete.emit(_bkmr_result)
	else:
		# Log the registration failure and emit a signal with an error message
		_bkmr_result = {"error": str(json_body.message)}
		BKMRLogger.error("BKMREngine player registration failure: " + str(json_body.message))
		bkmr_registration_complete.emit(_bkmr_result)


func register_player_user_password(player_name: String, password: String, confirm_password: String) -> Node:
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	RegisterPlayer = prepared_http_req.request
	bkmrRegisterPlayer = prepared_http_req.weakref
	var _register_signal: int = RegisterPlayer.request_completed.connect(_on_RegisterPlayerUserPassword_request_completed)
	BKMRLogger.info("Calling BKMRE to register a player")
	var payload: Dictionary = { "apiId": BKMREngine.config.apiId, "player_name": player_name, "password": password, "confirm_password": confirm_password }
	var request_url: String = host + "/api/register/beats"
	BKMREngine.send_post_request(RegisterPlayer, request_url, payload)
	return self

func _on_RegisterPlayerUserPassword_request_completed(_result: Dictionary, response_code: int, headers: Array, body: PackedByteArray) -> void:
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	#RegisterPlayer.queue_free()
	BKMREngine.free_request(bkmrRegisterPlayer, RegisterPlayer)
	if status_check:
		var json_body:Dictionary = JSON.parse_string(body.get_string_from_utf8())
		# also get a JWT token here
		# send a different signal depending on registration success or failure
		var bkmr_result: Dictionary = BKMREngine.build_result(json_body)
		if json_body.success:
			# if email confirmation is enabled for the game, we can't log in the player just yet
			var _email_conf_enabled: String = json_body.email_conf_enabled
			BKMRLogger.info("Player registration with username/password succeeded, player account autoconfirmed.")
			logged_in_player = tmp_username
		else:
			BKMRLogger.error("BKMR username/password player registration failure: " + str(json_body.error))
		bkmr_registration_user_pwd_complete.emit(bkmr_result)

#func verify_email(player_name: String, code: String) -> Node:
	#var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	#VerifyEmail = prepared_http_req.request
	#bkmrVerifyEmail = prepared_http_req.weakref
	#VerifyEmail.request_completed.connect(_on_VerifyEmail_request_completed)
	#BKMRLogger.info("Calling BKMREngine to verify email address for: " + str(player_name))
	#var payload: Dictionary = { "apiId": BKMREngine.config.apiId, "username":  player_name, "code": code }
	#var request_url: String = host + "/confirm_verif_code"
	#BKMREngine.send_post_request(VerifyEmail, request_url, payload)
	#return self

#func _on_VerifyEmail_request_completed(_result: Dictionary, response_code: int, headers: Array, body: PackedByteArray) -> void:
	#var status_check = BKMRUtils.check_http_response(response_code, headers, body)
	#BKMREngine.free_request(bkmrVerifyEmail, VerifyEmail)
	#
	#if status_check:
		#var json_body: Dictionary = JSON.parse_string(body.get_string_from_utf8())
		#BKMREngine.info("BKMREngine verify email success? : " + str(json_body.success))
		## also get a JWT token here
		## send a different signal depending on registration success or failure
		#var bkmr_result: Dictionary = BKMREngine.build_result(json_body)
		#if json_body.success:
			#BKMRLogger.info("BKMREngine email verification success.")
			#logged_in_player  = tmp_username
		#else:
			#BKMRLogger.error("BKMREngine email verification failure: " + str(json_body.error))
		#bkmr_email_verif_complete.emit(bkmr_result)
	
	
#func resend_conf_code(player_name: String) -> Node:
	#var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	#ResendConfCode = prepared_http_req.request
	#bkmrResendConfCode = prepared_http_req.weakref
	#ResendConfCode.request_completed.connect(_on_ResendConfCode_request_completed)
	#BKMRLogger.info("Calling BKMREngine to resend confirmation code for: " + str(player_name))
	#var payload: Dictionary = { "apiId": BKMREngine.config.apiId, "username": player_name }
	#var request_url: String = host + "/resend_conf_code"
	#BKMREngine.send_post_request(ResendConfCode, request_url, payload)
	#return self
	

#func _on_ResendConfCode_request_completed(result: Dictionary, response_code, headers, body) -> void:
	#BKMRLogger.info("ResendConfCode request completed")
	#var status_check = BKMRUtils.check_http_response(response_code, headers, body)
	#BKMREngine.free_request(bkmrResendConfCode, ResendConfCode)
	#
	#if status_check:
		#var json_body = JSON.parse_string(body.get_string_from_utf8())
		## also get a JWT token here
		## send a different signal depending on registration success or failure
		#var bkmr_result: Dictionary = BKMREngine.build_result(json_body)
		#if json_body.success:
			#BKMRLogger.info("BKMREngine resend conf code success.")
		#else:
			#BKMRLogger.error("BKMREngine resend conf code failure: " + str(json_body.error))
		#bkmr_resend_conf_code_complete.emit(bkmr_result)


# Initiates a request to log in a player with the provided username and password
func login_player(username: String, password: String) -> Node:
	# Store the username temporarily for reference in the callback function
	tmp_username = username
	
	# Prepare the HTTP request for player login
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	LoginPlayer = prepared_http_req.request
	bkmrLoginPlayer = prepared_http_req.weakref
	
	# Connect the callback function to handle the completion of the login request
	var _login_signal: int = LoginPlayer.request_completed.connect(_on_LoginPlayer_request_completed)
	
	# Log information about the login attempt
	BKMRLogger.info("Calling BKMREngine to log in a player")
	
	# Prepare the payload for the login request
	var payload: Dictionary = { "username": username, "password": password }
	
	# Obfuscate the password before logging and sending the request
	var payload_for_logging: Dictionary = payload
	var obfuscated_password: String = BKMRUtils.obfuscate_string(payload["password"])
	print("obfuscated password: " + str(obfuscated_password))
	payload_for_logging["password"] = obfuscated_password
	BKMRLogger.debug("BKMREngine login player payload: " + str(payload_for_logging))
	
	# Define the request URL for player login
	var request_url: String = host + "/api/login/beats"
	
	# Send the POST request to initiate player login
	BKMREngine.send_post_request(LoginPlayer, request_url, payload)
	
	# Return self for potential chaining of function calls
	return self

# Callback function triggered upon completion of the player login request
func _on_LoginPlayer_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status and free the request resources
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	BKMREngine.free_request(bkmrLoginPlayer, LoginPlayer)
	
	# Process the response based on the status check
	if status_check:
		# Parse the JSON body of the response
		var json_body: Dictionary = JSON.parse_string(body.get_string_from_utf8())
		
		# Log additional information if present in the response
		if "lookup" in json_body.keys():
			BKMRLogger.debug("Remember me lookup: " + str(json_body.lookup))
		if "validator" in json_body.keys():
			BKMRLogger.debug("Remember me validator: " + str(json_body.validator))
			
			# Save the session and set the player as logged in
			var body_lookup: String = json_body.lookup
			var body_validator: String = json_body.validator
			save_session(body_lookup, body_validator)
			set_player_logged_in(tmp_username)
			PLAYER.data = json_body.user
			bkmr_login_complete.emit(json_body)
			
		# Process token if present in the response
		if "token" in json_body.keys():
			bkmr_access_token = json_body.token
		else:
			# Emit login failure if no token is present
			bkmr_login_complete.emit(json_body.error)
			BKMRLogger.error("BKMREngine login player failure: " + str(json_body.error))
	else:
		# Handle cases where the JSON parsing fails or the server returns an unknown error
		if JSON.parse_string(body.get_string_from_utf8()) != null:
			var json_body: Dictionary = JSON.parse_string(body.get_string_from_utf8())
			bkmr_login_complete.emit(json_body)
		else:
			print("Unknown server error")

# Function to log out the player
func logout_player() -> void:
	# Clear the logged-in player information
	logged_in_player = ""
	
	# Remove stored session if any and log the deletion success
	var delete_success: bool = remove_stored_session()
	print("delete_success: " + str(delete_success))
	
	# Clear access and ID tokens
	bkmr_access_token = ""
	bkmr_id_token = ""
	
	# Emit signal indicating completion of player logout
	bkmr_logout_complete.emit()

	
#func request_player_password_reset(player_name: String) -> Node:
	#var prepared_http_req = BKMREngine.prepare_http_request()
	#RequestPasswordReset = prepared_http_req.request
	#bkmrRequestPasswordReset = prepared_http_req.weakref
	#RequestPasswordReset.request_completed.connect(_on_RequestPasswordReset_request_completed)
	#BKMRLogger.info("Calling BKMREngine to request a password reset for: " + str(player_name))
	#var payload = { "apiId": BKMREngine.config.apiId, "player_name": player_name }
	#BKMRLogger.debug("BKMREngine request player password reset payload: " + str(payload))
	#var request_url = "https://api.silentwolf.com/request_player_password_reset"
	#BKMREngine.send_post_request(RequestPasswordReset, request_url, payload)
	#return self

#func _on_RequestPasswordReset_request_completed(_result, response_code, headers, body) -> void:
	#BKMRLogger.info("RequestPasswordReset request completed")
	#var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	#BKMREngine.free_request(bkmrRequestPasswordReset, RequestPasswordReset)
	#
	#if status_check:
		#var json_body = JSON.parse_string(body.get_string_from_utf8())
		#var bkmr_result: Dictionary = BKMREngine.build_result(json_body)
		#if json_body.success:
			#BKMRLogger.info("BKMREngine request player password reset success.")
		#else:
			#BKMRLogger.error("BKMREngine request password reset failure: " + str(json_body.error))
		#bkmr_request_password_reset_complete.emit(bkmr_result)

#func reset_player_password(player_name: String, conf_code: String, new_password: String, confirm_password: String) -> Node:
	#var prepared_http_req = BKMREngine.prepare_http_request()
	#ResetPassword = prepared_http_req.request
	#bkmrResetPassword = prepared_http_req.weakref
	#ResetPassword.request_completed.connect(_on_ResetPassword_completed)
	#BKMRLogger.info("Calling BKMREngine to reset password for: " + str(player_name))
	#var payload = { "apiId": BKMREngine.config.apiId, "player_name": player_name, "conf_code": conf_code, "password": new_password, "confirm_password": confirm_password }
	#BKMRLogger.debug("BKMREngine request player password reset payload: " + str(payload))
	#var request_url = host + "api/reset_player_password"
	#BKMREngine.send_post_request(ResetPassword, request_url, payload)
	#return self

# Function to attempt automatic player login based on saved session data
func auto_login_player() -> Node:
	# Load saved BKMREngine session data
	var bkmr_session_data: Dictionary = load_session()
	BKMRLogger.debug("BKMR session data " + str(bkmr_session_data))
	
	# Check if session data is available for autologin
	if bkmr_session_data:
		BKMRLogger.debug("Found saved BKMREngine session data, attempting autologin...")
		
		# Extract lookup and validator from the saved session data
		var lookup: String = bkmr_session_data.lookup
		var validator: String = bkmr_session_data.validator
		
		# Validate the player session using the extracted data
		var _validate_session: Node = validate_player_session(lookup, validator)
	else:
		# If no saved session data is available, log the absence and initiate a delayed session check
		BKMRLogger.debug("No saved BKMREngine session data, so no autologin will be performed")
		
		# Set up a timer to delay the emission of the signal for a short duration
		setup_complete_session_check_wait_timer()
		complete_session_check_wait_timer.start()
	
	return self

# Function to validate an existing player session using lookup and validator tokens
# Params:
# - lookup: String, the lookup token associated with the player's session
# - validator: String, the validator token used for session validation
# - _scene: Node, the scene where the validation request is initiated (default: current scene)
# Returns: Node, the current script instance
func validate_player_session(lookup: String, validator: String, _scene: Node = get_tree().get_current_scene()) -> Node:
	# Prepare the HTTP request for session validation
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	ValidateSession = prepared_http_req.request
	bkmrValidateSession = prepared_http_req.weakref
	var _validate_session: int = ValidateSession.request_completed.connect(_on_ValidateSession_request_completed)
	
	# Log the initiation of player session validation
	BKMRLogger.info("Calling BKMREngine to validate an existing player session")
	
	# Create the payload with lookup and validator tokens
	var payload: Dictionary = {"lookup": lookup, "validator": validator}
	
	# Set the current validator token for further use
	bkmr_access_token = validator
	
	# Log the payload details
	BKMRLogger.debug("Validate session payload: " + str(payload))
	
	# Construct the request URL
	var request_url: String = host + "/api/validate_session/beats"
	
	# Send the POST request for session validation
	BKMREngine.send_post_request(ValidateSession, request_url, payload)
	
	# Return the current script instance
	return self

	
	
# Event handler for the completion of the player session validation request
# Params:
# - _result: int, the result of the HTTP request
# - response_code: int, the HTTP response code
# - headers: Array, the headers received in the response
# - body: PackedByteArray, the body of the response
func _on_ValidateSession_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the status of the HTTP response
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Free the request resources
	BKMREngine.free_request(bkmrValidateSession, ValidateSession)
	
	# Handle the result based on the status check
	if status_check:
		# Parse the JSON body of the response
		var json_body: Dictionary = JSON.parse_string(body.get_string_from_utf8())
		
		# Build a result dictionary from the JSON body
		var bkmr_result: Dictionary = BKMREngine.build_result(json_body)
		
		# Check for errors in the response
		if json_body.has("error"):
			BKMRLogger.error("BKMREngine validate session failure: " + str(json_body.error))
		elif json_body.has("success"):
			# Log success and set the player as logged in
			BKMRLogger.info("BKMREngine validate session success.")
			var body_username: String = json_body.username
			set_player_logged_in(body_username)
			
			# Set the access token if available
			if json_body.has("bkmr_jwt"):
				bkmr_access_token = json_body.bkmr_jwt
				
			# Set player data
			PLAYER.data = json_body
			
		# Trigger the completion of the session check with the result
		complete_session_check(bkmr_result)
	else:
		# Trigger the completion of the session check with an empty result in case of failure
		complete_session_check({})


# Set the currently logged-in player and configure session timeout if applicable
# Params:
# - player_name: String, the username of the logged-in player
func set_player_logged_in(player_name: String) -> void:
	# Set the global variable for the logged-in player
	logged_in_player  = player_name
	
	# Log information about the player being logged in
	BKMRLogger.info("BKMREngine - player logged in as " + str(player_name))
	
	# Check for session duration configuration in the authentication settings
	if BKMREngine.auth_config.has("session_duration_seconds") and typeof(BKMREngine.auth_config.session_duration_seconds) == 2:
		login_timeout = BKMREngine.auth_config.session_duration_seconds
	else:
		login_timeout = 0
	
	# Log information about the login timeout configuration
	BKMRLogger.info("BKMREngine login timeout: " + str(login_timeout))
	
	# If a login timeout is specified, set up the login timer
	if login_timeout != 0:
		setup_login_timer()
	
func get_anon_user_id() -> String:
	var anon_user_id: String = OS.get_unique_id()
	if anon_user_id == '':
		anon_user_id = UUID.generate_uuid_v4()
	print("anon_user_id: " + str(anon_user_id))
	return anon_user_id
	
# Remove stored BKMREngine session data from the user data directory.
# This function attempts to delete the file storing the session data.
# Returns: bool, indicating the success of the removal operation.
func remove_stored_session() -> bool:
	# Define the path to the file storing the BKMREngine session data
	var path: String = "user://bkmrsession.save"
	
	# Attempt to delete the file and log the result
	var delete_success: bool = BKMRLocalFileStorage.remove_data(path, "Removing BKMREngine session if any: " )
	
	# Return the success status of the removal operation
	return delete_success

# Complete the BKMREngine session check and emit the corresponding signal.
# This function is called to signal the completion of the session check process,
# and it emits the 'bkmr_session_check_complete' signal with the provided result.
# Parameters:
#   - bkmr_result: Dictionary, optional parameter to include additional result information.
#                  Default is an empty dictionary.
func complete_session_check(bkmr_result: Dictionary = {}) -> void:
	# Log a debug message indicating the completion of the session check
	BKMRLogger.debug("BKMREngine: completing session check")
	
	# Emit the 'bkmr_session_check_complete' signal with the provided result
	bkmr_session_check_complete.emit(bkmr_result)

# Set up a timer to delay the emission of the 'bkmr_session_check_complete' signal.
# This function creates a new Timer instance, configures it to be a one-shot timer with a small wait time,
# and connects its timeout signal to the 'complete_session_check' function.
# The timer is then added as a child of the current node.
# The purpose is to introduce a slight delay before emitting the signal, ensuring proper signal reception.
func setup_complete_session_check_wait_timer() -> void:
	# Create a new one-shot timer
	complete_session_check_wait_timer = Timer.new()
	
	# Configure the timer to be a one-shot timer with a small wait time (0.01 seconds)
	complete_session_check_wait_timer.set_one_shot(true)
	complete_session_check_wait_timer.set_wait_time(0.01)
	
	# Connect the timeout signal of the timer to the 'complete_session_check' function
	var _session_timer_signal: int = complete_session_check_wait_timer.timeout.connect(complete_session_check)
	
	# Add the timer as a child of the current node
	add_child(complete_session_check_wait_timer)

func setup_login_timer() -> void:
	login_timer = Timer.new()
	login_timer.set_one_shot(true)
	login_timer.set_wait_time(login_timeout)
	var _timer_signal: int = login_timer.timeout.connect(on_login_timeout_complete)
	add_child(login_timer)
	
func on_login_timeout_complete() -> void:
	logout_player()
	
# Save the BKMREngine session data to a local file.
# This function takes the provided 'lookup' and 'validator' values and creates a dictionary ('session_data') with them.
# The session data dictionary is then saved to a local file with the specified path ('user://bkmrsession.save').
# This function utilizes the 'BKMRLocalFileStorage' script to handle the data saving process.
# The function also logs debug information about the saved session.
func save_session(lookup: String, validator: String) -> void:
	# Log debug information about the session being saved
	BKMRLogger.debug("Saving session, lookup: " + str(lookup) + ", validator: " + str(validator))

	# Create a dictionary with 'lookup' and 'validator' values
	var session_data: Dictionary = {
		"lookup": lookup,
		"validator": validator
	}
	
	# Save the session data dictionary to a local file with the specified path
	BKMRLocalFileStorage.save_data("user://bkmrsession.save", session_data, "Saving BKMREngine session: ")

# Load BKMREngine session data from a local file.
# This function retrieves the session data stored in a local file with the specified path ('user://bkmrsession.save').
# The function uses the 'BKMRLocalFileStorage' script to handle the data loading process.
# If the loaded session data is an empty dictionary or null, the function logs a debug message indicating that no valid session data was found.
# Finally, the function logs an information message about the found session data and returns the loaded session data dictionary.
func load_session() -> Dictionary:
	# Initialize a variable to store the loaded BKMREngine session data
	var bkmr_session_data: Dictionary
	
	# Specify the path of the local file containing the BKMREngine session data
	var path: String = "user://bkmrsession.save"
	
	# Use the 'BKMRLocalFileStorage' script to retrieve the session data from the specified path
	bkmr_session_data = BKMRLocalFileStorage.get_data(path)
	
	# Print debug information about the loaded session data (for debugging purposes)
	print(bkmr_session_data)
	
	# Check if the loaded session data is an empty dictionary or null
	if bkmr_session_data == {} or null:
		# Log a debug message if no valid session data was found
		BKMRLogger.debug("No local BKMREngine session stored, or session data stored in incorrect format")
	
	# Log an information message about the found session data
	BKMRLogger.info("Found session data: " + str(bkmr_session_data))
	
	# Return the loaded session data dictionary
	return bkmr_session_data
