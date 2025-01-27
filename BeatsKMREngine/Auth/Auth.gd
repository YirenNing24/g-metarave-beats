extends Node

#TODO add error logging in the game ui in passkey registration if username for passkey registration already taken


# Constants for utility scripts
const BKMRLocalFileStorage: Script = preload("res://BeatsKMREngine/utils/BKMRLocalFileStorage.gd")
const BKMRUtils: Script = preload("res://BeatsKMREngine/utils/BKMRUtils.gd")
const BKMRLogger: Script = preload("res://BeatsKMREngine/utils/BKMRLogger.gd")
const UUID: Script = preload("res://BeatsKMREngine/utils/UUID.gd")

# Signals for various authentication and server interactions
signal bkmr_login_complete(result: Dictionary)
signal bkmr_google_login_complete
signal bkmr_logout_complete
signal bkmr_registration_complete
signal bkmr_google_registration_complete

signal bkmr_session_check_complete(session: Dictionary)
signal bkmr_token_renew_complete(tokens: Dictionary)

signal bkmr_google_registration_passkey_complete(message: Dictionary)
signal bkmr_google_registration_passkey_verify_complete(message: Dictionary)

signal bkmr_google_login_passkey_complete(message: Dictionary)
signal bkmr_google_login_passkey_verify_complete(message: Dictionary)

# Variables to store authentication and session information
var tmp_username: String
var logged_in_player: String
var logged_in_player_email: String
var logged_in_anon: bool = false
var bkmr_id_token: String
var VerifyEmail: String
var ResendConfCode: String

# Server host URL
#var host: String = BKMREngine.host


var access_token: String
var refresh_token: String
var login_type: String
var last_login_type: String
var google_auth: bool = false

var LoginPlayer: HTTPRequest
var wrLoginPlayer: WeakRef

var ValidateSession: HTTPRequest 
var wrValidateSession: WeakRef

var GoogleValidateSession: HTTPRequest 
var wrGoogleValidateSession: WeakRef

var RegisterPlayer: HTTPRequest
var wrRegisterPlayer: WeakRef

var VersionCheck: HTTPRequest
var wrVersionCheck: WeakRef = null

var GoogleRegisterPlayer: HTTPRequest
var wrGoogleRegisterPlayer: WeakRef

var GoogleRegisterPasskey: HTTPRequest
var wrGoogleRegisterPasskey: WeakRef

var GoogleLoginPasskey: HTTPRequest
var wrGoogleLoginPasskey: WeakRef

var GoogleVerifyPasskey: HTTPRequest
var wrGoogleVerifyPasskey: WeakRef


var GoogleLoginPlayer: HTTPRequest
var wrGoogleLoginPlayer: WeakRef

var GoogleVerifyPasskeyLogin: HTTPRequest
var wrGoogleVerifyPasskeyLogin: WeakRef

var RenewToken: HTTPRequest
var wrRenewToken: WeakRef

# Timer variables for login timeout and session check wait
var login_timeout: int = 0
var login_timer: Timer
var complete_session_check_wait_timer: Timer

var google_token: String


#region Init functions


func _ready() -> void:
	pass


