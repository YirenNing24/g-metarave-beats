extends Node

const BKMRLocalFileStorage: Script = preload("res://BeatsKMREngine/utils/BKMRLocalFileStorage.gd")
const BKMRUtils: Script = preload("res://BeatsKMREngine/utils/BKMRUtils.gd")
const BKMRLogger: Script = preload("res://BeatsKMREngine/utils/BKMRLogger.gd")
const UUID: Script = preload("res://BeatsKMREngine/utils/UUID.gd")

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

var tmp_username: String
var logged_in_player: String
var logged_in_player_email: String
var logged_in_anon: bool = false
var bkmr_access_token: String
var bkmr_id_token: String

var host: String = "http://192.168.4.117:8081"

var VersionCheck: HTTPRequest
var RegisterPlayer: HTTPRequest
var VerifyEmail: String
var ResendConfCode: String
var LoginPlayer: HTTPRequest
var ValidateSession: HTTPRequest

#weakref
var bkmrVersionCheck:Object = null
var bkmrValidateSession: WeakRef

var bkmrRegisterPlayer: WeakRef
var bkmrLoginPlayer: WeakRef
var login_timeout: int = 0
var login_timer: Timer

var complete_session_check_wait_timer: Timer


func check_version(config: Dictionary) -> Node:
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	VersionCheck = prepared_http_req.request
	bkmrVersionCheck = prepared_http_req.weakref
	var _signal_version_check: int = VersionCheck.request_completed.connect(_on_VersionCheck_request_completed)
	BKMRLogger.info("Calling BKMRServer to check game version")
	var payload: Dictionary = config
	var request_url: String = host + "/api/version-check/beats"
	BKMREngine.send_post_request(VersionCheck, request_url, payload)
	return self
	

func _on_VersionCheck_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:

	var _status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	var json_body: String = body.get_string_from_utf8()
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

func register_player(email: String, username: String, password: String, firstname: String, lastname: String ) -> Node:
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	RegisterPlayer = prepared_http_req.request
	bkmrRegisterPlayer = prepared_http_req.weakref
	var _register_signal:int = RegisterPlayer.request_completed.connect(_on_RegisterPlayer_request_completed)
	BKMRLogger.info("Calling BKMRServer to register a player")
	var payload: Dictionary = { 
		"anon": false, 
		"email":  email,  
		"userName": username, 
		"password": password, 
		"firstName": firstname, 
		"lastName": lastname }
	var request_url: String = host + "/api/register/beats"
	BKMREngine.send_post_request(RegisterPlayer, request_url, payload)
	return self

func _on_RegisterPlayer_request_completed(_result: Dictionary, response_code: int, headers: Array, body: PackedByteArray) -> void:
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	BKMREngine.free_request(bkmrRegisterPlayer, RegisterPlayer)
	var json_body: Dictionary = JSON.parse_string(body.get_string_from_utf8())
	var _bkmr_result: Dictionary
	if status_check:
		_bkmr_result = {"success": str(json_body.username)}
		BKMRLogger.info("BKMREngine register player success, username: " + json_body.username)
		bkmr_registration_complete.emit(_bkmr_result)
	else:
		_bkmr_result = {"error": str(json_body.message)}
		BKMRLogger.error("BKMREngine player registration failure: " + str(json_body.message))
		bkmr_registration_complete.emit(_bkmr_result)
#			#bkmr_token = json_body.swtoken
#			var anon = json_body.anon
#			if anon:
#				BKMRLogger.info("Anonymous Player registration succeeded")
#				logged_in_anon = true
#				if 'player_name' in json_body:
#					logged_in_player = json_body.player_name
#				elif 'player_local_id' in json_body: 
#					logged_in_player = str("anon##" + json_body.player_local_id)
#				else:
#					logged_in_player = "anon##unknown"
#				BKMRLogger.info("Anonymous registration, logged in player: " + str(logged_in_player))
#			else: 
#				# if email confirmation is enabled for the game, we can't log in the player just yet
#				var email_conf_enabled = json_body.email_conf_enabled
#				if email_conf_enabled:
#					BKMRLogger.info("Player registration succeeded, but player still needs to verify email address")
#				else:
#					BKMRLogger.info("Player registration succeeded, email verification is disabled")
#					logged_in_player = tmp_username
#		else:
#			BKMRLogger.error("BKMREngine player registration failure: " + str(json_body.error))
#		bkmr_registration_complete.emit(bkmr_result)

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


