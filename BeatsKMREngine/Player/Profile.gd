extends Node

const BKMRUtils:Script = preload("res://BeatsKMREngine/utils/BKMRUtils.gd")
const BKMRLogger:Script = preload("res://BeatsKMREngine/utils/BKMRLogger.gd")

var UploadProfilePicture:HTTPRequest = null
var ProfilePictureUpload:WeakRef = null

var UpdateStatPointsSaved:HTTPRequest = null
var StatPointsSavedUpdate:WeakRef = null

var FetchImages = null
var ImagesFetch = null
var host:String = "http://localhost:8081"
var profilePicURLs:Array

signal profile_pic_upload_complete
signal stat_update_complete(data)

# Called when the node enters the scene tree for the first time.
func upload_profile_pic(image_buffer) -> Node:
	var prepared_http_req:Dictionary = BKMREngine.prepare_http_request()
	UploadProfilePicture = prepared_http_req.request
	ProfilePictureUpload = prepared_http_req.weakref
	UploadProfilePicture.request_completed.connect(_on_ProfilePictureUpload_request_completed)
	var payload:Dictionary = {"bufferData": image_buffer}
	var request_url:String = host + "/api/upload/pic/profile/"
	BKMREngine.send_post_request(UploadProfilePicture, request_url, payload)
	return self
	
	
@warning_ignore("unused_parameter")
func _on_ProfilePictureUpload_request_completed(result, response_code, headers, body) -> void:
	var status_check:bool = BKMRUtils.check_http_response(response_code, headers, body)
	BKMREngine.free_request(ProfilePictureUpload, UploadProfilePicture)
	
	var json_body:Dictionary = JSON.parse_string(body.get_string_from_utf8())
	var _bkmr_result:Dictionary
	
	if status_check:
		if json_body.success:
			_bkmr_result = {"success": "Profile picture upload succesful"}
			BKMRLogger.info("BKMREngine profile picture upload successful")
			profilePicURLs = json_body.profilePics
			PLAYER.profile_pics = json_body.profilePics
			profile_pic_upload_complete.emit()
		else:
			print(json_body)
	
	
func update_statpoints_saved(stat_points_saved) -> Node:
	var prepared_http_req:Dictionary = BKMREngine.prepare_http_request()
	UpdateStatPointsSaved = prepared_http_req.request
	StatPointsSavedUpdate = prepared_http_req.weakref
	UpdateStatPointsSaved.request_completed.connect(_on_UpdateStatPointsSaved_request_completed)
	var payload:Dictionary = stat_points_saved
	var request_url:String = host + "/api/update/statpoints"
	BKMREngine.send_post_request(UpdateStatPointsSaved, request_url, payload)
	return self
	
func _on_UpdateStatPointsSaved_request_completed(_result, response_code, headers, body) -> void:
	var status_check:bool = BKMRUtils.check_http_response(response_code, headers, body)
	BKMREngine.free_request(StatPointsSavedUpdate, UpdateStatPointsSaved)
	
	var json_body:Dictionary = JSON.parse_string(body.get_string_from_utf8())
	if status_check:
		if json_body.success:
			BKMRLogger.info("BKMREngine stat update successful")
			stat_update_complete.emit(json_body)
		else:
			print(json_body)
	