# Function to attempt automatic player login based on saved session data
func auto_login_player() -> void:
	# Load saved BKMREngine session data
	var bkmr_session_data: Dictionary = await load_session()
	BKMRLogger.debug("BKMR session data " + str(bkmr_session_data))
	
	# Check if session data is available for autologin
	if bkmr_session_data:
		BKMRLogger.debug("Found saved BKMREngine session data, attempting autologin...")
		# Extract access and refresh token from the saved session data
		if bkmr_session_data.has("access_token") and bkmr_session_data.has("refresh_token") and bkmr_session_data.has("login_type"):
			access_token = bkmr_session_data.access_token
			refresh_token = bkmr_session_data.refresh_token
			last_login_type = bkmr_session_data.login_type
			if last_login_type == 'beats':
				validate_player_session()
			elif last_login_type == 'passkey':
				validate_player_session()
			#elif last_login_type == 'google':
				#SignInClient.request_server_side_access(BKMREngine.google_server_client_id, true)
			else:
				complete_session_check({})
		else:
			BKMRLogger.debug("No saved BKMREngine session data, so no autologin will be performed")
			# Set up a timer to delay the emission of the signal for a short duration
			setup_complete_session_check_wait_timer()
			complete_session_check_wait_timer.start()
	else:
		# If no saved session data is available, log the absence and initiate a delayed session check
		BKMRLogger.debug("No saved BKMREngine session data, so no autologin will be performed")
		
		# Set up a timer to delay the emission of the signal for a short duration
		setup_complete_session_check_wait_timer()
		complete_session_check_wait_timer.start()


# Function to validate an existing player session using refresh_token
func validate_player_session() -> void:
	# Prepare the HTTP request for session validation
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	ValidateSession = prepared_http_req.request
	wrValidateSession = prepared_http_req.weakref
	var _validate_session: int = ValidateSession.request_completed.connect(_on_ValidateSession_request_completed)
	
	# Log the initiation of player session validation
	BKMRLogger.info("Calling BKMREngine to validate an existing player session")
	# Create the payload with lookup and access tokens
	var payload: Dictionary = {}
	# Log the payload details
	BKMRLogger.debug("Validate session payload: " + str(payload))
	# Construct the request URL
	var request_url: String = BKMREngine.host + "/api/validate-session/beats"
	# Send the POST request for session validation
	BKMREngine.send_login_request(ValidateSession, request_url, payload)
	# Return the current script instance


# Event handler for the completion of the player session validation request
func _on_ValidateSession_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the status of the HTTP response
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Handle the result based on the status check
	if status_check:
		# Parse the JSON body of the response
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body == null:
			complete_session_check({ })
			return
			
		var result_body: Dictionary = json_body
		# Build a result dictionary from the JSON body
		var _bkmr_result: Dictionary = BKMREngine.build_result(result_body)

		if json_body.has("error"):
			BKMRLogger.error("BKMREngine validate session failure: " + str(json_body.error))
		elif json_body.has("success"):
			# Log success and set the player as logged in
			BKMRLogger.info("BKMREngine validate session success.")
			
			var username: String = json_body.username
			set_player_logged_in(username)
			
		if "accessToken" in json_body.keys():
			BKMRLogger.debug("Remember me access: " + str(json_body.accessToken))
			# Save the session and set the player as logged in
			access_token = json_body.accessToken
			refresh_token = json_body.refreshToken
			login_type = json_body.loginType
			
			bkmr_login_complete.emit(result_body)
			save_session(access_token, refresh_token, login_type)

		# Trigger the completion of the session check with the result
		complete_session_check(result_body)
		renew_access_token_timer()
	else:
		# Trigger the completion of the session check with an empty result in case of failure
		complete_session_check({ })
#endregion


#region Registration functions
func register_player(username: String, password: String ) -> void:
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	RegisterPlayer = prepared_http_req.request
	wrRegisterPlayer = prepared_http_req.weakref
	var _register_signal: int = RegisterPlayer.request_completed.connect(_on_RegisterPlayer_request_completed)
	BKMRLogger.info("Calling BKMRServer to register a player")
	
	var payload: Dictionary = { 
		"userName": username, 
		"password": password,
		"deviceId": OS.get_model_name()
	}
	
	var request_url: String = BKMREngine.host + "/api/register/beats"
	BKMREngine.send_post_request(RegisterPlayer, request_url, payload)


# Callback function triggered upon completion of the player registration request
func _on_RegisterPlayer_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
	if status_check:
		BKMRLogger.info("BKMREngine register player success")
		bkmr_registration_complete.emit({ "success": "Registration Successful" })
	else:
		if json_body != null or "":
			if "error" in json_body:
				bkmr_registration_complete.emit({ "error": json_body })
			else:
				BKMRLogger.error("BKMREngine player registration failure: " + str(json_body))
				bkmr_registration_complete.emit({ "error": str(json_body) })
		else:
			BKMRLogger.error("Unknown server Error")
			
			
