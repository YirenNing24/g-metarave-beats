extends Node

# Preloaded scripts for utility functions and logging.
const BKMRUtils: Script = preload("res://BeatsKMREngine/utils/BKMRUtils.gd")
const BKMRLogger: Script = preload("res://BeatsKMREngine/utils/BKMRLogger.gd")

signal get_classic_leaderboard_complete(scores: Array)

# BKMREngine.host URL for server communication.
# var BKMREngine.host: String = BKMREngine.BKMREngine.host

var GetClassicLeaderboard: HTTPRequest
var wrGetClassicLeaderboard: WeakRef


func get_classic_leaderboard(song_name: String, difficulty: String, period: String) -> void:
	# Prepare an HTTP request for fetching leaderboard data.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	GetClassicLeaderboard = prepared_http_req.request
	wrGetClassicLeaderboard = prepared_http_req.weakref

	# Connect the callback function to handle the completion of the leaderboard data request.
	var _connect: int = GetClassicLeaderboard.request_completed.connect(_on_GetClassicLeaderboard_request_completed)

	# Log the initiation of the request to retrieve leaderboard data.	
	BKMRLogger.info("Calling BKMREngine to get leaderboard data")
	
	# Construct the request URL for fetching leaderboard data.
	var request_url: String = BKMREngine.host + "/api/leaderboard/classic?difficulty=%s&songName=%s&period=%s" % [difficulty, song_name, period]


	# Send the GET request using the prepared URL.
	BKMREngine.send_get_request(GetClassicLeaderboard, request_url)


func _on_GetClassicLeaderboard_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Free the request resources.
	BKMREngine.free_request(wrGetClassicLeaderboard, GetClassicLeaderboard)

	# Check if the server update was successful.
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body.has("error"):
				get_classic_leaderboard_complete.emit({"error": json_body.error})
			else:
				get_classic_leaderboard_complete.emit(json_body)
		else:
			get_classic_leaderboard_complete.emit({"error": "Unknown server error"})
	else:
		get_classic_leaderboard_complete.emit({"error": "Unknown server error"})
