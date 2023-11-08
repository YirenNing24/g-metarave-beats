extends Node

const BKMRUtils:Script = preload("res://BeatsKMREngine/utils/BKMRUtils.gd")
const BKMRLogger:Script = preload("res://BeatsKMREngine/utils/BKMRLogger.gd")

signal view_profile_complete
signal follow_unfollow_complete

var host: String = BKMREngine.host

var ViewProfile: HTTPRequest
var wrViewProfile: WeakRef

var FollowUnfollow: HTTPRequest
var wrFollowUnfollow: WeakRef

var player_profile: Dictionary 
var follow_response: Dictionary

func view_profile(username: String) -> Node:
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	ViewProfile = prepared_http_req.request
	wrViewProfile = prepared_http_req.weakref
	var _view_profile: int = ViewProfile.request_completed.connect(_onViewProfile_request_comleted)
	BKMRLogger.info("Calling BKMREngine to get cards on sale data")
	var request_url: String = host + "/api/social/viewprofile/" + username
	var _get_store_cards: Error = await BKMREngine.send_get_request(ViewProfile, request_url)
	return self

func _onViewProfile_request_comleted(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	if is_instance_valid(ViewProfile):
		BKMREngine.free_request(wrViewProfile, ViewProfile)
	if status_check:
		var json_body: Dictionary = JSON.parse_string(body.get_string_from_utf8())
		player_profile = json_body
		view_profile_complete.emit()
		
func follow_unfollow(follower: String, to_follow: String) -> Node:
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	FollowUnfollow = prepared_http_req.request
	wrFollowUnfollow = prepared_http_req.weakref
	var _follow_unfollow: int = FollowUnfollow.request_completed.connect(_onFollowUnfollow_request_completed)
	var payload: Dictionary = { "follower": follower, "toFollow": to_follow }
	var request_url: String = host + "/api/update/statpoints"
	BKMREngine.send_post_request(FollowUnfollow, request_url, payload)
	return self
	
func _onFollowUnfollow_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	if is_instance_valid(ViewProfile):
		BKMREngine.free_request(wrFollowUnfollow, FollowUnfollow)
	if status_check:
		var json_body: Dictionary = JSON.parse_string(body.get_string_from_utf8())
		follow_response = json_body
		follow_unfollow_complete.emit()