func register_google(token: String) -> void:
	# Prepare HTTP request
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	GoogleRegisterPlayer = prepared_http_req.request
	wrGoogleRegisterPlayer = prepared_http_req.weakref
	
	# Connect the signal for handling registration completion
	var _register_signal: int = GoogleRegisterPlayer.request_completed.connect(_on_GoogleRegisterPlayer_request_completed)
	
	# Log registration initiation
	BKMRLogger.info("Calling BKMRServer to register a player")
	
	# Prepare payload and send a POST request
	var payload: Dictionary = {
		"serverToken": token
	}
	var request_url: String = BKMREngine.host + "/api/register/google"
	BKMREngine.send_post_request(GoogleRegisterPlayer, request_url, payload)
	
	
func _on_GoogleRegisterPlayer_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Free the HTTP request resources
	BKMREngine.free_request(wrGoogleRegisterPlayer, GoogleRegisterPlayer)
	
	# Parse the JSON body of the response
	var json_body: Variant= JSON.parse_string(body.get_string_from_utf8())

	# Check if the registration was successful
	if status_check:
		# Log the successful registration and emit a signal
		BKMRLogger.info("BKMREngine register player success")
		bkmr_google_registration_complete.emit({"success": "Registration Successful"})
	else:
		# Log the registration failure and emit a signal with an error message
		BKMRLogger.error("BKMREngine player registration failure: " + str(json_body.message))
		bkmr_google_registration_complete.emit({"error": str(json_body.message)})


func register_google_passkey(username: String) -> void:
	# Prepare HTTP request
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	GoogleRegisterPasskey = prepared_http_req.request
	wrGoogleRegisterPasskey = prepared_http_req.weakref
	
	# Connect the signal for handling registration completion
	var _register_signal: int = GoogleRegisterPasskey.request_completed.connect(_on_GoogleRegisterPasskey_request_completed)
	
	# Prepare payload and send a POST request
	var payload: Dictionary = { "username": username }
	var request_url: String = BKMREngine.host + "/api/register/passkey"
	BKMREngine.send_post_request(GoogleRegisterPasskey, request_url, payload)
	
	
func _on_GoogleRegisterPasskey_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	# Free the HTTP request resources
	BKMREngine.free_request(wrGoogleRegisterPasskey, GoogleRegisterPasskey)
	
	# Parse the JSON body of the response
	var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
	if json_body != null:
	# Check if the registration was successful
		if status_check:
			if json_body is Dictionary:
				var challenge: Dictionary = json_body
				BeatsPasskey.beats_create_passkey(challenge)
		else:
			bkmr_google_registration_passkey_complete.emit({"error": json_body})
	else:
		bkmr_google_registration_passkey_complete.emit({"error": "Unknown server error"})
		
		
func beats_passkey_registration_response(result: Dictionary) -> void:
	_beats_passkey_registration_verification(result)
	
	
func _beats_passkey_registration_verification(result: Dictionary) -> void:
	# Prepare HTTP request
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	GoogleVerifyPasskey = prepared_http_req.request
	wrGoogleVerifyPasskey = prepared_http_req.weakref
	
	# Connect the signal for handling registration completion
	var _register_signal: int = GoogleVerifyPasskey.request_completed.connect(_on_GoogleVerifyPasskeyRegistration_request_completed)
		
	result.deviceId = OS.get_model_name()
	# Prepare payload and send a POST request
	var payload: Dictionary = result
	var request_url: String = BKMREngine.host + "/api/register/passkey/verify-registration"
	BKMREngine.send_post_request(GoogleVerifyPasskey, request_url, payload)
	
	
