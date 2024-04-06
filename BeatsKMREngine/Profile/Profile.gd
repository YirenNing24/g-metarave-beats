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
signal open_profile_pic_complete(profile_pic: Array)
var profile_pics: Array

# HTTPRequest object for updating saved stat points.
var UpdateStatPointsSaved: HTTPRequest = null
var wrUpdateStatPointsSaved: WeakRef = null
signal stat_update_complete(data: String)

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
			# Print the JSON body if the update was not successful.
			print(json_body)
#endregion

#region for Profile Pic
# Function called to upload a profile picture.
func upload_profile_pic(image_buffer: PackedByteArray) -> Node:
	# Prepare the HTTP request and associated resources.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	UploadProfilePicture = prepared_http_req.request
	wrUploadProfilePicture = prepared_http_req.weakref
	
	# Connect the callback function to the request_completed signal.
	var _upload: int = UploadProfilePicture.request_completed.connect(_on_ProfilePictureUpload_request_completed)
	
	# Prepare the payload with the image data.
	var payload: Dictionary = {"bufferData": image_buffer}
	
	# Specify the request URL for profile picture upload.
	var request_url: String = host + "/api/upload/dp/"
	
	# Send a POST request to upload the profile picture.
	BKMREngine.send_post_request(UploadProfilePicture, request_url, payload)
	
	# Return the current instance of the Node.
	return self

# Callback function triggered when the profile picture upload request is completed.
func _on_ProfilePictureUpload_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Free resources associated with the HTTP request.
	BKMREngine.free_request(wrUploadProfilePicture, UploadProfilePicture)
	
	# Parse the response body as a JSON dictionary.
	var json_body: Dictionary = JSON.parse_string(body.get_string_from_utf8())
	var _bkmr_result: Dictionary
	
	# Check if the upload was successful based on the JSON response.
	if status_check:
		if json_body.success:
			_bkmr_result = {"success": "Profile picture upload successful"}
			BKMRLogger.info("BKMREngine profile picture upload successful")
			# Update profile picture URLs and emit a signal to notify completion.
			#profilePicURLs = json_body.profilePics
			#PLAYER.profile_pics = json_body.profilePics
			profile_pic_upload_complete.emit(json_body)
		else:
			profile_pic_upload_complete.emit(json_body.error)	

# Function to retrive profile pic from the server.
func get_profile_pic() -> Node:
	# Prepare an HTTP request for fetching private inbox data.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	GetProfilePicture = prepared_http_req.request
	wrGetProfilePicture  = prepared_http_req.weakref
	
	# Connect the callback function to handle the completion of the private inbox data request.
	var _cards: int = GetProfilePicture.request_completed.connect(_onGetProfilePicture_request_completed)
	
	# Log the initiation of the request to retrieve inbox messages.
	BKMRLogger.info("Calling BKMREngine to get card inventory data")
	
	# Construct the request URL for fetching private inbox data for the specified user.
	var request_url: String = host + "/api/open/profilepic"
	
	# Send a GET request to retrieve the private inbox data.
	await BKMREngine.send_get_request(GetProfilePicture, request_url)
	
	# Return the current node for method chaining.
	return self as Node

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
		if json_body.has("error"):
			BKMRLogger.info(json_body.error)
		else:
			open_profile_pic_complete.emit(json_body)
			profile_pics = json_body
#endregion
