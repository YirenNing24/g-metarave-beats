extends Node

# Preloaded scripts for utility functions and logging.
const BKMRUtils: Script = preload("res://BeatsKMREngine/utils/BKMRUtils.gd")
const BKMRLogger: Script = preload("res://BeatsKMREngine/utils/BKMRLogger.gd")

# HTTPRequest object for profile picture upload.
var UploadProfilePicture: HTTPRequest = null
var wrUploadProfilePicture: WeakRef = null
signal profile_pic_upload_complete(message: Dictionary)

# HTTPRequest object for getting profile picture.
var GetProfilePicture: HTTPRequest = null
var wrGetProfilePicture: WeakRef = null
signal get_profile_pic_complete(profile_pic: Array)
var profile_pics: Array = []

var GetPlayerProfilePicture: HTTPRequest = null
var wrGetPlayerProfilePicture: WeakRef = null
signal get_player_profile_pic_complete(profile_pic: Array)

var UpdateMyNote: HTTPRequest = null
var wrUpdateMyNote: WeakRef = null
signal update_my_note_complete(message: Dictionary)

var GetMyNote: HTTPRequest = null
var wrGetMyNote: WeakRef = null
signal get_my_note_complete(my_note: Dictionary)

var LikeProfilePicture: HTTPRequest = null
var wrLikeProfilePicture: WeakRef = null
signal like_profile_pic_complete(message: Dictionary)

var UnlikeProfilePicture: HTTPRequest = null
var wrUnlikeProfilePicture: WeakRef = null
signal unlike_profile_pic_complete(message: Dictionary)

var ChangeProfilePicture: HTTPRequest = null
var wrChangeProfilePicture: WeakRef = null
signal change_profile_pic_complete(message: Dictionary)

# HTTPRequest object for updating saved stat points.
var UpdateStatPointsSaved: HTTPRequest = null
var wrUpdateStatPointsSaved: WeakRef = null
signal stat_update_complete(data: String)

# HTTPRequest object for updating saved preferences.
var SavePreference: HTTPRequest = null
var wrSavePreference: WeakRef = null
signal preference_save_complete(data: Dictionary)

var GetPreference: HTTPRequest = null
var wrGetPreference: WeakRef = null
signal preference_get_complete(data: Dictionary)

var GetCardCount: HTTPRequest = null
var wrGetCardCount: WeakRef = null
signal card_count_get_complete(data: Dictionary)

var GetCardCollection: HTTPRequest = null
var wrGetCardCollection: WeakRef = null
signal card_collection_get_complete(data: Dictionary)

var GetProfilePics: HTTPRequest = null
var wrGetProfilePics: WeakRef = null
signal get_profile_pics_complete(pics: Array)

# Host URL for server communication.
var host: String = BKMREngine.host

# Array to store profile picture URLs.
var profilePicURLs: Array

#region for Statpoints
# Function to update saved stat points by making an API request to the server.
func update_statpoints_saved(stat_points_saved: Dictionary) -> Node:
	# Prepare the HTTP request.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	UpdateStatPointsSaved = prepared_http_req.request
	wrUpdateStatPointsSaved = prepared_http_req.weakref
	
	# Connect the request completion signal to the callback function.
	var _update_stat_points: int = UpdateStatPointsSaved.request_completed.connect(_on_UpdateStatPointsSaved_request_completed)
	
	# Set the payload and request URL for updating stat points.
	var payload: Dictionary = stat_points_saved
	var request_url: String = host + "/api/update/statpoints"
	
	# Send the POST request to update stat points on the server.
	BKMREngine.send_post_request(UpdateStatPointsSaved, request_url, payload)
	return self
	
# Callback function triggered when the server responds to the stat points update request.
func _on_UpdateStatPointsSaved_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Free the request resources.
	BKMREngine.free_request(wrUpdateStatPointsSaved, UpdateStatPointsSaved)
	
	# Parse the JSON body received from the server.
	var json_body: Dictionary = JSON.parse_string(body.get_string_from_utf8())
	
	# Check if the server update was successful.
	if status_check:
		if json_body.success:
			# Log a successful stat points update.
			BKMRLogger.info("BKMREngine stat update successful")
			
			# Emit a signal indicating the completion of the stat points update.
			stat_update_complete.emit(json_body)
		else:
			stat_update_complete.emit({"Error": "Unknown Server Error"})
#endregion