func _on_GoogleVerifyPasskeyRegistration_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Free the HTTP request resources
	BKMREngine.free_request(wrGoogleVerifyPasskey, GoogleVerifyPasskey)
	
	# Parse the JSON body of the response
	var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
	if json_body != null:
	# Check if the registration was successful
		if status_check:
			if json_body.has("error"):
				bkmr_google_registration_passkey_verify_complete.emit({"error": json_body})
			else:
				# Log additional information if present in the response
				if "accessToken" in json_body.keys():
					BKMRLogger.debug("Remember me access: " + str(json_body.accessToken))
				if "refreshToken" in json_body.keys():
					BKMRLogger.debug("Remember me refresh: " + str(json_body.refreshToken))
					
					# Save the session and set the player as logged in
					access_token = json_body.accessToken
					refresh_token  = json_body.refreshToken
					login_type = json_body.loginType
					save_session(access_token, refresh_token, login_type)
					var username: String = json_body.username
					set_player_logged_in(username)
					bkmr_google_login_passkey_verify_complete.emit(json_body)
					renew_access_token_timer()
		else:
			bkmr_google_registration_passkey_verify_complete.emit({ "error": json_body })
	else:
		bkmr_google_registration_passkey_verify_complete.emit({"error": "Unknown error"})
	
	
func login_player_google_passkey(username: String) -> void:
	# Prepare HTTP request
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	GoogleLoginPasskey = prepared_http_req.request
	wrGoogleLoginPasskey = prepared_http_req.weakref
	
	# Connect the signal for handling registration completion
	var _register_signal: int = GoogleLoginPasskey.request_completed.connect(_on_GoogleLoginPasskey_request_completed)
	
	# Prepare payload and send a POST request
	var payload: Dictionary = {"username": username}
	var request_url: String = BKMREngine.host + "/api/login/passkey"
	BKMREngine.send_post_request(GoogleLoginPasskey, request_url, payload)
	
		
func _on_GoogleLoginPasskey_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Free the HTTP request resources
	BKMREngine.free_request(wrGoogleLoginPasskey, GoogleLoginPasskey)
	
	# Parse the JSON body of the response
	var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
	if json_body != null:
	# Check if the registration was successful
		if status_check:
			if json_body is Dictionary:
				var challenge: Dictionary = json_body
				BeatsPasskey.login_passkey(challenge)
		else:
			bkmr_google_login_passkey_complete.emit({"error": json_body})
	else:
		bkmr_google_login_passkey_complete.emit({"error": "Unknown error"})
		
	
func beats_passkey_login_response(result: Dictionary) -> void:
	_beats_passkey_login_verification(result)
	
	
func _beats_passkey_login_verification(result: Dictionary) -> void:
	# Prepare HTTP request
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	GoogleVerifyPasskeyLogin = prepared_http_req.request
	wrGoogleVerifyPasskeyLogin = prepared_http_req.weakref
	
	# Connect the signal for handling registration completion
	var _register_signal: int = GoogleVerifyPasskeyLogin.request_completed.connect(_on_GoogleVerifyPasskeyLogin_request_completed)
		
	result.deviceId = OS.get_model_name()

	# Prepare payload and send a POST request
	var payload: Dictionary = result
	var request_url: String = BKMREngine.host + "/api/login/passkey/verify-auth"
	BKMREngine.send_post_request(GoogleVerifyPasskeyLogin, request_url, payload)
		
		
