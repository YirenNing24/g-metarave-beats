extends Node

const version: String = "0.1"
var godot_version: String = Engine.get_version_info().string

const BKMRUtils: Script = preload("res://BeatsKMREngine/utils/BKMRUtils.gd")
const BKMRHashing: Script = preload("res://BeatsKMREngine/utils/BKMRHashing.gd")
const BKMRLogger: Script = preload("res://BeatsKMREngine/utils/BKMRLogger.gd")

@onready var Auth: Node = Node.new()
@onready var Profile: Node = Node.new()
@onready var Store: Node = Node.new()
@onready var Chat: Node = Node.new()

@onready var config: Dictionary = {}

var auth_config: Dictionary = {
	"session_duration_seconds": 0,
	"saved_session_expiration_days": 30
	}
 
var auth_script: Script = load("res://BeatsKMREngine/Auth/Auth.gd")
var profile_script: Script = load("res://BeatsKMREngine/Player/Profile.gd")
var store_script: Script = load("res://BeatsKMREngine/Store/Store.gd")
var chat_script: Script = load("res://BeatsKMREngine/Player/Chat.gd")

func _ready() -> void:
	await ENV_VAR.completed
	config = {
		"apiKey": ENV_VAR.apiKey,
		"apiId": ENV_VAR.apiId,
		"gameVersion": ENV_VAR.gameVersion,
		"logLevel": ENV_VAR.logLevel,
	}
	print("BKMR ready start timestamp: " + str(BKMRUtils.get_timestamp()))
	Auth.set_script(auth_script)
	add_child(Auth)
	Profile.set_script(profile_script)
	add_child(Profile)
	Store.set_script(store_script)
	add_child(Store)
	Chat.set_script(chat_script)
	add_child(Chat)
	print("BKMR ready end timestamp: " + str(BKMRUtils.get_timestamp()))
	Auth.check_version(config)
	
func free_request(weak_ref: WeakRef, object: Node) -> void:
	if (weak_ref.get_ref()):
		object.queue_free()

func prepare_http_request() -> Dictionary:
	var request: HTTPRequest = HTTPRequest.new()
	@warning_ignore("shadowed_global_identifier")
	var weakref: WeakRef = weakref(request)
	if OS.get_name() != "Web":
		request.set_use_threads(true)
	request.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().get_root().call_deferred("add_child", request)
	var return_dict: Dictionary = {
		"request": request, 
		"weakref": weakref
	}
	return return_dict

func send_get_request(http_node: HTTPRequest, request_url: String) -> void:
	var headers: Array = [
		"x-api-key: " + BKMREngine.config.apiKey, 
		"x-api-id: " + BKMREngine.config.apiId,
		"x-bkmr-plugin-version: " + BKMREngine.version,
		"x-bkmr-godot-version: " + godot_version,
		
	]
	headers = add_jwt_token_headers(headers)
	if !http_node.is_inside_tree():
		await get_tree().create_timer(0.01).timeout
	BKMRLogger.debug("Method: GET")
	BKMRLogger.debug("request_url: " + str(request_url))
	BKMRLogger.debug("headers: " + str(headers))
	http_node.request(request_url, headers) 
	
func send_post_request(http_node: HTTPRequest, request_url: String, payload: Dictionary) -> void:
	var headers: Array = [
		"content-Type: application/json",
		"x-api-key: " + BKMREngine.config.apiKey,
		"x-api-id: " + BKMREngine.config.apiId,
	]
	headers = add_jwt_token_headers(headers)
	var _use_ssl: bool = true
	if !http_node.is_inside_tree():
		await get_tree().create_timer(0.01).timeout
		
	var query: String = JSON.stringify(payload)
	BKMRLogger.debug("Method: POST")
	BKMRLogger.debug("request_url: " + str(request_url))
	BKMRLogger.debug("headers: " + str(headers))
	BKMRLogger.debug("query: " + str(query))
	http_node.request(request_url, headers, HTTPClient.METHOD_POST, query)
	
func add_jwt_token_headers(headers: Array) -> Array:
	if Auth.bkmr_access_token != null:
		headers.append("Authorization: Bearer " + Auth.bkmr_access_token)
		print(Auth.bkmr_access_token, "meron baaaaaaaaaaaaaaaaaaaaaaaaaa")
	return headers
	
func check_string_in_url(test_string: String, url: String) -> bool:
	return test_string in url
	
func build_result(body: Dictionary) -> Dictionary:
	var error: String
	var success: String
	if "error" in body:
		error = body.error
	if "success" in body:
		success = body.success
	return {
		"success": success,
		"error": error
	}

func check_auth_ready() -> void:
	if !Auth:
		await get_tree().create_timer(0.01).timeout
