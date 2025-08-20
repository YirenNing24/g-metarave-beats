extends Node

# Preloaded scripts for utility functions and logging.
const BKMRUtils: Script = preload("res://BeatsKMREngine/utils/BKMRUtils.gd")
const BKMRLogger: Script = preload("res://BeatsKMREngine/utils/BKMRLogger.gd")

var GetClassicScore: HTTPRequest
var wrGetClassicScore: WeakRef
signal get_classic_highscore_single(scores: Array)

var GetClassicScoreSingle: HTTPRequest
var wrGetClassicScoreSingle: WeakRef

var SaveClassicHighScore: HTTPRequest
var wrSaveClassicHighScore: WeakRef
signal save_classic_highscore_complete()

var GetPlayerHighscorePerSong: HTTPRequest
var wrGetPlayerHighscorePerSong: WeakRef
signal get_player_highscore_per_song_complete(score: Array[Dictionary])

var GetRetrieveHistory: HTTPRequest
var wrGetRetrieveHistory: WeakRef
signal get_retrieve_history_complete(score: Array[Dictionary])

var classic_scores: Array
var classic_game_rewards: Dictionary

# Send get highscore request
func get_classic_high_score_single(peer_id: int) -> void:
	# Prepare the HTTP request.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	GetPlayerHighscorePerSong = prepared_http_req.request
	wrGetClassicScoreSingle = prepared_http_req.weakref
	
	# Connect the request completion signal to the callback function.
	var _get_classic_score: int = GetClassicScoreSingle.request_completed.connect(_on_GetClassicHighScoreSingle_request_completed)
	
	# Create the request URL with the peer_id as a parameter.
	var request_url: String = BKMREngine.host + "/api/open/highscore/classic/single?peerId=" + str(peer_id)
	
	# Send the GET request to update stat points on the server.
	BKMREngine.send_get_request(GetClassicScoreSingle, request_url)
	
	
func _on_GetClassicHighScoreSingle_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Free the request resources.
	BKMREngine.free_request(wrGetClassicScoreSingle, GetClassicScoreSingle)

	# Check if the server update was successful.
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body.has("error"):
				get_classic_highscore_single.emit(json_body.error)
			else:
				get_classic_highscore_single.emit(json_body)
		else:
			get_classic_highscore_single.emit({"error": "Unknown body error"})
	else:
		get_classic_highscore_single.emit({"error": "Unknown body error"})
	
	
func get_player_highscore_per_song() -> void:
	# Prepare the HTTP request.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	GetPlayerHighscorePerSong = prepared_http_req.request
	wrGetPlayerHighscorePerSong = prepared_http_req.weakref
	
	# Connect the request completion signal to the callback function.
	var _get_classic_score: int = GetPlayerHighscorePerSong.request_completed.connect(_on_GetPlayerHighScorePerSong_request_completed)
	
	var request_url: String = BKMREngine.host + "/api/open/highscore/classic/per-song/player"
	
	# Send the POST request to update stat points on the server.
	BKMREngine.send_get_request(GetPlayerHighscorePerSong, request_url)
	
	
# Callback function triggered when the server responds to the get high score request.
func _on_GetPlayerHighScorePerSong_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Free the request resources.
	BKMREngine.free_request(wrGetPlayerHighscorePerSong, GetPlayerHighscorePerSong)
	
	# Check if the server update was successful.
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body.has("error"):
				get_player_highscore_per_song_complete.emit({ "error": "Unknown server error"})
			else:
				if json_body is Array:
					get_player_highscore_per_song_complete.emit(json_body)
				else:
					get_player_highscore_per_song_complete.emit([])
		else:
			get_player_highscore_per_song_complete.emit([])
			
	else:
		get_player_highscore_per_song_complete.emit([])
	
	
func save_classic_high_score(classic_score_stats: Dictionary) -> void:
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	SaveClassicHighScore = prepared_http_req.request
	wrSaveClassicHighScore  = prepared_http_req.weakref
	
	var _connect: int = SaveClassicHighScore.request_completed.connect(_on_SaveClassicHighScore_request_completed)
	 
	var request_url: String = BKMREngine.host + "/api/save/score/classic"
	var payload: Dictionary = classic_score_stats
	
	BKMREngine.send_post_request(SaveClassicHighScore, request_url, payload)
	
	
func _on_SaveClassicHighScore_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)

	# Check if the server update was successful.
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body is Dictionary:
				if json_body.has("error"):
					save_classic_highscore_complete.emit(json_body)
				else:
					save_classic_highscore_complete.emit(json_body)
					classic_game_rewards = json_body
			else:
				save_classic_highscore_complete.emit({"error": "Unknown server error"})
				
		else:
			save_classic_highscore_complete.emit({"error": "Unknown server error"})
	else:
		save_classic_highscore_complete.emit({"error": "Unknown server error"})
	
	
func retrieve_history(username: String) -> void:
	# Prepare the HTTP request.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	GetRetrieveHistory = prepared_http_req.request
	wrGetRetrieveHistory = prepared_http_req.weakref

	# Connect the request completion signal to the callback function.
	var _get_classic_score: int = GetRetrieveHistory.request_completed.connect(_on_GetRetrieveHistory_request_completed)

	# Format the correct URL with the username in the path
	var request_url: String = BKMREngine.host + "/api/open/history/retrieve/" + username

	# Send the GET request
	BKMREngine.send_get_request(GetRetrieveHistory, request_url)
	
	
func _on_GetRetrieveHistory_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Check if the server update was successful.
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body.has("error"):
				get_retrieve_history_complete.emit(json_body.error)
			else:
				get_retrieve_history_complete.emit(json_body)
		else:
			get_retrieve_history_complete.emit({"error": "Unknown body error"})
	else:
		get_retrieve_history_complete.emit({"error": "Unknown body error"})
	
