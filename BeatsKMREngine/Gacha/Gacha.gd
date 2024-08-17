extends Node

# Preloaded scripts for utility functions and logging.
const BKMRUtils: Script = preload("res://BeatsKMREngine/utils/BKMRUtils.gd")
const BKMRLogger: Script = preload("res://BeatsKMREngine/utils/BKMRLogger.gd")


signal open_card_pack_complete(message: Dictionary)

# Host URL for server communication.
var host: String = BKMREngine.host

var OpenCardPack: HTTPRequest
var wrOpenCardPack: WeakRef


func open_card_pack(classic_score_stats: Dictionary) -> void:
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	OpenCardPack = prepared_http_req.request
	wrOpenCardPack  = prepared_http_req.weakref
	
	var _connect: int = OpenCardPack.request_completed.connect(_on_OpenCardPack_request_completed)
	
	var request_url: String = host + "/api/gacha/open/card-pack"
	var payload: Dictionary = classic_score_stats
	
	BKMREngine.send_post_request(OpenCardPack, request_url, payload)


func _on_OpenCardPack_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Free the request resources.
	BKMREngine.free_request(wrOpenCardPack, OpenCardPack)
	
	# Check if the server update was successful.
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body.has("error"):
				open_card_pack_complete.emit({"error": json_body.error})
			else:
				open_card_pack_complete.emit(json_body)
		else:
			open_card_pack_complete.emit({"error": "Unknown server error"})
	else:
		open_card_pack_complete.emit({"error": "Unknown server error"})
