extends Node

const BKMRUtils:Script = preload("res://BeatsKMREngine/utils/BKMRUtils.gd")
const BKMRLogger:Script = preload("res://BeatsKMREngine/utils/BKMRLogger.gd")

signal view_profile_complete
signal follow_complete
signal unfollow_complete
signal get_mutual_complete

var host: String = BKMREngine.host

var ViewProfile: HTTPRequest
var wrViewProfile: WeakRef

var Follow: HTTPRequest
var wrFollow: WeakRef

var Unfollow: HTTPRequest
var wrUnfollow: WeakRef

var Mutual: HTTPRequest
var wrMutual: WeakRef

var player_profile: Dictionary 
var follow_response: Dictionary
var mutual_followers: Array

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
		
func follow(follower: String, to_follow: String) -> Node:
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	Follow = prepared_http_req.request
	wrFollow = prepared_http_req.weakref
	var _follow: int = Follow.request_completed.connect(_onFollow_request_completed)
	var payload: Dictionary = { "follower": follower, "toFollow": to_follow }
	var request_url: String = host + "/api/social/follow"
	BKMREngine.send_post_request(Follow, request_url, payload)
	return self
	
func _onFollow_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	if is_instance_valid(Follow):
		BKMREngine.free_request(wrFollow, Follow)
	if status_check:
		var json_body: Dictionary = JSON.parse_string(body.get_string_from_utf8())
		follow_response = json_body
		follow_complete.emit()

func unfollow(follower: String, toUnfollow: String) -> Node:
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	Unfollow = prepared_http_req.request
	wrUnfollow = prepared_http_req.weakref
	var _follow: int = Unfollow.request_completed.connect(_onUnfollow_request_completed)
	var payload: Dictionary = { "follower": follower, "toUnfollow": toUnfollow }
	var request_url: String = host + "/api/social/unfollow"
	BKMREngine.send_post_request(Unfollow, request_url, payload)
	return self
	
func _onUnfollow_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	if is_instance_valid(Unfollow):
		BKMREngine.free_request(wrUnfollow, Unfollow)
	if status_check:
		var json_body: Dictionary = JSON.parse_string(body.get_string_from_utf8())
		follow_response = json_body
		unfollow_complete.emit()

func get_mutual() -> Node:
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	Mutual = prepared_http_req.request
	wrMutual  = prepared_http_req.weakref
	var _mutuals: int = Mutual.request_completed.connect(_onGetMutual_request_completed)
	BKMRLogger.info("Calling BKMREngine to get mutual followers data")
	var request_url: String = host + "/api/social/mutual"
	var _get_mutuals: Error = await BKMREngine.send_get_request(Mutual, request_url)
	return self
	
func _onGetMutual_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	if is_instance_valid(Mutual):
		BKMREngine.free_request(wrMutual, Mutual)
	if status_check:
		var json_body: Array = JSON.parse_string(body.get_string_from_utf8())
		mutual_followers = json_body
		get_mutual_complete.emit()