func login_player(username: String, password: String ) -> Node:
	tmp_username = username
	var prepared_http_req:Dictionary = BKMREngine.prepare_http_request()
	LoginPlayer = prepared_http_req.request
	bkmrLoginPlayer = prepared_http_req.weakref
	var _login_signal: int = LoginPlayer.request_completed.connect(_on_LoginPlayer_request_completed)
	BKMRLogger.info("Caling BKMREngine to log in a player")
	var payload:Dictionary = { "username": username, "password": password }
	var payload_for_logging: Dictionary = payload
	var obfuscated_password: String = BKMRUtils.obfuscate_string(payload["password"])
	print("obfuscated password: " + str(obfuscated_password))
	payload_for_logging["password"] = obfuscated_password
	BKMRLogger.debug("BKMREngine login player payload: " + str(payload_for_logging))
	var request_url:String = host + "/api/login/beats"
	BKMREngine.send_post_request(LoginPlayer, request_url, payload)
	return self


func _on_LoginPlayer_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	BKMREngine.free_request(bkmrLoginPlayer, LoginPlayer)
	if status_check:
		@warning_ignore("unused_variable")
		var json_body: Dictionary = JSON.parse_string(body.get_string_from_utf8())
		if "lookup" in json_body.keys():
			BKMRLogger.debug("remember me lookup: " + str(json_body.lookup))
		if "validator" in json_body.keys():
			BKMRLogger.debug("remember me validator: " + str(json_body.validator))
			var body_lookup: String = json_body.lookup
			var body_validator: String = json_body.validator
			save_session(body_lookup, body_validator)
			set_player_logged_in(tmp_username)
			PLAYER.data = json_body.user
			bkmr_login_complete.emit(json_body)
		if "token" in json_body.keys():
			bkmr_access_token = json_body.token
		else:
			bkmr_login_complete.emit(json_body.error)
			BKMRLogger.error("BKMREngine login player failure: " + str(json_body.error))
	else:
		if JSON.parse_string(body.get_string_from_utf8()) != null:
			var json_body: Dictionary = JSON.parse_string(body.get_string_from_utf8())
			bkmr_login_complete.emit(json_body)
		else:
			print("unknown server error")
		
func logout_player() -> void:
	logged_in_player = ""
	# remove stored session if any
	var delete_success: bool = remove_stored_session()
	print("delete_success: " + str(delete_success))
	bkmr_access_token = ""
	bkmr_id_token = ""
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

#func _on_ResetPassword_completed(_result, response_code, headers, body) -> void:
	#var status_check = BKMRUtils.check_http_response(response_code, headers, body)
	#BKMREngine.free_request(bkmrResetPassword, ResetPassword)
#
	#if status_check:
		#var json_body = JSON.parse_string(body.get_string_from_utf8())
		#var bkmr_result: Dictionary = BKMREngine.build_result(json_body)
		#if json_body.success:
			#BKMRLogger.info("BKMREngine reset player password success.")
		#else:
			#BKMRLogger.error("BKMREngine reset password failure: " + str(json_body.error))
		#bkmr_reset_password_complete.emit(bkmr_result)

#func get_player_details(player_name: String) -> Node:
	#var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	#GetPlayerDetails = prepared_http_req.request
	#bkmrGetPlayerDetails = prepared_http_req.weakref
	#GetPlayerDetails.request_completed.connect(_on_GetPlayerDetails_request_completed)
	#BKMRLogger.info("Calling BKMREngine to get player details")
	#var payload:  = { "apiId": BKMREngine.config.apiId, "player_name": player_name }
	#var request_url = host + "api/get_player_details"
	#BKMREngine.send_post_request(GetPlayerDetails, request_url, payload)
	#return self

#func _on_GetPlayerDetails_request_completed(_result, response_code, headers, body) -> void:
	#var status_check = BKMRUtils.check_http_response(response_code, headers, body)
	#BKMREngine.free_request(bkmrGetPlayerDetails, GetPlayerDetails)
	#if status_check:
		#var json_body = JSON.parse_string(body.get_string_from_utf8())
		#var bkmr_result: Dictionary = BKMREngine.build_result(json_body)
		#if json_body.success:
			#BKMRLogger.info("BKMREngine get player details success: " + str(json_body.player_details))
			#bkmr_result["player_details"] = json_body.player_details
		#else:
			#BKMRLogger.error("BKMREngine get player details failure: " + str(json_body.error))
		#bkmr_get_player_details_complete.emit(bkmr_result)
		
func auto_login_player() -> Node:
	var bkmr_session_data: Dictionary = load_session()
	BKMRLogger.debug("BKMR session data " + str(bkmr_session_data))
	if bkmr_session_data:
		BKMRLogger.debug("Found saved BKMREngine session data, attempting autologin...")
		var lookup: String = bkmr_session_data.lookup
		var validator: String = bkmr_session_data.validator
		var _validate_session: Node = validate_player_session(lookup, validator)
	else:
		BKMRLogger.debug("No saved BKMREngine session data, so no autologin will be performed")
		# the following is needed to delay the emission of the signal just a little bit, otherwise the signal is never received!
		setup_complete_session_check_wait_timer()
		complete_session_check_wait_timer.start()
	return self
	
	