func _on_GoogleVerifyPasskeyLogin_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Free the HTTP request resources
	BKMREngine.free_request(wrGoogleVerifyPasskeyLogin , GoogleVerifyPasskeyLogin)
	
	# Parse the JSON body of the response
	var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
	if json_body != null:
	# Check if the registration was successful
		if status_check:
			if json_body.has("error"):
				bkmr_google_login_passkey_verify_complete.emit({ "error": json_body })
			else:
				# Log additional information if present in the response
				if "accessToken" in json_body.keys():
					BKMRLogger.debug("Remember me access: " + str(json_body.accessToken))
				if "refreshToken" in json_body.keys():
					BKMRLogger.debug("Remember me refresh: " + str(json_body.refreshToken))
					# Save the session and set the player as logged in
					access_token = json_body.accessToken
					refresh_token  = json_body.refreshToken
					login_type = json_body.loginType
					save_session(access_token, refresh_token, login_type)
					var username: String = json_body.username
					set_player_logged_in(username)
					bkmr_google_login_passkey_verify_complete.emit(json_body)
					renew_access_token_timer()
		else:
			bkmr_google_login_passkey_verify_complete.emit({"error": json_body})
	else:
		bkmr_google_login_passkey_verify_complete.emit({"error": "Unknown error"})
#endregion


#region Login functions
# Initiates a request to log in a player with the provided username and password
func login_player(username: String, password: String) -> void:
	# Store the username temporarily for reference in the callback function
	tmp_username = username
	
	# Prepare the HTTP request for player login
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	LoginPlayer = prepared_http_req.request
	wrLoginPlayer = prepared_http_req.weakref
	
	# Connect the callback function to handle the completion of the login request
	var _login_signal: int = LoginPlayer.request_completed.connect(_on_LoginPlayer_request_completed)
	
	# Log information about the login attempt
	BKMRLogger.info("Calling BKMREngine to log in a player")
	
	# Prepare the payload for the login request
	var payload: Dictionary = { "username": username, "password": password }
	
	# Obfuscate the password before logging and sending the request
	var payload_for_logging: Dictionary = payload
	var obfuscated_password: String = BKMRUtils.obfuscate_string(payload["password"])

	payload_for_logging["password"] = obfuscated_password
	BKMRLogger.debug("BKMREngine login player payload: " + str(payload_for_logging))
	
	# Define the request URL for player login
	var request_url: String = BKMREngine.host + "/api/login/beats"
	
	# Send the POST request to initiate player login
	BKMREngine.send_login_request(LoginPlayer, request_url, payload)
	

# Callback function triggered upon completion of the player login request
func _on_LoginPlayer_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	if status_check:
		# Parse the JSON body of the response
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body == null:
			bkmr_login_complete.emit({"error": "Unknown server error"})
			return
			
		# Log additional information if present in the response
		if "accessToken" in json_body.keys():
			BKMRLogger.debug("Remember me access: " + str(json_body.accessToken))
		if "refreshToken" in json_body.keys():
			BKMRLogger.debug("Remember me refresh: " + str(json_body.refreshToken))
			
			# Save the session and set the player as logged in
			access_token = json_body.accessToken
			refresh_token  = json_body.refreshToken
			login_type = json_body.loginType
			save_session(access_token, refresh_token, login_type)
			var username: String = json_body.username
			set_player_logged_in(username)
			bkmr_login_complete.emit(json_body)
			renew_access_token_timer()
		elif json_body.has("error"):
			# Emit login failure if no token is present
			bkmr_login_complete.emit(json_body)
			BKMRLogger.error("BKMREngine login player failure: " + str(json_body.error))
	else:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		# Handle cases where the JSON parsing fails or the server returns an unknown error
		if json_body == null:
			bkmr_login_complete.emit({"error": "Unknown server error"})
		else:
			if json_body.has("name"):
				if json_body.name == "Error":
					bkmr_login_complete.emit({"error": json_body.message})
			elif json_body.has("error"):
				bkmr_login_complete.emit({"error": json_body.error})
			else:
				bkmr_login_complete.emit({"error": "Unknown server error"})
				

