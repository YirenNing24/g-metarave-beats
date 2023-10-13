extends Node

const BKMRLocalFileStorage = preload("res://utils/BKMRLocalFileStorage.gd")
const BKMRUtils = preload("res://utils/BKMRUtils.gd")
const BKMRLogger = preload("res://utils/BKMRLogger.gd")
const UUID = preload("res://utils/UUID.gd")

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


var tmp_username = null
var logged_in_player = null
var logged_in_player_email = null
var logged_in_anon = false
var bkmr_access_token = null
var bkmr_id_token = null

var VersionCheck = null
var RegisterPlayer = null
var VerifyEmail = null
var ResendConfCode = null
var LoginPlayer = null
var ValidateSession = null
var RequestPasswordReset = null
var ResetPassword = null
var GetPlayerDetails = null

var bkmrVersionCheck = null
var bkmrRegisterPlayer = null
var bkmrVerifyEmail = null
var bkmrResendConfCode = null
var bkmrLoginPlayer = null
var bkmrValidateSession = null
var bkmrRequestPasswordReset = null
var bkmrResetPassword = null
var bkmrGetPlayerDetails = null

var login_timeout = 0
var login_timer = null

var complete_session_check_wait_timer


func check_version(config: Dictionary):
	var prepared_http_req = BKMREngine.prepare_http_request()
	VersionCheck = prepared_http_req.request
	bkmrVersionCheck = prepared_http_req.weakref
	VersionCheck.request_completed.connect(_on_VersionCheck_request_completed)
	BKMRLogger.info("Calling BKMRServer to check game version")
	var payload = config
	var request_url = "http://api.gmetarave.art/api/version-check"
	BKMREngine.send_post_request(VersionCheck, request_url, payload)
	return self

@warning_ignore("unused_parameter")
func _on_VersionCheck_request_completed(result, response_code, headers, body) -> void:
	@warning_ignore("unused_variable")
	var status_check = BKMRUtils.check_http_response(response_code, headers, body)
	var json_body = body.get_string_from_utf8()
	bkmr_version_check_complete.emit(json_body)
	
func register_player_anon(player_name = null) -> Node:
	var user_local_id: String = get_anon_user_id()
	var prepared_http_req = BKMREngine.prepare_http_request()
	RegisterPlayer = prepared_http_req.request
	bkmrRegisterPlayer = prepared_http_req.weakref
	RegisterPlayer.request_completed.connect(_on_RegisterPlayer_request_completed)
	BKMRLogger.info("Calling BKMRServer to register an anonymous player")
	var payload = { "apiId": BKMREngine.config.apiId, "anon": true, "player_name": player_name, "user_local_id": user_local_id }
	var request_url = "http://api.gmetarave.art/api/register"
	BKMREngine.send_post_request(RegisterPlayer, request_url, payload)
	return self

func register_player(player_name: String, email: String, password: String, confirm_password: String) -> Node:
	tmp_username = player_name
	var prepared_http_req = BKMREngine.prepare_http_request()
	RegisterPlayer = prepared_http_req.request
	bkmrRegisterPlayer = prepared_http_req.weakref
	RegisterPlayer.request_completed.connect(_on_RegisterPlayer_request_completed)
	BKMRLogger.info("Calling BKMRServer to register a player")
	var payload = { "apiId": BKMREngine.config.apiId, "anon": false, "player_name": player_name, "email":  email, "password": password, "confirm_password": confirm_password }
	var request_url = "http://api.gmetarave.art/api/register"
	BKMREngine.send_post_request(RegisterPlayer, request_url, payload)
	return self

