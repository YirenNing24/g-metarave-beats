extends Node

# Preloaded scripts for utility functions and logging.
const BKMRUtils: Script = preload("res://BeatsKMREngine/utils/BKMRUtils.gd")
const BKMRLogger: Script = preload("res://BeatsKMREngine/utils/BKMRLogger.gd")

signal get_energy_drink_complete(energy_drinks: Array)

# Host URL for server communication.
# var host: String = BKMREngine.host

var GetEnergyDrink: HTTPRequest
var wrGetEnergyDrink: WeakRef


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