#region for Profile Pic
# Function called to upload a profile picture.
func upload_profile_pic(image_buffer: PackedByteArray) -> void:
	# Prepare the HTTP request and associated resources.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	UploadProfilePicture = prepared_http_req.request
	wrUploadProfilePicture = prepared_http_req.weakref
	
	# Connect the callback function to the request_completed signal.
	var _upload: int = UploadProfilePicture.request_completed.connect(_on_ProfilePictureUpload_request_completed)
	
	# Prepare the payload with the image data.
	var payload: Dictionary = { "bufferData": image_buffer }
	
	# Specify the request URL for profile picture upload.
	var request_url: String = host + "/api/upload/dp/"
	
	# Send a POST request to upload the profile picture.
	BKMREngine.send_post_request(UploadProfilePicture, request_url, payload)
	
# Callback function triggered when the profile picture upload request is completed.
func _on_ProfilePictureUpload_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Free resources associated with the HTTP request.
	BKMREngine.free_request(wrUploadProfilePicture, UploadProfilePicture)
	
	# Parse the response body as a JSON dictionary.
	var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
	if json_body != null:
	# Check if the upload was successful based on the JSON response.
		if status_check:
			if json_body.has("success"):
				BKMRLogger.info(json_body.success)
				profile_pic_upload_complete.emit(json_body)
			elif json_body.has("error"):
				profile_pic_upload_complete.emit(json_body.error)
			else:
				profile_pic_upload_complete.emit({ "error": "Unknown Server Error" })
		else:
			profile_pic_upload_complete.emit({ "error": "Unknown Server Error" })
		
# Function to retrive profile pic from the server.
func get_profile_pic() -> void:
	# Prepare an HTTP request for fetching profile pictures.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	GetProfilePicture = prepared_http_req.request
	wrGetProfilePicture  = prepared_http_req.weakref
	
	# Connect the callback function to handle the completion of the request.
	var _connect: int = GetProfilePicture.request_completed.connect(_onGetProfilePicture_request_completed)
	
	# Log the initiation of the request.
	BKMRLogger.info("Calling BKMREngine to get profile picture data")
	
	# Construct the request URL for fetching profile pictures for the specified user.
	var request_url: String = host + "/api/open/profilepic/"

	# Send a GET request to retrieve the profile pictures.
	BKMREngine.send_get_request(GetProfilePicture, request_url)

# Callback function to handle the completion of the private inbox data retrieval request.
func _onGetProfilePicture_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check if the HTTP response indicates success.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Free the HTTP request resource if it is still valid.
	if is_instance_valid(GetProfilePicture):
		BKMREngine.free_request(wrGetProfilePicture, GetProfilePicture)
	
	# If the HTTP response indicates success, parse the JSON response body.
	if status_check:
		# Parse the JSON response body.
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body.has("error"):
				BKMRLogger.info(json_body.error)
				get_profile_pic_complete.emit(json_body.error)
			else:
				get_profile_pic_complete.emit(json_body)
		else:
			get_profile_pic_complete.emit({"Error:": "Unknown Server Error" })
	else:
		get_profile_pic_complete.emit({"Error:": "Unknown Server Error" })
		
func get_player_profile_pic(player_username: String) -> void:
	# Prepare an HTTP request for fetching profile pictures.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	GetPlayerProfilePicture = prepared_http_req.request
	wrGetPlayerProfilePicture  = prepared_http_req.weakref
	
	# Connect the callback function to handle the completion of the request.
	var _connect: int = GetPlayerProfilePicture.request_completed.connect(_onGetPlayerProfilePicture_request_completed)
	
	# Log the initiation of the request.
	BKMRLogger.info("Calling BKMREngine to get profile picture data")
	
	# Construct the request URL for fetching profile pictures for the specified user.
	var request_url: String = host + "/api/open/playerprofilepic/" + player_username

	# Send a GET request to retrieve the profile pictures.
	BKMREngine.send_get_request(GetPlayerProfilePicture, request_url)

# Callback function to handle the completion of the private inbox data retrieval request.
func _onGetPlayerProfilePicture_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check if the HTTP response indicates success.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Free the HTTP request resource if it is still valid.
	if is_instance_valid(GetPlayerProfilePicture):
		BKMREngine.free_request(wrGetPlayerProfilePicture, GetPlayerProfilePicture)
	
	# If the HTTP response indicates success, parse the JSON response body.
	if status_check:
		# Parse the JSON response body.
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body.has("error"):
				BKMRLogger.info(json_body.error)
				get_player_profile_pic_complete.emit(json_body.error)
			else:
				get_player_profile_pic_complete.emit(json_body)
		else:
			get_player_profile_pic_complete.emit({"Error:": "Unknown Server Error" })
	else:
		get_player_profile_pic_complete.emit({"Error:": "Unknown Server Error" })
		