@warning_ignore("unused_parameter")
func _on_RegisterPlayer_request_completed(result, response_code, headers, body) -> void:
	var status_check = BKMRUtils.check_http_response(response_code, headers, body)
	BKMREngine.free_request(bkmrRegisterPlayer, RegisterPlayer)
	
	if status_check:
		var json_body = JSON.parse_string(body.get_string_from_utf8())
		# also get a JWT token here, when available in backend
		# send a different signal depending on registration success or failure
		var bkmr_result: Dictionary = BKMREngine.build_result(json_body)
		if json_body.success:
			BKMRLogger.info("BKMREngine register player success, player_name: " + str(json_body.player_name))
			#bkmr_token = json_body.swtoken
			var anon = json_body.anon
			if anon:
				BKMRLogger.info("Anonymous Player registration succeeded")
				logged_in_anon = true
				if 'player_name' in json_body:
					logged_in_player = json_body.player_name
				elif 'player_local_id' in json_body: 
					logged_in_player = str("anon##" + json_body.player_local_id)
				else:
					logged_in_player = "anon##unknown"
				BKMRLogger.info("Anonymous registration, logged in player: " + str(logged_in_player))
			else: 
				# if email confirmation is enabled for the game, we can't log in the player just yet
				var email_conf_enabled = json_body.email_conf_enabled
				if email_conf_enabled:
					BKMRLogger.info("Player registration succeeded, but player still needs to verify email address")
				else:
					BKMRLogger.info("Player registration succeeded, email verification is disabled")
					logged_in_player = tmp_username
		else:
			BKMRLogger.error("BKMREngine player registration failure: " + str(json_body.error))
		bkmr_registration_complete.emit(bkmr_result)


		
		
func register_player_user_password(player_name: String, password: String, confirm_password: String) -> Node:
	var prepared_http_req = BKMREngine.prepare_http_request()
	RegisterPlayer = prepared_http_req.request
	bkmrRegisterPlayer = prepared_http_req.weakref
	RegisterPlayer.request_completed.connect(_on_RegisterPlayerUserPassword_request_completed)
	BKMRLogger.info("Calling BKMRE to register a player")
	var payload = { "apiId": BKMREngine.config.apiId, "player_name": player_name, "password": password, "confirm_password": confirm_password }
	var request_url = "http://api.gmetarave.art/api/register"
	BKMREngine.send_post_request(RegisterPlayer, request_url, payload)
	return self


@warning_ignore("unused_parameter")
func _on_RegisterPlayerUserPassword_request_completed(result, response_code, headers, body) -> void:
	var status_check = BKMRUtils.check_http_response(response_code, headers, body)
	#RegisterPlayer.queue_free()
	BKMREngine.free_request(bkmrRegisterPlayer, RegisterPlayer)
	
	if status_check:
		var json_body = JSON.parse_string(body.get_string_from_utf8())
		# also get a JWT token here
		# send a different signal depending on registration success or failure
		var bkmr_result: Dictionary = BKMREngine.build_result(json_body)
		if json_body.success:
			# if email confirmation is enabled for the game, we can't log in the player just yet
			@warning_ignore("unused_variable")
			var email_conf_enabled = json_body.email_conf_enabled
			BKMRLogger.info("Player registration with username/password succeeded, player account autoconfirmed.")
			logged_in_player = tmp_username
		else:
			BKMRLogger.error("BKMR username/password player registration failure: " + str(json_body.error))
		bkmr_registration_user_pwd_complete.emit(bkmr_result)


func verify_email(player_name: String, code: String) -> Node:
	var prepared_http_req = BKMREngine.prepare_http_request()
	VerifyEmail = prepared_http_req.request
	bkmrVerifyEmail = prepared_http_req.weakref
	VerifyEmail.request_completed.connect(_on_VerifyEmail_request_completed)
	BKMRLogger.info("Calling BKMREngine to verify email address for: " + str(player_name))
	var payload = { "apiId": BKMREngine.config.apiId, "username":  player_name, "code": code }
	var request_url = "https://api.silentwolf.com/confirm_verif_code"
	BKMREngine.send_post_request(VerifyEmail, request_url, payload)
	return self


@warning_ignore("unused_parameter")
func _on_VerifyEmail_request_completed(result, response_code, headers, body) -> void:
	var status_check = BKMRUtils.check_http_response(response_code, headers, body)
	BKMREngine.free_request(bkmrVerifyEmail, VerifyEmail)
	
	if status_check:
		var json_body = JSON.parse_string(body.get_string_from_utf8())
		BKMREngine.info("BKMREngine verify email success? : " + str(json_body.success))
		# also get a JWT token here
		# send a different signal depending on registration success or failure
		var bkmr_result: Dictionary = BKMREngine.build_result(json_body)
		if json_body.success:
			BKMRLogger.info("BKMREngine email verification success.")
			logged_in_player  = tmp_username
		else:
			BKMRLogger.error("BKMREngine email verification failure: " + str(json_body.error))
		bkmr_email_verif_complete.emit(bkmr_result)


