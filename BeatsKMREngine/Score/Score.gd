extends Node

# Preloaded scripts for utility functions and logging.
const BKMRUtils: Script = preload("res://BeatsKMREngine/utils/BKMRUtils.gd")
const BKMRLogger: Script = preload("res://BeatsKMREngine/utils/BKMRLogger.gd")

signal get_classic_highscore_complete(scores: Array)
signal get_classic_highscore_single(scores: Array)
signal save_classic_highscore_complete()

# Host URL for server communication.
var host: String = BKMREngine.host

var GetClassicScore: HTTPRequest
var wrGetClassicScore: WeakRef

var GetClassicScoreSingle: HTTPRequest
var wrGetClassicScoreSingle: WeakRef

var SaveClassicHighScore: HTTPRequest
var wrSaveClassicHighScore: WeakRef

var classic_scores: Array


func save_classic_high_score(classic_score_stats: Dictionary) -> void:
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	SaveClassicHighScore = prepared_http_req.request
	wrSaveClassicHighScore  = prepared_http_req.weakref
	
	var _connect: int = SaveClassicHighScore.request_completed.connect(_on_SaveClassicHighScore_request_completed)
	
	var request_url: String = host + "/api/save/score/classic"
	var payload: Dictionary = classic_score_stats
	
	BKMREngine.send_post_request(SaveClassicHighScore, request_url, payload)


func _on_SaveClassicHighScore_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Free the request resources.
	BKMREngine.free_request(wrSaveClassicHighScore, SaveClassicHighScore)
	
	# Check if the server update was successful.
	if status_check:
		save_classic_highscore_complete.emit()
	else:
		pass

# Send get highscore request
func get_classic_high_score_single(peer_id: int) -> void:
	# Prepare the HTTP request.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	GetClassicScoreSingle = prepared_http_req.request
	wrGetClassicScoreSingle = prepared_http_req.weakref
	
	# Connect the request completion signal to the callback function.
	var _get_classic_score: int = GetClassicScoreSingle.request_completed.connect(_on_GetClassicHighScoreSingle_request_completed)
	
	# Create the request URL with the peer_id as a parameter.
	var request_url: String = host + "/api/open/highscore/classic/single?peerId=" + str(peer_id)
	
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


func get_classic_high_score_all() -> void:
	# Prepare the HTTP request.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	GetClassicScore = prepared_http_req.request
	wrGetClassicScore = prepared_http_req.weakref
	
	# Connect the request completion signal to the callback function.
	var _get_classic_score: int = GetClassicScore.request_completed.connect(_on_GetClassicHighScore_request_completed)
	
	var request_url: String = host + "/api/open/highscore/classic/all"
	
	# Send the POST request to update stat points on the server.
	BKMREngine.send_get_request(GetClassicScore, request_url)
	
# Callback function triggered when the server responds to the get high score request.
func _on_GetClassicHighScore_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Free the request resources.
	BKMREngine.free_request(wrGetClassicScore, GetClassicScore)

	# Check if the server update was successful.
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			for score: Dictionary in json_body:
				# Parse scoreStats and replace the original value
				var string_score_stats: String = score["scoreStats"]
				var parsed_score_stats: Dictionary = JSON.parse_string(string_score_stats)
				score["scoreStats"] = parsed_score_stats
			
			# Assign the modified array to the global/class variable (classic_scores)
			classic_scores = json_body
			
			# Emit the signal to indicate the completion of the get_mutual request.
			get_classic_highscore_complete.emit(json_body)
		else:
			get_classic_highscore_complete.emit([])
			
	else:
		get_classic_highscore_complete.emit([])
