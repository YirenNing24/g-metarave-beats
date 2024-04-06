extends Node

# Preloaded scripts for utility functions and logging.
const BKMRUtils: Script = preload("res://BeatsKMREngine/utils/BKMRUtils.gd")
const BKMRLogger: Script = preload("res://BeatsKMREngine/utils/BKMRLogger.gd")

signal get_weekly_leaderboard_complete(scores: Array)
signal get_daily_leaderboard_complete(scores: Array)

# Host URL for server communication.
var host: String = BKMREngine.host

var GetWeeklyLeaderboard: HTTPRequest
var wrGetWeeklyLeaderboard: WeakRef

var GetDailyLeaderboard: HTTPRequest
var wrGetDailyLeaderboard: WeakRef

var weekly_leaderboard: Array
var daily_leaderboard: Array

func get_weekly_leaderboard(song_name: String, difficulty: String) -> Node:
	# Prepare an HTTP request for fetching private inbox data.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	GetWeeklyLeaderboard = prepared_http_req.request
	wrGetWeeklyLeaderboard = prepared_http_req.weakref

	# Connect the callback function to handle the completion of weekly leaderboard data request
	var _connect: int = GetWeeklyLeaderboard.request_completed.connect(_on_GetWeeklyLeaderboard_request_completed)

	# Log the initiation of the request to retrieve inbox messages.
	BKMRLogger.info("Calling BKMREngine to get card inventory data")

	# Construct the request URL for fetching private inbox data for the specified user.
	var request_url: String = host + "/api/leaderboard/weekly?songName=" + song_name + "&difficulty=" + difficulty

	# Send a GET request to retrieve the private inbox data.
	await BKMREngine.send_get_request(GetWeeklyLeaderboard, request_url)
	
	# Return the current node for method chaining.
	return self as Node

func _on_GetWeeklyLeaderboard_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Free the request resources.
	BKMREngine.free_request(wrGetWeeklyLeaderboard, GetWeeklyLeaderboard)

	# Check if the server update was successful.
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			weekly_leaderboard = json_body
			
			# Emit the signal to indicate the completion of the get_mutual request.
			get_weekly_leaderboard_complete.emit(json_body)
		else:
			pass

func get_daily_leaderboard(song_name: String, difficulty: String) -> Node:
	# Prepare an HTTP request for fetching private inbox data.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	GetDailyLeaderboard = prepared_http_req.request
	wrGetDailyLeaderboard = prepared_http_req.weakref

	# Connect the callback function to handle the completion of weekly leaderboard data request
	var _connect: int = GetDailyLeaderboard.request_completed.connect(_on_GetDailyLeaderboard_request_completed)

	# Log the initiation of the request to retrieve inbox messages.
	BKMRLogger.info("Calling BKMREngine to get card inventory data")

	# Construct the request URL for fetching private inbox data for the specified user.
	var request_url: String = host + "/api/leaderboard/daily?songName=" + song_name + "&difficulty=" + difficulty

	# Send a GET request to retrieve the private inbox data.
	await BKMREngine.send_get_request(GetDailyLeaderboard, request_url)
	
	# Return the current node for method chaining.
	return self as Node

func _on_GetDailyLeaderboard_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Free the request resources.
	BKMREngine.free_request(wrGetDailyLeaderboard, GetDailyLeaderboard)

	# Check if the server update was successful.
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			daily_leaderboard = json_body

			# Emit the signal to indicate the completion of the get_mutual request.
			get_daily_leaderboard_complete.emit(json_body)
		else:
			pass