func resend_conf_code(player_name: String) -> Node:
	var prepared_http_req = BKMREngine.prepare_http_request()
	ResendConfCode = prepared_http_req.request
	bkmrResendConfCode = prepared_http_req.weakref
	ResendConfCode.request_completed.connect(_on_ResendConfCode_request_completed)
	BKMRLogger.info("Calling BKMREngine to resend confirmation code for: " + str(player_name))
	var payload = { "apiId": BKMREngine.config.apiId, "username": player_name }
	var request_url = "https://api.silentwolf.com/resend_conf_code"
	BKMREngine.send_post_request(ResendConfCode, request_url, payload)
	return self


@warning_ignore("unused_parameter")
func _on_ResendConfCode_request_completed(result, response_code, headers, body) -> void:
	BKMRLogger.info("ResendConfCode request completed")
	var status_check = BKMRUtils.check_http_response(response_code, headers, body)
	BKMREngine.free_request(bkmrResendConfCode, ResendConfCode)
	
	if status_check:
		var json_body = JSON.parse_string(body.get_string_from_utf8())
		# also get a JWT token here
		# send a different signal depending on registration success or failure
		var bkmr_result: Dictionary = BKMREngine.build_result(json_body)
		if json_body.success:
			BKMRLogger.info("BKMREngine resend conf code success.")
		else:
			BKMRLogger.error("BKMREngine resend conf code failure: " + str(json_body.error))
		bkmr_resend_conf_code_complete.emit(bkmr_result)


func login_player(username: String, password: String, remember_me:bool=false) -> Node:
	tmp_username = username
	var prepared_http_req = BKMREngine.prepare_http_request()
	LoginPlayer = prepared_http_req.request
	bkmrLoginPlayer = prepared_http_req.weakref
	LoginPlayer.request_completed.connect(_on_LoginPlayer_request_completed)
	BKMRLogger.info("Calling BKMREngine to log in a player")
	var payload = { "apiId": BKMREngine.config.apiId, "username": username, "password": password, "remember_me": str(remember_me) }
	if BKMREngine.auth_config.has("saved_session_expiration_days") and typeof(BKMREngine.auth_config.saved_session_expiration_days) == 2:
		payload["remember_me_expires_in"] = str(BKMREngine.auth_config.saved_session_expiration_days)
	var payload_for_logging = payload
	var obfuscated_password = BKMRUtils.obfuscate_string(payload["password"])
	print("obfuscated password: " + str(obfuscated_password))
	payload_for_logging["password"] = obfuscated_password
	BKMRLogger.debug("BKMREngine login player payload: " + str(payload_for_logging))
	var request_url = "https://api.silentwolf.com/login_player"
	BKMREngine.send_post_request(LoginPlayer, request_url, payload)
	return self


@warning_ignore("unused_parameter")
func _on_LoginPlayer_request_completed(result, response_code, headers, body) -> void:
	var status_check = BKMRUtils.check_http_response(response_code, headers, body)
	BKMREngine.free_request(bkmrLoginPlayer, LoginPlayer)
	
	if status_check:
		var json_body = JSON.parse_string(body.get_string_from_utf8())
		if "lookup" in json_body.keys():
			BKMRLogger.debug("remember me lookup: " + str(json_body.lookup))
			save_session(json_body.lookup, json_body.validator)
		if "validator" in json_body.keys():
			BKMRLogger.debug("remember me validator: " + str(json_body.validator))
		# send a different signal depending on login success or failure
		var bkmr_result: Dictionary = BKMREngine.build_result(json_body)
		if json_body.success:
			BKMRLogger.info("BKMREngine resend conf code success.")
			bkmr_access_token = json_body.swtoken
			bkmr_id_token = json_body.swidtoken
			set_player_logged_in(tmp_username)
		else:
			BKMRLogger.error("BKMREngine login player failure: " + str(json_body.error))
		bkmr_login_complete.emit(bkmr_result)


func logout_player() -> void:
	logged_in_player = null
	# remove any player data if present
	BKMREngine.Players.clear_player_data()
	# remove stored session if any
	var delete_success = remove_stored_session()
	print("delete_success: " + str(delete_success))
	bkmr_access_token = null
	bkmr_id_token = null
	bkmr_logout_complete.emit(true, "")