# Login function for google login
func google_login_player(token: String) -> void:
	# Prepare the HTTP request for player login
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	GoogleLoginPlayer = prepared_http_req.request
	wrGoogleLoginPlayer = prepared_http_req.weakref
	
	# Connect the callback function to handle the completion of the login request
	var _login_signal: int = GoogleLoginPlayer.request_completed.connect(_on_GoogleLoginPlayer_request_completed)
	
	# Log information about the login attempt
	BKMRLogger.info("Calling BKMREngine to log in a player")
	
	# Prepare the payload for the login request
	var payload: Dictionary = {"serverToken": token}
	 
	# Obfuscate the password before logging and sending the request
	var payload_for_logging: Dictionary = payload
	BKMRLogger.debug("BKMREngine login player payload: " + str(payload_for_logging))
	
	# Define the request URL for player login
	var request_url: String = BKMREngine.host + "/api/login/google"
	
	# Send the POST request to initiate player login
	BKMREngine.send_post_request(GoogleLoginPlayer, request_url, payload)



# Callback function triggered upon completion of the player login request
func _on_GoogleLoginPlayer_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status and free the request resources
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	# Process the response based on the status check

	if status_check:
		# Parse the JSON body of the response
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body == null:
			bkmr_google_login_complete.emit({})
			return

		# Log additional information if present in the response
		if "refreshToken" in json_body.keys():
			BKMRLogger.debug("Remember me refresh: " + str(json_body.refreshToken))
		if "accessToken" in json_body.keys():
			BKMRLogger.debug("Remember me access: " + str(json_body.accessToken))
			
			# Save the session and set the player as logged in
			access_token = json_body.accessToken
			refresh_token = json_body.refresh_token
			login_type = json_body.loginType
			
			save_session(access_token, refresh_token, login_type)
			
			var username: String = json_body.username
			set_player_logged_in(username)
			
			bkmr_google_login_complete.emit(json_body)
			var session_body: Dictionary = json_body
			
			complete_session_check(session_body)
			renew_access_token_timer()
		elif json_body.has("error"):
			# Emit login failure if no token is present
			bkmr_google_login_complete.emit(json_body)
			BKMRLogger.error("BKMREngine login player failure: " + str(json_body.error))
	else:
		# Handle cases where the JSON parsing fails or the server returns an unknown error
		if JSON.parse_string(body.get_string_from_utf8()) != null:
			var json_body: Dictionary = JSON.parse_string(body.get_string_from_utf8())
			bkmr_google_login_complete.emit(json_body)
		else:
			bkmr_google_login_complete.emit({"error": "Unknown server error"})
#endregion

#region Log-out functions
# Function to log out the player
func logout_player() -> void:
	# Clear the logged-in player information
	logged_in_player = ""
	
	# Remove stored session if any and log the deletion success
	var delete_success: bool = remove_stored_session()
	print("delete_success: " + str(delete_success))
	
	# Emit signal indicating completion of player logout
	bkmr_logout_complete.emit()
	get_tree().quit()


# Set the currently logged-in player and configure session timeout if applicable
func set_player_logged_in(player_name: String) -> void:
	# Set the global variable for the logged-in player
	logged_in_player = player_name
	
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
	
	
# Remove stored BKMREngine session data from the user data directory.
func remove_stored_session() -> bool:
	if OS.get_name() == "Android":
		BeatsSessionTokens.clear_jwt_tokens()
	else:
	# Define the path to the file storing the BKMREngine session data
		var path: String = "user://bkmrsession.save"
		# Attempt to delete the file and log the result
		var delete_success: bool = BKMRLocalFileStorage.remove_data(path, "Removing BKMREngine session if any: " )
		return delete_success
	# Return the success status of the removal operation
	return true
#endregion


#region Util functions

func renew_access_token_timer() -> void:
	# Create a timer that fires every 4 minutes (240 seconds)
	var timer: SceneTreeTimer = get_tree().create_timer(240.0)
	var _renew: int = timer.timeout.connect(renew_access_token_timer)
	var _connect: int = timer.timeout.connect(request_new_access_token)
	print("renewing_token")
	# Start the timer


