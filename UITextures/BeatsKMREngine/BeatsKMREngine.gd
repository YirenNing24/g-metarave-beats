extends Node

const version = "0.1"
var godot_version = Engine.get_version_info().string

const BKMRUtils = preload("res://utils/BKMRUtils.gd")
const BKMRHashing = preload("res://utils/BKMRHashing.gd")
const BKMRLogger = preload("res://utils/BKMRLogger.gd")


@onready var Auth = Node.new()

#@onready var Scores = Node.new()
#@onready var Players = Node.new()
#@onready var Items = Node.new()
#@onready var Multiplayer = Node.new()

@onready var config = {}

var auth_config = {
	"session_duration_seconds": 0,
	"saved_session_expiration_days": 30
}
 
var auth_script = load("res://Auth/Auth.gd")

func _ready():
	
	await ENV_VAR.completed
	config = {
		"apiKey": ENV_VAR.apiKey,
		"apiId": ENV_VAR.apiId,
		"gameVersion": ENV_VAR.gameVersion,
		"logLevel": ENV_VAR.logLevel,
	}
	
	# The following line would keep BKMREngine working even if the game tree is paused.
	#pause_mode = Node.PAUSE_MODE_PROCESS
	print("BKMR ready start timestamp: " + str(BKMRUtils.get_timestamp()))
	Auth.set_script(auth_script)
	add_child(Auth)
	#Multiplayer.set_script(multiplayer_script)
	#add_child(Multiplayer)
	print("BKMR ready end timestamp: " + str(BKMRUtils.get_timestamp()))
	Auth.check_version(config)
	
##################################################################
# Log levels:
# 0 - error (only log errors)
# 1 - info (log errors and the main actions taken by the BKMREngine plugin) - default setting
# 2 - debug (detailed logs, including the above and much more, to be used when investigating a problem). This shouldn't be the default setting in production.
##################################################################

func configure_auth(json_auth_config):
	auth_config = json_auth_config


func configure_auth_redirect_to_scene(scene):
	auth_config.open_scene_on_close = scene


func configure_auth_session_duration(duration):
	auth_config.session_duration = duration


func free_request(weak_ref, object):
	if (weak_ref.get_ref()):
		object.queue_free()


func prepare_http_request() -> Dictionary:
	var request = HTTPRequest.new()
	@warning_ignore("shadowed_global_identifier")
	var weakref = weakref(request)
	
	if OS.get_name() != "Web":
		request.set_use_threads(true)
	request.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().get_root().call_deferred("add_child", request)
	var return_dict = {
		"request": request, 
		"weakref": weakref
	}
	return return_dict


func send_get_request(http_node: HTTPRequest, request_url: String):
	var headers = [
		"x-api-key: " + BKMREngine.config.apiKey, 
		"x-bkmr-game-id: " + BKMREngine.apiId,
		"x-bkmr-plugin-version: " + BKMREngine.version,
		"x-bkmr-godot-version: " + godot_version 
	]
	headers = add_jwt_token_headers(headers)
	print("GET headers: " + str(headers))
	if !http_node.is_inside_tree():
		await get_tree().create_timer(0.01).timeout
	BKMRLogger.debug("Method: GET")
	BKMRLogger.debug("request_url: " + str(request_url))
	BKMRLogger.debug("headers: " + str(headers))
	http_node.request(request_url, headers) 


func send_post_request(http_node, request_url, payload):
	var headers = ["Content-Type: application/json"]
	print("POST headers: " + str(headers))
	# TODO: This should in fact be the case for all POST requests, make the following code more generic
	#var post_request_paths: Array[String] = ["post_new_score", "push_player_data"]
	var paths_with_values_to_hash: Dictionary = {
		"save_score": ["player_name", "score"],
		"push_player_data": ["player_name", "player_data"]
	}
	for path in paths_with_values_to_hash:
		var values_to_hash = []
		if check_string_in_url(path, request_url):
			BKMRLogger.debug("Computing hash for " + str(path))
			var fields_to_hash = paths_with_values_to_hash[path]
			for field in fields_to_hash:
				var value = payload[field]
				# if the data is a dictionary (e.g. player data, stringify it before hashing)
				if typeof(payload[field]) == TYPE_DICTIONARY:
					value = JSON.stringify(payload[field])
				values_to_hash = values_to_hash + [value]
			var timestamp = BKMRUtils.get_timestamp()
			values_to_hash = values_to_hash + [timestamp]
			BKMRLogger.debug(str(path) + " to_be_hashed: " + str(values_to_hash))
			var hashed = BKMRHashing.hash_values(values_to_hash)
			BKMRLogger.debug("hash value: " + str(hashed))
			headers.append("x-sw-act-tmst: " + str(timestamp))
			headers.append("x-sw-act-dig: " + hashed)
			break
	@warning_ignore("unused_variable")
	var use_ssl = true
	if !http_node.is_inside_tree():
		await get_tree().create_timer(0.01).timeout
	var query = JSON.stringify(payload)
	BKMRLogger.debug("Method: POST")
	BKMRLogger.debug("request_url: " + str(request_url))
	BKMRLogger.debug("headers: " + str(headers))
	BKMRLogger.debug("query: " + str(query))
	http_node.request(request_url, headers, HTTPClient.METHOD_POST, query)


func add_jwt_token_headers(headers: Array) -> Array:
	if Auth.bkmr_id_token != null:
		headers.append("x-sw-id-token: " + Auth.bkmr_id_token)
	if Auth.bkmr_access_token != null:
		headers.append("x-sw-access-token: " + Auth.bkmr_access_token)
	return headers


func check_string_in_url(test_string: String, url: String) -> bool:
	return test_string in url


func build_result(body: Dictionary) -> Dictionary:
	var error = null
	var success = false
	if "error" in body:
		error = body.error
	if "success" in body:
		success = body.success
	return {
		"success": success,
		"error": error
	}


func check_auth_ready():
	if !Auth:
		await get_tree().create_timer(0.01).timeout