func request_player_password_reset(player_name: String) -> Node:
	var prepared_http_req = BKMREngine.prepare_http_request()
	RequestPasswordReset = prepared_http_req.request
	bkmrRequestPasswordReset = prepared_http_req.weakref
	RequestPasswordReset.request_completed.connect(_on_RequestPasswordReset_request_completed)
	BKMRLogger.info("Calling BKMREngine to request a password reset for: " + str(player_name))
	var payload = { "apiId": BKMREngine.config.apiId, "player_name": player_name }
	BKMRLogger.debug("BKMREngine request player password reset payload: " + str(payload))
	var request_url = "https://api.silentwolf.com/request_player_password_reset"
	BKMREngine.send_post_request(RequestPasswordReset, request_url, payload)
	return self


@warning_ignore("unused_parameter")
func _on_RequestPasswordReset_request_completed(result, response_code, headers, body) -> void:
	BKMRLogger.info("RequestPasswordReset request completed")
	var status_check = BKMRUtils.check_http_response(response_code, headers, body)
	BKMREngine.free_request(bkmrRequestPasswordReset, RequestPasswordReset)
	
	if status_check:
		var json_body = JSON.parse_string(body.get_string_from_utf8())
		var bkmr_result: Dictionary = BKMREngine.build_result(json_body)
		if json_body.success:
			BKMRLogger.info("BKMREngine request player password reset success.")
		else:
			BKMRLogger.error("BKMREngine request password reset failure: " + str(json_body.error))
		bkmr_request_password_reset_complete.emit(bkmr_result)


func reset_player_password(player_name: String, conf_code: String, new_password: String, confirm_password: String) -> Node:
	var prepared_http_req = BKMREngine.prepare_http_request()
	ResetPassword = prepared_http_req.request
	bkmrResetPassword = prepared_http_req.weakref
	ResetPassword.request_completed.connect(_on_ResetPassword_completed)
	BKMRLogger.info("Calling BKMREngine to reset password for: " + str(player_name))
	var payload = { "apiId": BKMREngine.config.apiId, "player_name": player_name, "conf_code": conf_code, "password": new_password, "confirm_password": confirm_password }
	BKMRLogger.debug("BKMREngine request player password reset payload: " + str(payload))
	var request_url = "https://api.silentwolf.com/reset_player_password"
	BKMREngine.send_post_request(ResetPassword, request_url, payload)
	return self


@warning_ignore("unused_parameter")
func _on_ResetPassword_completed(result, response_code, headers, body) -> void:
	var status_check = BKMRUtils.check_http_response(response_code, headers, body)
	BKMREngine.free_request(bkmrResetPassword, ResetPassword)

	if status_check:
		var json_body = JSON.parse_string(body.get_string_from_utf8())
		var bkmr_result: Dictionary = BKMREngine.build_result(json_body)
		if json_body.success:
			BKMRLogger.info("BKMREngine reset player password success.")
		else:
			BKMRLogger.error("BKMREngine reset password failure: " + str(json_body.error))
		bkmr_reset_password_complete.emit(bkmr_result)


func get_player_details(player_name: String) -> Node:
	var prepared_http_req = BKMREngine.prepare_http_request()
	GetPlayerDetails = prepared_http_req.request
	bkmrGetPlayerDetails = prepared_http_req.weakref
	GetPlayerDetails.request_completed.connect(_on_GetPlayerDetails_request_completed)
	BKMRLogger.info("Calling BKMREngine to get player details")
	var payload = { "apiId": BKMREngine.config.apiId, "player_name": player_name }
	var request_url = "https://api.silentwolf.com/get_player_details"
	BKMREngine.send_post_request(GetPlayerDetails, request_url, payload)
	return self


@warning_ignore("unused_parameter")
func _on_GetPlayerDetails_request_completed(result, response_code, headers, body) -> void:
	var status_check = BKMRUtils.check_http_response(response_code, headers, body)
	BKMREngine.free_request(bkmrGetPlayerDetails, GetPlayerDetails)
	
	if status_check:
		var json_body = JSON.parse_string(body.get_string_from_utf8())
		var bkmr_result: Dictionary = BKMREngine.build_result(json_body)
		if json_body.success:
			BKMRLogger.info("BKMREngine get player details success: " + str(json_body.player_details))
			bkmr_result["player_details"] = json_body.player_details
		else:
			BKMRLogger.error("BKMREngine get player details failure: " + str(json_body.error))
		bkmr_get_player_details_complete.emit(bkmr_result)


