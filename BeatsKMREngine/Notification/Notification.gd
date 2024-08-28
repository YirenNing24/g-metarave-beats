extends Node

# Preloaded scripts for utility functions and logging.
const BKMRUtils: Script = preload("res://BeatsKMREngine/utils/BKMRUtils.gd")

# Host URL for server communication.
var host: String = BKMREngine.host

var GetNotifications: HTTPRequest
var wrGetNotifications: WeakRef
signal get_notifications_complete(notifications: Array)


func get_notifications() -> void:
	# Prepare an HTTP request for fetching leaderboard data.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	GetNotifications = prepared_http_req.request
	wrGetNotifications = prepared_http_req.weakref

	# Connect the callback function to handle the completion of the leaderboard data request.
	var _connect: int = GetNotifications.request_completed.connect(_on_GetNotifications_request_completed)
	
	# Construct the request URL for fetching leaderboard data.
	var request_url: String = host + "/api/notification"

	# Send the GET request using the prepared URL.
	BKMREngine.send_get_request(GetNotifications, request_url)


func _on_GetNotifications_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Free the request resources.
	BKMREngine.free_request(wrGetNotifications, GetNotifications)

	# Check if the server update was successful.
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body.has("error"):
				get_notifications_complete.emit({"error": json_body.error})
			else:
				get_notifications_complete.emit(json_body)
		else:
			get_notifications_complete.emit({"error": "Unknown server error"})
	else:
		get_notifications_complete.emit({"error": "Unknown server error"})
