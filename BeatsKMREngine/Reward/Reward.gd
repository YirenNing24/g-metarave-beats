extends Node

# Preloaded scripts for utility functions and logging.
const BKMRUtils: Script = preload("res://BeatsKMREngine/utils/BKMRUtils.gd")
const BKMRLogger: Script = preload("res://BeatsKMREngine/utils/BKMRLogger.gd")


var GetPersonalMissionList: HTTPRequest
var wrGetPersonalMissionList: WeakRef
signal get_personal_mission_list_completed(personal_mission_list: Array[Dictionary])

var ClaimPersonalMissionReward: HTTPRequest
var wrClaimPersonalMissionReward: WeakRef
signal claim_personal_mission_reward_completed(message: Dictionary)


func claim_personal_mission_reward(mission_name: String) -> void:
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	ClaimPersonalMissionReward = prepared_http_req.request
	wrClaimPersonalMissionReward = prepared_http_req.weakref

	var _connect: int = ClaimPersonalMissionReward.request_completed.connect(_on_ClaimPersonalMissionReward_request_completed)
	BKMRLogger.info("Calling BKMREngine to get card inventory data")

	var request_url: String = BKMREngine.host + "/api/reward/claim/personal-mission"
	var payload: Dictionary = { "name": mission_name }
	BKMREngine.send_post_request(ClaimPersonalMissionReward, request_url, payload)


func _on_ClaimPersonalMissionReward_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body.has("error"):
			BKMRLogger.info(json_body.error)
			claim_personal_mission_reward_completed.emit(json_body.error)
		else:
			claim_personal_mission_reward_completed.emit(json_body)
	else:
		claim_personal_mission_reward_completed.emit({"Error:": "Unknown Server Error" })


func get_personal_mission_list() -> void:
	
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	GetPersonalMissionList = prepared_http_req.request
	wrGetPersonalMissionList = prepared_http_req.weakref

	var _connect: int = GetPersonalMissionList.request_completed.connect(_on_GetPersonalMissionList_request_completed)
	BKMRLogger.info("Calling BKMREngine to get card inventory data")

	var request_url: String = BKMREngine.host + "/api/reward/personal-missions"
	BKMREngine.send_get_request(GetPersonalMissionList, request_url)


func _on_GetPersonalMissionList_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		
		
		print("ANU RESULT: ", json_body)
		if json_body != null:
			if json_body.has("error"):
				get_personal_mission_list_completed.emit(json_body)
			else:
				get_personal_mission_list_completed.emit(json_body)
		else:
			get_personal_mission_list_completed.emit({"Error:": "Unknown Server Error" })
	else:
		get_personal_mission_list_completed.emit({"Error:": "Unknown Server Error" })
