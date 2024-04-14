extends Node

# Plugin version
const version: String = "0.1"

# Godot engine version
var godot_version: String = Engine.get_version_info().string

# Configuration variables
#var host_ip: String = "localhost"
var host_ip: String = "api.gmetarave.art"
var port: String = ":8085"
#var host: String = "http://" + host_ip

var google_server_client_id: String = "484949065971-ujoksdio9417hnvd5goaclrvlnsv6704.apps.googleusercontent.com"
var host: String = "http://" + "localhost" + port

var session: bool = false

var time_server: String
var ping: int

# Preloaded utility scripts
const BKMRUtils: Script = preload("res://BeatsKMREngine/utils/BKMRUtils.gd")
const BKMRHashing: Script = preload("res://BeatsKMREngine/utils/BKMRHashing.gd")
const BKMRLogger: Script = preload("res://BeatsKMREngine/utils/BKMRLogger.gd")

# Child nodes representing different modules
@onready var Auth: Node = Node.new()
@onready var Websocket: Node = Node.new()
@onready var Inventory: Node = Node.new()
@onready var Profile: Node = Node.new()
@onready var Store: Node = Node.new()
@onready var Social: Node = Node.new()
@onready var Score: Node = Node.new()
@onready var Leaderboard: Node = Node.new()

# Configuration dictionaries
@onready var config: Dictionary = {}
var auth_config: Dictionary = {
	"session_duration_seconds": 0,
	"saved_session_expiration_days": 30
}

# Loaded scripts for various modules
var auth_script: Script = load("res://BeatsKMREngine/Auth/Auth.gd")
var websocket_script: Script = load("res://BeatsKMREngine/Websocket/Websocket.gd")
var inventory_script: Script = load("res://BeatsKMREngine/Inventory/Inventory.gd")
var profile_script: Script = load("res://BeatsKMREngine/Profile/Profile.gd")
var social_script: Script = load("res://BeatsKMREngine/Social/Social.gd")
var store_script: Script = load("res://BeatsKMREngine/Store/Store.gd")
var score_script: Script = load("res://BeatsKMREngine/Score/Score.gd")
var leaderboard_script: Script = load("res://BeatsKMREngine/Leaderboard/Leaderboard.gd")

# Called when the node is added to the scene tree
func _ready() -> void:
	# Wait for environment variable completion
	await ENV_VAR.completed
	# Set configuration based on environment variables
	config = {
		"apiKey": ENV_VAR.apiKey,
		"apiId": ENV_VAR.apiId,
		"gameVersion": ENV_VAR.gameVersion,
		"logLevel": ENV_VAR.logLevel,
	}
	# Print start timestamp for debugging purposes
	print("BKMR ready start timestamp: " + str(BKMRUtils.get_timestamp()))
	initialize_script()
	add_child_nodes()
	get_server_time()
	
func initialize_script() -> void:
	# Initialize script
	Auth.set_script(auth_script)
	Websocket.set_script(websocket_script)
	Inventory.set_script(inventory_script)
	Profile.set_script(profile_script)
	Store.set_script(store_script)
	Social.set_script(social_script)
	Score.set_script(score_script)
	Leaderboard.set_script(leaderboard_script)

func add_child_nodes() -> void:
	#Add child nodes for different modules
	add_child(Auth)
	add_child(Websocket)
	add_child(Inventory)
	add_child(Profile)
	add_child(Store)
	add_child(Social)
	add_child(Score)
	add_child(Leaderboard)
	
	# Print end timestamp for debugging purposes
	print("BKMR ready end timestamp: " + str(BKMRUtils.get_timestamp()))
	
#func _physics_process(_delta: float) -> void:

func get_server_time() -> void:
	var _connect: int = get_tree().create_timer(5).timeout.connect(get_server_time)
	if session == false:
		return
	Websocket.get_server_time()

	#time_server = server_time.serverTime
	#ping = latency
	
# Frees an HTTP request object using a WeakRef.
# 
# This function checks if the WeakRef is still valid before freeing the associated HTTP request object.
# It helps manage the memory by ensuring that the object is only freed if it hasn't been already.
#
# Parameters:
# - `weak_ref`: The WeakRef associated with the HTTP request object.
# - `object`: The Node (HTTP request object) to be freed.
#
# Example usage:
# ```gdscript
# free_request(wrGetCards, GetCards)
# ```
func free_request(weak_ref: Variant, object: HTTPRequest) -> void:
	if (weak_ref.get_ref()):
		object.queue_free()

# Prepares an HTTP request and returns a dictionary containing the request object and its WeakRef.
# 
# This function creates an HTTPRequest object, sets its properties, and adds it as a child to the scene.
# It returns a dictionary with the HTTP request object and a WeakRef associated with it.
#
# Returns:
# - A dictionary with the keys:
#   - "request": The HTTPRequest object.
#   - "weakref": The WeakRef associated with the HTTPRequest object.
#
# Example usage:
# ```gdscript
# var prepared_http_req: Dictionary = prepare_http_request()
# var http_request: HTTPRequest = prepared_http_req.request
# var weak_ref: WeakRef = prepared_http_req.weakref
# ```
func prepare_http_request() -> Dictionary:
	var request: HTTPRequest = HTTPRequest.new()
	var weak_ref: WeakRef = weakref(request)
	if OS.get_name() != "Web":
		request.set_use_threads(true)
	request.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().get_root().call_deferred("add_child", request)
	var return_dict: Dictionary = {
		"request": request, 
		"weakref": weak_ref
	}
	return return_dict