# Function to be called when the timer fires
func request_new_access_token() -> void:
	# This function will be called every 4 minutes
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	RenewToken = prepared_http_req.request
	wrRenewToken = prepared_http_req.weakref
	# Add your JWT decoding logic here
	var _new_token_signal: int = RenewToken.request_completed.connect(_on_RequestNewAccessToken_completed)
		# Log the initiation of player session validation
	BKMRLogger.info("Calling BKMREngine to validate an existing player session")
	# Create the payload with lookup and access tokens
	var payload: Dictionary = {}
	# Log the payload details
	BKMRLogger.debug("Validate session payload: " + str(payload))
	var request_url: String = BKMREngine.host + "/api/renew/access"
	# Send the POST request for session validation
	BKMREngine.send_login_request(RenewToken, request_url, payload)
	# Return the current script instance


func _on_RequestNewAccessToken_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the status of the HTTP response
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	# Handle the result based on the status check
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body == null:
			bkmr_token_renew_complete.emit({})
			return
		if json_body.has("error"):
			BKMRLogger.error("BKMREngine renew token failure: " + str(json_body.error))
			return
			
		var result_body: Dictionary = json_body
		var _bkmr_result: Dictionary = BKMREngine.build_result(result_body)
		if "refreshToken" in json_body.keys():
			BKMRLogger.debug("Remember me access: " + str(json_body.accessToken))
			# Save the session and set the player as logged in
			refresh_token = json_body.refreshToken
			access_token = json_body.accessToken
			save_session(access_token, refresh_token, login_type)
			bkmr_token_renew_complete.emit(json_body)
	else:
		# Trigger the completion of the session check with an empty result in case of failure
		bkmr_token_renew_complete.emit({})
	
	
# Complete the BKMREngine session check and emit the corresponding signal.
func complete_session_check(session_check: Dictionary = {}) -> void:
	# Log a debug message indicating the completion of the session check
	BKMRLogger.debug("BKMREngine: completing session check")
	# Emit the 'bkmr_session_check_complete' signal with the provided result
	bkmr_session_check_complete.emit(session_check)


# Set up a timer to delay the emission of the 'bkmr_session_check_complete' signal.
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
func save_session(token_access: String, token_refresh: String, type_login: String) -> void:
	# Log debug information about the session being saved
	BKMRLogger.debug("Saving session, access: " + str(token_access) + ", refresh: " + str(token_refresh))
	var session_data: Dictionary = {
		"access_token": token_access,
		"refresh_token": token_refresh,
		"login_type": type_login
	}
	# Check if the OS is Android
	if OS.get_name() == "Android":
		BeatsSessionTokens.store_jwt_tokens(session_data)
	else:
		# Save the session data dictionary to a local file with the specified path
		BKMRLocalFileStorage.save_data("user://bkmrsession.save", session_data, "Saving BKMREngine session: ")


# Load BKMREngine session data from a local file.
func load_session() -> Dictionary:
	# Check if the OS is Android
	if OS.get_name() == "Android":
		# Log debug information about loading session for Android
		BKMRLogger.debug("Loading session from Android plugin")
		var session_data: Dictionary = await BeatsSessionTokens.retrieve_jwt_tokens()
		if session_data == {} or session_data == null:
			BKMRLogger.debug("No session data found on Android plugin")
			return {}
		BKMRLogger.info("Loaded session data from Android: " + str(session_data))
		return session_data
	else:
		# Log debug information about loading session from local storage
		BKMRLogger.debug("Loading session from local file storage")
		var path: String = "user://bkmrsession.save"
		
		# Retrieve the session data using BKMRLocalFileStorage
		var session_data: Dictionary = BKMRLocalFileStorage.get_data(path)
		
		if session_data == {} or session_data == null:
			BKMRLogger.debug("No local BKMREngine session stored, or session data stored in incorrect format")
			return {}
		
		BKMRLogger.info("Loaded session data from local storage: " + str(session_data))
		return session_data



#endregion