func like_profile_picture(picture_id: String) -> void:
	# Prepare the HTTP request and associated resources.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	LikeProfilePicture = prepared_http_req.request
	wrLikeProfilePicture = prepared_http_req.weakref
	
	# Connect the callback function to the request_completed signal.
	var _upload: int = LikeProfilePicture.request_completed.connect(_on_LikeProfilePicture_request_completed)
	
	# Prepare the payload with the image data.
	var payload: Dictionary = { "id": picture_id }
	
	# Specify the request URL for profile picture upload.
	var request_url: String = host + "/api/like/profilepic"
	
	# Send a POST request to upload the profile picture.
	BKMREngine.send_post_request(LikeProfilePicture, request_url, payload)
	
# Callback function triggered when the profile picture upload request is completed.
func _on_LikeProfilePicture_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Free resources associated with the HTTP request.
	BKMREngine.free_request(wrLikeProfilePicture, LikeProfilePicture)
	
	# Parse the response body as a JSON dictionary.
	var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
	if json_body != null:
	# Check if the upload was successful based on the JSON response.
		if status_check:
			if json_body.has("success"):
				BKMRLogger.info(json_body.success)
				like_profile_pic_complete.emit(json_body)
			elif json_body.has("error"):
				like_profile_pic_complete.emit(json_body.error)
			else:
				like_profile_pic_complete.emit({ "error": "Unknown Server Error" })
		else:
			like_profile_pic_complete.emit({ "error": "Unknown Server Error" })
	else:
		like_profile_pic_complete.emit({ "error": "Unknown Server Error" })
		
func unlike_profile_picture(picture_id: String) -> void:
	# Prepare the HTTP request and associated resources.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	UnlikeProfilePicture = prepared_http_req.request
	wrUnlikeProfilePicture = prepared_http_req.weakref
	
	# Connect the callback function to the request_completed signal.
	var _upload: int = UnlikeProfilePicture.request_completed.connect(_on_UnlikeProfilePicture_request_completed)
	
	# Prepare the payload with the image data.
	var payload: Dictionary = { "id": picture_id }
	
	# Specify the request URL for profile picture upload.
	var request_url: String = host + "/api/unlike/profilepic"
	
	# Send a POST request to upload the profile picture.
	BKMREngine.send_post_request(UnlikeProfilePicture, request_url, payload)
	
# Callback function triggered when the profile picture upload request is completed.
func _on_UnlikeProfilePicture_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Free resources associated with the HTTP request.
	BKMREngine.free_request(wrUnlikeProfilePicture, UnlikeProfilePicture)
	
	# Parse the response body as a JSON dictionary.
	var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
	if json_body != null:
	# Check if the upload was successful based on the JSON response.
		if status_check:
			if json_body.has("success"):
				BKMRLogger.info(json_body.success)
				unlike_profile_pic_complete.emit(json_body)
			elif json_body.has("error"):
				unlike_profile_pic_complete.emit(json_body.error)
			else:
				unlike_profile_pic_complete.emit({ "error": "Unknown Server Error" })
		else:
			unlike_profile_pic_complete.emit({ "error": "Unknown Server Error" })

func change_profile_picture(picture_id: String) -> void:
	# Prepare the HTTP request and associated resources.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	ChangeProfilePicture = prepared_http_req.request
	wrChangeProfilePicture = prepared_http_req.weakref
	
	# Connect the callback function to the request_completed signal.
	var _upload: int = ChangeProfilePicture.request_completed.connect(_on_ChangeProfilePicture_request_completed)
	
	# Prepare the payload with the image data.
	var payload: Dictionary = { "id": picture_id }
	
	# Specify the request URL for profile picture upload.
	var request_url: String = host + "/api/change/profilepic"
	
	# Send a POST request to upload the profile picture.
	BKMREngine.send_post_request(UnlikeProfilePicture, request_url, payload)
	