# Sends a GET request using the provided HTTPRequest object to the specified URL.
func send_get_request(http_node: HTTPRequest, request_url: String) -> void:
	var headers: Array = [
		"x-api-key: " + BKMREngine.config.apiKey, 
		"x-api-id: " + BKMREngine.config.apiId,
		"x-bkmr-plugin-version: " + BKMREngine.version,
		"x-bkmr-godot-version: " + godot_version,
	]
	headers = add_jwt_token_headers(headers)
	if !http_node.is_inside_tree():
		await get_tree().create_timer(0.09).timeout

	BKMRLogger.debug("Method: GET")
	BKMRLogger.debug("request_url: " + str(request_url))
	BKMRLogger.debug("headers: " + str(headers))
	var _get_request_send: Error = http_node.request(request_url, headers, HTTPClient.METHOD_GET) 
	
#localhost:8081/api/social/mutual/nashar2

# Sends a POST request using the provided HTTPRequest object to the specified URL with the given payload.
func send_post_request(http_node: HTTPRequest, request_url: String, payload: Dictionary) -> void:
	var headers: Array = [
		"content-Type: application/json",
		"x-api-key: " + BKMREngine.config.apiKey,
		"x-api-id: " + BKMREngine.config.apiId,
		"x-bkmr-plugin-version: " + BKMREngine.version,
		"x-bkmr-godot-version: " + godot_version,
	]
	headers = add_jwt_token_headers(headers)
	if !http_node.is_inside_tree():
		await get_tree().create_timer(0.05).timeout
		
	var query: String = JSON.stringify(payload)
	BKMRLogger.debug("Method: POST")
	BKMRLogger.debug("request_url: " + str(request_url))
	BKMRLogger.debug("headers: " + str(headers))
	BKMRLogger.debug("query: " + str(query))
	var _request_post_send: Error = http_node.request(request_url, headers, HTTPClient.METHOD_POST, query)

func send_login_request(http_node: HTTPRequest, request_url: String, payload: Dictionary) -> void:
	var headers: Array = [
		"content-Type: application/json",
		"x-api-key: " + BKMREngine.config.apiKey,
		"x-api-id: " + BKMREngine.config.apiId,
		"x-bkmr-plugin-version: " + BKMREngine.version,
		"x-bkmr-godot-version: " + godot_version,
	]
	headers = add_jwt_refresh_token_headers(headers)
	if !http_node.is_inside_tree():
		await get_tree().create_timer(0.05).timeout
		
	var query: String = JSON.stringify(payload)
	BKMRLogger.debug("Method: POST")
	BKMRLogger.debug("request_url: " + str(request_url))
	BKMRLogger.debug("headers: " + str(headers))
	BKMRLogger.debug("query: " + str(query))
	var _request_post_send: Error = http_node.request(request_url, headers, HTTPClient.METHOD_POST, query)

# Adds JWT token headers to the provided array of headers.
func add_jwt_token_headers(headers: Array = []) -> Array:
	if Auth.access_token != null:
		headers.append("Authorization: Bearer " + Auth.access_token)
	return headers as Array
	
# Adds JWT token headers for LOGIN and AUTO_LOGIN.
func add_jwt_refresh_token_headers(headers: Array = []) -> Array:
	if Auth.refresh_token != null:
		headers.append("Authorization: Bearer " + Auth.refresh_token)
	return headers as Array

# Checks if a specified string is present in the given URL.
#
# This function takes a test string and a URL as parameters and returns a boolean value indicating 
# whether the test string is present in the URL or not. It uses the 'in' operator to perform the
# substring check.
#
# Parameters:
# - test_string: The string to be checked for presence in the URL.
# - url: The URL in which the presence of the test string is checked.
#
# Returns:
# - A boolean value indicating whether the test string is present in the URL (true) or not (false).
#
# Example usage:
# ```gdscript
# var is_present: bool = check_string_in_url("example", "https://www.example.com")
# ```
func check_string_in_url(test_string: String, url: String) -> bool:
	return test_string in url



# Builds a result dictionary based on the response body.
#
# This function takes a response body dictionary as input and constructs a result dictionary
# with 'success' and 'error' fields. If the response body contains an 'error' field, it is assigned
# to the 'error' field in the result dictionary. Similarly, if the response body contains a 'success'
# field, it is assigned to the 'success' field in the result dictionary.
#
# Parameters:
# - body: The dictionary representing the response body.
#
# Returns:
# - A dictionary with 'success' and 'error' fields based on the response body.
#
# Example usage:
# ```gdscript
# var response_body: Dictionary = { "success": "Operation successful" }
# var result: Dictionary = build_result(response_body)
# ```
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

# Checks if the authentication module is ready.
#
# This function verifies whether the authentication module (Auth) has been initialized and is ready for use.
# If the authentication module is not ready, it waits for a small duration before proceeding.
#
# Returns:
# - This function does not return a value; it operates by checking and potentially waiting for the authentication module to be ready.
#
# Example usage:
# ```gdscript
# check_auth_ready()
# ```
func check_auth_ready() -> void:
	if !Auth:
		await get_tree().create_timer(0.01).timeout
