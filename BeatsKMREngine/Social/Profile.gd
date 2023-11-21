extends Node

# Preloaded scripts for utility functions and logging.
const BKMRUtils: Script = preload("res://BeatsKMREngine/utils/BKMRUtils.gd")
const BKMRLogger: Script = preload("res://BeatsKMREngine/utils/BKMRLogger.gd")

# HTTPRequest object for profile picture upload.
var UploadProfilePicture: HTTPRequest = null
var ProfilePictureUpload: WeakRef = null

# HTTPRequest object for updating saved stat points.
var UpdateStatPointsSaved: HTTPRequest = null
var StatPointsSavedUpdate: WeakRef = null

# Host URL for server communication.
var host: String = BKMREngine.host

# Array to store profile picture URLs.
var profilePicURLs: Array

# Signals for completion of profile picture upload and stat points update.
signal profile_pic_upload_complete
signal stat_update_complete(data: String)

# Function called to upload a profile picture.
# Function to upload a user's profile picture to the server.
# Parameters:
# - image_buffer (PackedByteArray): The packed byte array containing the image data.
# Returns:
# - Node: The current instance of the Node.
func upload_profile_pic(image_buffer: PackedByteArray) -> Node:
	# Prepare the HTTP request and associated resources.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	UploadProfilePicture = prepared_http_req.request
	ProfilePictureUpload = prepared_http_req.weakref
	
	# Connect the callback function to the request_completed signal.
	var _upload: int = UploadProfilePicture.request_completed.connect(_on_ProfilePictureUpload_request_completed)
	
	# Prepare the payload with the image data.
	var payload: Dictionary = {"bufferData": image_buffer}
	
	# Specify the request URL for profile picture upload.
	var request_url: String = host + "/api/upload/pic/profile/"
	
	# Send a POST request to upload the profile picture.
	BKMREngine.send_post_request(UploadProfilePicture, request_url, payload)
	
	# Return the current instance of the Node.
	return self

	
# Callback function triggered when the profile picture upload request is completed.
# Parameters:
# - _result (int): The result of the request.
# - response_code (int): The HTTP response code.
# - headers (Array): The array of response headers.
# - body (PackedByteArray): The packed byte array containing the response body.
# Returns:
# - void
func _on_ProfilePictureUpload_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Free resources associated with the HTTP request.
	BKMREngine.free_request(ProfilePictureUpload, UploadProfilePicture)
	
	# Parse the response body as a JSON dictionary.
	var json_body: Dictionary = JSON.parse_string(body.get_string_from_utf8())
	var _bkmr_result: Dictionary
	
	# Check if the upload was successful based on the JSON response.
	if status_check:
		if json_body.success:
			_bkmr_result = {"success": "Profile picture upload successful"}
			BKMRLogger.info("BKMREngine profile picture upload successful")
			
			# Update profile picture URLs and emit a signal to notify completion.
			profilePicURLs = json_body.profilePics
			PLAYER.profile_pics = json_body.profilePics
			profile_pic_upload_complete.emit()
		else:
			print(json_body)
	
# Function to update saved stat points by making an API request to the server.
# Parameters:
# - stat_points_saved (Dictionary): Dictionary containing the updated stat points.
# Returns:
# - Node: Self-reference for chaining method calls.
func update_statpoints_saved(stat_points_saved: Dictionary) -> Node:
	# Prepare the HTTP request.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	UpdateStatPointsSaved = prepared_http_req.request
	StatPointsSavedUpdate = prepared_http_req.weakref
	
	# Connect the request completion signal to the callback function.
	var _update_stat_points: int = UpdateStatPointsSaved.request_completed.connect(_on_UpdateStatPointsSaved_request_completed)
	
	# Set the payload and request URL for updating stat points.
	var payload: Dictionary = stat_points_saved
	var request_url: String = host + "/api/update/statpoints"
	
	# Send the POST request to update stat points on the server.
	BKMREngine.send_post_request(UpdateStatPointsSaved, request_url, payload)
	
	# Return self-reference for method chaining.
	return self

# Callback function triggered when the server responds to the stat points update request.
# Parameters:
# - _result (Dictionary): Result of the HTTP request.
# - response_code (int): HTTP response code.
# - headers (Array): Array of HTTP headers.
# - body (PackedByteArray): Response body containing server data.
# Returns:
# - void
func _on_UpdateStatPointsSaved_request_completed(_result: Dictionary, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Free the request resources.
	BKMREngine.free_request(StatPointsSavedUpdate, UpdateStatPointsSaved)
	
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