@warning_ignore("unused_parameter")
func validate_player_session(lookup: String, validator: String, scene: Node=get_tree().get_current_scene()) -> Node:
	var prepared_http_req = BKMREngine.prepare_http_request()
	ValidateSession = prepared_http_req.request
	bkmrValidateSession = prepared_http_req.weakref
	ValidateSession.request_completed.connect(_on_ValidateSession_request_completed)
	BKMRLogger.info("Calling BKMREngine to validate an existing player session")
	var payload = { "apiId": BKMREngine.config.apiId, "lookup": lookup, "validator": validator }
	BKMRLogger.debug("Validate session payload: " + str(payload))
	var request_url = "https://api.silentwolf.com/validate_remember_me"
	BKMREngine.send_post_request(ValidateSession, request_url, payload)
	return self


@warning_ignore("unused_parameter")
func _on_ValidateSession_request_completed(result, response_code, headers, body) -> void:
	var status_check = BKMRUtils.check_http_response(response_code, headers, body)
	BKMREngine.free_request(bkmrValidateSession, ValidateSession)
	
	if status_check:
		var json_body = JSON.parse_string(body.get_string_from_utf8())
		var bkmr_result: Dictionary = BKMREngine.build_result(json_body)
		if json_body.success:
			BKMRLogger.info("BKMREngine validate session success.")	
			set_player_logged_in(json_body.player_name)
			bkmr_result["logged_in_player"] = logged_in_player
		else:
			BKMRLogger.error("BKMREngine validate session failure: " + str(json_body.error))
		complete_session_check(bkmr_result)


func auto_login_player() -> Node:
	var bkmr_session_data = load_session()
	BKMRLogger.debug("SW session data " + str(bkmr_session_data))
	if bkmr_session_data:
		BKMRLogger.debug("Found saved BKMREngine session data, attempting autologin...")
		var lookup = bkmr_session_data.lookup
		var validator = bkmr_session_data.validator
		# whether successful or not, in the end the "bkmr_session_check_complete" signal will be emitted
		validate_player_session(lookup, validator)
	else:
		BKMRLogger.debug("No saved BKMREngine session data, so no autologin will be performed")
		# the following is needed to delay the emission of the signal just a little bit, otherwise the signal is never received!
		setup_complete_session_check_wait_timer()
		complete_session_check_wait_timer.start()
	return self


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
	var anon_user_id = OS.get_unique_id()
	if anon_user_id == '':
		anon_user_id = UUID.generate_uuid_v4()
	print("anon_user_id: " + str(anon_user_id))
	return anon_user_id


func remove_stored_session() -> bool:
	var path = "user://swsession.save"
	var delete_success = BKMRLocalFileStorage.remove_data(path, "Removing BKMREngine session if any: " )
	return delete_success


# Signal can't be emitted directly from auto_login_player() function
# otherwise it won't connect back to calling script
func complete_session_check(bkmr_result=null) -> void:
	BKMRLogger.debug("BKMREngine: completing session check")
	bkmr_session_check_complete.emit(bkmr_result)


func setup_complete_session_check_wait_timer() -> void:
	complete_session_check_wait_timer = Timer.new()
	complete_session_check_wait_timer.set_one_shot(true)
	complete_session_check_wait_timer.set_wait_time(0.01)
	complete_session_check_wait_timer.timeout.connect(complete_session_check)
	add_child(complete_session_check_wait_timer)


func setup_login_timer() -> void:
	login_timer = Timer.new()
	login_timer.set_one_shot(true)
	login_timer.set_wait_time(login_timeout)
	login_timer.timeout.connect(on_login_timeout_complete)
	add_child(login_timer)


func on_login_timeout_complete() -> void:
	logout_player()


# store lookup (not logged in player name) and validator in local file
func save_session(lookup: String, validator: String) -> void:
	BKMRLogger.debug("Saving session, lookup: " + str(lookup) + ", validator: " + str(validator))
	@warning_ignore("unused_variable")
	var path = "user://swsession.save"
	var session_data: Dictionary = {
		"lookup": lookup,
		"validator": validator
	}
	BKMRLocalFileStorage.save_data("user://bkmrsession.save", session_data, "Saving BKMREngine session: ")


# reload lookup and validator and send them back to the server to auto-login user
func load_session() -> Dictionary:
	var bkmr_session_data = null
	var path = "user://swsession.save"
	bkmr_session_data = BKMRLocalFileStorage.get_data(path)
	if bkmr_session_data == null:
		BKMRLogger.debug("No local BKMREngine session stored, or session data stored in incorrect format")
	BKMRLogger.info("Found session data: " + str(bkmr_session_data))
	return bkmr_session_data