# Callback function triggered when the profile picture upload request is completed.
func _on_ChangeProfilePicture_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Free resources associated with the HTTP request.
	BKMREngine.free_request(wrChangeProfilePicture, ChangeProfilePicture)
	
	# Parse the response body as a JSON dictionary.
	var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
	if json_body != null:
	# Check if the upload was successful based on the JSON response.
		if status_check:
			if json_body.has("success"):
				BKMRLogger.info(json_body.success)
				change_profile_pic_complete.emit(json_body)
			elif json_body.has("error"):
				change_profile_pic_complete.emit(json_body.error)
			else:
				change_profile_pic_complete.emit({ "error": "Unknown Server Error" })
		else:
			change_profile_pic_complete.emit({ "error": "Unknown Server Error" })
#endregion

func save_preference(preferences_data: Dictionary) -> void:
	# Prepare the HTTP request.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	SavePreference = prepared_http_req.request
	wrSavePreference = prepared_http_req.weakref
	
	# Connect the request completion signal to the callback function.
	var _update_stat_points: int = SavePreference.request_completed.connect(_on_SavePreference_request_completed)
	
	# Set the payload and request URL for updating stat points.
	var payload: Dictionary = preferences_data
	var request_url: String = host + "/api/profile/preference/save"
	
	# Send the POST request to update stat points on the server.
	BKMREngine.send_post_request(SavePreference, request_url, payload)

func _on_SavePreference_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	BKMREngine.free_request(wrSavePreference, SavePreference)
	
	# Parse the JSON body received from the server.
	var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
	if status_check:
		if json_body.has("success"):
			BKMRLogger.info("BKMREngine stat update successful")
			preference_save_complete.emit(json_body)
		else:
			# Print the JSON body if the update was not successful.
			preference_save_complete.emit(json_body.error)
	else:
		preference_save_complete.emit({"Error": "Unknown Server Error"})

func get_soul() -> void:
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	GetPreference = prepared_http_req.request
	wrGetPreference  = prepared_http_req.weakref
	
	BKMRLogger.info("Calling BKMREngine to get preferences")
	
	# Connect the callback function to handle the completion of the private inbox data request.
	var _soul: int = GetPreference.request_completed.connect(_onGetSoul_request_completed)
	var request_url: String = host + "/api/profile/preference/soul"
	BKMREngine.send_get_request(GetPreference, request_url)

func _onGetSoul_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check if the HTTP response indicates success.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Free the HTTP request resource if it is still valid.
	if is_instance_valid(GetPreference):
		BKMREngine.free_request(wrGetPreference, GetPreference)
	
	if status_check:
		var json_body: Dictionary = JSON.parse_string(body.get_string_from_utf8())
		if json_body.has("error"):
			BKMRLogger.info(json_body.error)
			preference_get_complete.emit(json_body.error)
		else:
			preference_get_complete.emit(json_body)
	else:
		preference_get_complete.emit({"Error:": "Unknown Server Error" })

func get_card_count() -> void:
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	GetCardCount = prepared_http_req.request
	wrGetCardCount  = prepared_http_req.weakref
	
	BKMRLogger.info("Calling BKMREngine to get preferences")
	var _count: int = GetCardCount.request_completed.connect(_onGetCardCount_request_completed)
	var request_url: String = host + "/api/profile/card/count"
	BKMREngine.send_get_request(GetCardCount, request_url)
	
func _onGetCardCount_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	if is_instance_valid(GetCardCount):
		BKMREngine.free_request(wrGetCardCount, GetCardCount)
	
	if status_check:
		var json_body: Dictionary = JSON.parse_string(body.get_string_from_utf8())
		if json_body.has("error"):
			BKMRLogger.info(json_body.error)
			card_count_get_complete.emit(json_body.error)
		else:
			card_count_get_complete.emit(json_body)
	else:
		card_count_get_complete.emit({"Error:": "Unknown Server Error" })

func get_card_collection() -> void:
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	GetCardCollection = prepared_http_req.request
	wrGetCardCollection = prepared_http_req.weakref
	
	BKMRLogger.info("Calling BKMREngine to get preferences")
	var _count: int = GetCardCollection.request_completed.connect(_onGetCardCollection_request_completed)
	var request_url: String = host + "/api/profile/card/collection"
	BKMREngine.send_get_request(GetCardCollection, request_url)
	
