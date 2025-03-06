extends Node

# Preloaded scripts for utility functions and logging.
const BKMRUtils: Script = preload("res://BeatsKMREngine/utils/BKMRUtils.gd")
const BKMRLogger: Script = preload("res://BeatsKMREngine/utils/BKMRLogger.gd")

var GetEnergyDrink: HTTPRequest
var wrGetEnergyDrink: WeakRef
signal get_energy_drink_complete(energy_drinks: Array)

var UsePlayerEnergy: HTTPRequest
var wrUsePlayerEnergy: WeakRef
signal use_player_energy_complete(is_energy: bool)

var game_id: String


func get_energy_drink() -> void:
	# Prepare an HTTP request for fetching leaderboard data.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	GetEnergyDrink = prepared_http_req.request
	wrGetEnergyDrink = prepared_http_req.weakref

	# Connect the callback function to handle the completion of the leaderboard data request.
	var _connect: int = GetEnergyDrink.request_completed.connect(_on_GetEnergyDrink_request_completed)

	# Log the initiation of the request to retrieve leaderboard data.	
	BKMRLogger.info("Calling BKMREngine to get leaderboard data")
	
	# Construct the request URL for fetching leaderboard data.
	var request_url: String = BKMREngine.host + "/api/energy-drinks/get"

	# Send the GET request using the prepared URL.
	BKMREngine.send_get_request(GetEnergyDrink, request_url)
	
	
func _on_GetEnergyDrink_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Check if the server update was successful.
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body.has("error"):
				get_energy_drink_complete.emit({"error": json_body.error})
			else:
				get_energy_drink_complete.emit(json_body)
		else:
			get_energy_drink_complete.emit({"error": "Unknown server error"})
	else:
		get_energy_drink_complete.emit({"error": "Unknown server error"})


func use_player_energy() -> void:
	# Prepare an HTTP request for fetching leaderboard data.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	UsePlayerEnergy = prepared_http_req.request
	wrUsePlayerEnergy = prepared_http_req.weakref

	# Connect the callback function to handle the completion of the leaderboard data request.
	var _connect: int = UsePlayerEnergy.request_completed.connect(_on_UsePlayerEnergy_request_completed)

	# Log the initiation of the request to retrieve leaderboard data.	
	BKMRLogger.info("Calling BKMREngine to get leaderboard data")
	
	# Construct the request URL for fetching leaderboard data.
	var request_url: String = "https://api-fn.gmetarave.asia" + "/api/energy/use"

	# Send the GET request using the prepared URL.
	BKMREngine.send_post_request(UsePlayerEnergy, request_url, {})
	
	
func _on_UsePlayerEnergy_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Check if the server update was successful.
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body is Dictionary:
				if json_body.has("error"):
					use_player_energy_complete.emit({ "error": json_body.error })
				else:
					use_player_energy_complete.emit(json_body)
		else:
			use_player_energy_complete.emit({ "error": "Unknown server error" })
	else:
		use_player_energy_complete.emit({ "error": "Unknown server error" })