func validate_player_session(lookup: String, validator: String, _scene: Node=get_tree().get_current_scene()) -> Node:
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	ValidateSession = prepared_http_req.request
	bkmrValidateSession = prepared_http_req.weakref
	var _validate_session: int = ValidateSession.request_completed.connect(_on_ValidateSession_request_completed)
	BKMRLogger.info("Calling BKMREngine to validate an existing player session")
	var payload: Dictionary  = {"lookup": lookup, "validator": validator }
	bkmr_access_token = validator
	BKMRLogger.debug("Validate session payload: " + str(payload))
	var request_url: String = host + "/api/validate_session/beats"
	BKMREngine.send_post_request(ValidateSession, request_url, payload)
	return self
	
	
func _on_ValidateSession_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	BKMREngine.free_request(bkmrValidateSession, ValidateSession)
	if status_check:
		var json_body: Dictionary = JSON.parse_string(body.get_string_from_utf8())
		var bkmr_result: Dictionary = BKMREngine.build_result(json_body)
		if json_body.has("error"):
			BKMRLogger.error("BKMREngine validate session failure: " + str(json_body.error))
		elif json_body.has("success"):
			BKMRLogger.info("BKMREngine validate session success.")	
			var body_username: String = json_body.username
			set_player_logged_in(body_username)
			if json_body.has("bkmr_jwt"):
				bkmr_access_token = json_body.bkmr_jwt
				
			PLAYER.data = json_body
		complete_session_check(bkmr_result)
	else:
		complete_session_check({})

func set_player_logged_in(player_name: String) -> void:
	logged_in_player  = player_name
	BKMRLogger.info("BKMREngine - player logged in as " + str(player_name))
	if BKMREngine.auth_config.has("session_duration_seconds") and typeof(BKMREngine.auth_config.session_duration_seconds) == 2:
		login_timeout = BKMREngine.auth_config.session_duration_seconds
	else:
		login_timeout = 0
	BKMRLogger.info("BKMREngine login timeout: " + str(login_timeout))
	if login_timeout != 0:
		setup_login_timer()
	
	
func get_anon_user_id() -> String:
	var anon_user_id: String = OS.get_unique_id()
	if anon_user_id == '':
		anon_user_id = UUID.generate_uuid_v4()
	print("anon_user_id: " + str(anon_user_id))
	return anon_user_id
	
	
func remove_stored_session() -> bool:
	var path: String = "user://bkmrsession.save"
	var delete_success: bool = BKMRLocalFileStorage.remove_data(path, "Removing BKMREngine session if any: " )
	return delete_success
	
	
# Signal can't be emitted directly from auto_login_player() function
# otherwise it won't connect back to calling script
func complete_session_check(bkmr_result: Dictionary = {}) -> void:
	BKMRLogger.debug("BKMREngine: completing session check")
	bkmr_session_check_complete.emit(bkmr_result)
	
	
func setup_complete_session_check_wait_timer() -> void:
	complete_session_check_wait_timer = Timer.new()
	complete_session_check_wait_timer.set_one_shot(true)
	complete_session_check_wait_timer.set_wait_time(0.01)
	var _session_timer_signal: int = complete_session_check_wait_timer.timeout.connect(complete_session_check)
	add_child(complete_session_check_wait_timer)
	
	
func setup_login_timer() -> void:
	login_timer = Timer.new()
	login_timer.set_one_shot(true)
	login_timer.set_wait_time(login_timeout)
	var _timer_signal: int = login_timer.timeout.connect(on_login_timeout_complete)
	add_child(login_timer)
	
	
func on_login_timeout_complete() -> void:
	logout_player()
	
	
# store lookup (not logged in player name) and validator in local file
func save_session(lookup: String, validator: String) -> void:
	BKMRLogger.debug("Saving session, lookup: " + str(lookup) + ", validator: " + str(validator))

	var _path: String = "user://bkmrsession.save"
	var session_data: Dictionary = {
		"lookup": lookup,
		"validator": validator
	}
	BKMRLocalFileStorage.save_data("user://bkmrsession.save", session_data, "Saving BKMREngine session: ")
	
# reload lookup and validator and send them back to the server to auto-login user
func load_session() -> Dictionary:
	var bkmr_session_data: Dictionary
	var path: String = "user://bkmrsession.save"
	bkmr_session_data = BKMRLocalFileStorage.get_data(path)
	print(bkmr_session_data, "tae na mo gago")
	if bkmr_session_data == {} or null:
		BKMRLogger.debug("No local BKMREngine session stored, or session data stored in incorrect format")
	BKMRLogger.info("Found session data: " + str(bkmr_session_data))
	return bkmr_session_data