func _onGetCardCollection_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	if is_instance_valid(GetCardCount):
		BKMREngine.free_request(wrGetCardCollection, GetCardCollection)
	
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body.has("error"):
			BKMRLogger.info(json_body.error)
			card_collection_get_complete.emit(json_body.error)
		else:
			card_collection_get_complete.emit(json_body)
	else:
		card_collection_get_complete.emit({"Error:": "Unknown Server Error" })

func update_my_note(my_note: String) -> void:
	# Prepare the HTTP request and associated resources.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	UpdateMyNote = prepared_http_req.request
	wrUpdateMyNote = prepared_http_req.weakref
	
	# Connect the callback function to the request_completed signal.
	var _upload: int = UpdateMyNote.request_completed.connect(_on_UpdateMyNote_request_completed)
	
	# Prepare the payload with the image data.
	var payload: Dictionary = { "note": my_note }
	
	# Specify the request URL for profile picture upload.
	var request_url: String = host + "/api/mynote/update"
	
	# Send a POST request to upload the profile picture.
	BKMREngine.send_post_request(UpdateMyNote, request_url, payload)
	
# Callback function triggered when the profile picture upload request is completed.
func _on_UpdateMyNote_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Free resources associated with the HTTP request.
	BKMREngine.free_request(wrUpdateMyNote, UpdateMyNote)
	
	# Parse the response body as a JSON dictionary.
	var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
	if json_body != null:
	# Check if the upload was successful based on the JSON response.
		if status_check:
			if json_body.has("success"):
				BKMRLogger.info(json_body.success)
				update_my_note_complete.emit(json_body)
			elif json_body.has("error"):
				update_my_note_complete.emit(json_body.error)
			else:
				update_my_note_complete.emit({ "error": "Unknown Server Error" })
		else:
			update_my_note_complete.emit({ "error": "Unknown Server Error" })
	else:
		update_my_note_complete.emit({ "error": "Unknown Server Error" })

func get_my_note() -> void:
	# Prepare the HTTP request and associated resources.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	GetMyNote = prepared_http_req.request
	wrGetMyNote = prepared_http_req.weakref
	
	# Connect the callback function to the request_completed signal.
	var _upload: int = GetMyNote.request_completed.connect(_on_GetMyNote_request_completed)
	
	# Specify the request URL for profile picture upload.
	var request_url: String = host + "/api/mynote/latest"
	
	# Send a POST request to upload the profile picture.
	BKMREngine.send_get_request(GetMyNote, request_url)
	
# Callback function triggered when the profile picture upload request is completed.
func _on_GetMyNote_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Free resources associated with the HTTP request.
	BKMREngine.free_request(wrGetMyNote, GetMyNote)
	
	# Parse the response body as a JSON dictionary.
	var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
	if json_body != null:
		if status_check:
			if json_body:
				get_my_note_complete.emit(json_body)
			elif json_body.has("error"):
				get_my_note_complete.emit(json_body.error)
			else:
				get_my_note_complete.emit({ "error": "Unknown Server Error" })
		else:
			get_my_note_complete.emit({ "error": "Unknown Server Error" })
	else:
		get_my_note_complete.emit({ "error": "Unknown Server Error" })
	
func get_profile_pics(usernames: Array) -> void:
	# Prepare the HTTP request and associated resources.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	GetProfilePics = prepared_http_req.request
	wrGetProfilePics = prepared_http_req.weakref
	
	# Connect the callback function to the request_completed signal.
	var _upload: int = GetProfilePics.request_completed.connect(_on_GetProfilePics_request_completed)
	
	# Prepare the payload with the image data.
	var payload: Array = usernames
	
	# Specify the request URL for profile picture upload.
	var request_url: String = host + "/api/open/profilepics"
	
	# Send a POST request to upload the profile picture.
	BKMREngine.send_post_request(GetProfilePics, request_url, payload)
	
# Callback function triggered when the profile picture upload request is completed.
func _on_GetProfilePics_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Free resources associated with the HTTP request.
	BKMREngine.free_request(wrGetProfilePics, GetProfilePics)
	
	# Parse the response body as a JSON dictionary.
	var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
	if json_body != null:
	# Check if the upload was successful based on the JSON response.
		if status_check:
			if json_body.has("error"):
				get_profile_pics_complete.emit(json_body.error)
			else:
				print("GANO KALAKI :", json_body.size())
				get_profile_pics_complete.emit(json_body)
		else:
			get_profile_pics_complete.emit({ "error": "Unknown Server Error" })
	else:
		get_profile_pics_complete.emit({ "error": "Unknown Server Error" })
