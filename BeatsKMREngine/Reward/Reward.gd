extends Node

# Preloaded scripts for utility functions and logging.
const BKMRUtils: Script = preload("res://BeatsKMREngine/utils/BKMRUtils.gd")
const BKMRLogger: Script = preload("res://BeatsKMREngine/utils/BKMRLogger.gd")


# Host URL for server communication.
var host: String = BKMREngine.host

var GetAvailableCardReward: HTTPRequest
var wrGetAvailableCardReward: WeakRef
signal get_available_card_reward_completed

var ClaimCardOwnershipReward: HTTPRequest
var wrClaimCardOwnershipReward: WeakRef
signal claim_card_ownership_reward_completed(message: Dictionary)

func get_available_card_reward() -> void:
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	GetAvailableCardReward = prepared_http_req.request
	wrGetAvailableCardReward = prepared_http_req.weakref

	var _connect: int = GetAvailableCardReward.request_completed.connect(_on_GetAvailableCardReward_request_completed)
	BKMRLogger.info("Calling BKMREngine to get card inventory data")

	var request_url: String = host + "/api/reward/card"
	BKMREngine.send_get_request(GetAvailableCardReward, request_url)

func _on_GetAvailableCardReward_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	if is_instance_valid(GetAvailableCardReward):
		BKMREngine.free_request(wrGetAvailableCardReward, GetAvailableCardReward)
	
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body.has("error"):
			BKMRLogger.info(json_body.error)
			get_available_card_reward_completed.emit(json_body.error)
		else:
			print("PEPE MATABA: ", json_body)
			get_available_card_reward_completed.emit(json_body)
	else:
		get_available_card_reward_completed.emit({"Error:": "Unknown Server Error" })

func claim_card_ownership_reward(card_name: String) -> void:
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	ClaimCardOwnershipReward = prepared_http_req.request
	wrClaimCardOwnershipReward = prepared_http_req.weakref

	var _connect: int = ClaimCardOwnershipReward.request_completed.connect(_on_ClaimCardOwnerShipReward_request_completed)
	BKMRLogger.info("Calling BKMREngine to get card inventory data")

	var request_url: String = host + "/api/reward/claim/ownership"
	var payload: Dictionary = { "name": card_name }
	BKMREngine.send_post_request(ClaimCardOwnershipReward, request_url, payload)

func _on_ClaimCardOwnerShipReward_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	if is_instance_valid(ClaimCardOwnershipReward):
		BKMREngine.free_request(wrClaimCardOwnershipReward, ClaimCardOwnershipReward)
	
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body.has("error"):
			BKMRLogger.info(json_body.error)
			claim_card_ownership_reward_completed.emit(json_body.error)
		else:
			claim_card_ownership_reward_completed.emit(json_body)
	else:
		claim_card_ownership_reward_completed.emit({"Error:": "Unknown Server Error" })
