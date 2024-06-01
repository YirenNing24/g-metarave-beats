extends Node

# Preloaded scripts for utility functions and logging.
const BKMRUtils: Script = preload("res://BeatsKMREngine/utils/BKMRUtils.gd")
const BKMRLogger: Script = preload("res://BeatsKMREngine/utils/BKMRLogger.gd")

# Signals for completion of view profile, follow, unfollow, and get mutual followers operations.
signal view_profile_complete
signal follow_complete
signal unfollow_complete
signal get_mutual_complete(mutual_list: Array)
signal gift_card_complete
#signal set_status_online_complete
signal get_mutual_status_complete

# Host URL for server communication.
var host: String = BKMREngine.host

# HTTPRequest objects and WeakRefs for view profile, follow, unfollow, and get mutual followers.
var ViewProfile: HTTPRequest
var wrViewProfile: WeakRef

var Follow: HTTPRequest
var wrFollow: WeakRef

var Unfollow: HTTPRequest
var wrUnfollow: WeakRef

var Mutual: HTTPRequest
var wrMutual: WeakRef

var OnlineStatus: HTTPRequest
var wrOnlineStatus: WeakRef

var MutualStatus: HTTPRequest
var wrMutualStatus: WeakRef

var GiftCard: HTTPRequest
var wrGiftCard: WeakRef

# Data containers for player profile, follow response, and mutual followers.
var player_profile: Dictionary 
var follow_response: Dictionary
var mutual_status: Array
var mutual_followers: Array

# Function to view a player's profile.
func view_profile(username: String) -> void:
	# Prepare HTTP request for viewing a player's profile.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	ViewProfile = prepared_http_req.request
	wrViewProfile = prepared_http_req.weakref
	
	# Connect the callback function for handling the request completion.
	var _view_profile: int = ViewProfile.request_completed.connect(_onViewProfile_request_completed)
	
	# Log the initiation of the profile view request.
	BKMRLogger.info("Calling BKMREngine to get cards on sale data")
	
	# Prepare the request URL for viewing the player's profile.
	var request_url: String = host + "/api/social/viewprofile/" + username
	
	# Send the GET request to view the player's profile.
	await BKMREngine.send_get_request(ViewProfile, request_url)
	
	# Return the current Node.

# Callback function executed when the view profile request is completed.
func _onViewProfile_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Free the HTTP request resources if the instance is valid.
	if is_instance_valid(ViewProfile):
		BKMREngine.free_request(wrViewProfile, ViewProfile)
	
	# Process the response if the status check is successful.
	if status_check:
		# Parse the response body as a JSON dictionary.
		var json_body: Dictionary = JSON.parse_string(body.get_string_from_utf8())
		
		# Assign the player profile data to the global variable.
		player_profile = json_body
		
		# Emit a signal indicating that the profile view is complete.
		view_profile_complete.emit()

# Function to initiate a follow action for a player..
func follow(follower: String, to_follow: String) -> Node:
	# Prepare the HTTP request.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	Follow = prepared_http_req.request
	wrFollow = prepared_http_req.weakref
	
	# Connect the callback function to handle the completion of the follow request.
	var _follow: int = Follow.request_completed.connect(_onFollow_request_completed)
	
	# Prepare the payload with follower and to_follow usernames.
	var payload: Dictionary = { "follower": follower, "toFollow": to_follow }
	
	# Construct the request URL.
	var request_url: String = host + "/api/social/follow"
	
	# Send the POST request to initiate the follow action.
	BKMREngine.send_post_request(Follow, request_url, payload)
	
	# Return the current node for method chaining.
	return self

	
# Callback function triggered when a follow request is completed.
func _onFollow_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Free the request resources if the HTTP response is valid.
	if is_instance_valid(Follow):
		BKMREngine.free_request(wrFollow, Follow)
	
	# Process the response body if the HTTP status check is successful.
	if status_check:
		# Parse the JSON body from the response.
		var json_body: Dictionary = JSON.parse_string(body.get_string_from_utf8())
		
		# Store the follow response in the appropriate variable.
		follow_response = json_body
		
		# Emit the signal to indicate that the follow action is complete.
		follow_complete.emit()

# Function to send a request to unfollow a player.
func unfollow(follower: String, toUnfollow: String) -> Node:
	# Prepare the HTTP request.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	Unfollow = prepared_http_req.request
	wrUnfollow = prepared_http_req.weakref
	
	# Connect the callback function to the request completion signal.
	var _follow: int = Unfollow.request_completed.connect(_onUnfollow_request_completed)
	
	# Prepare the payload for the unfollow request.
	var payload: Dictionary = { "follower": follower, "toUnfollow": toUnfollow }
	
	# Set the request URL for the unfollow action.
	var request_url: String = host + "/api/social/unfollow"
	
	# Send the POST request to unfollow the specified player.
	BKMREngine.send_post_request(Unfollow, request_url, payload)
	
	# Return the current node.
	return self

# Callback function triggered when the unfollow request is completed.
func _onUnfollow_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Free the request resources if the request instance is valid.
	if is_instance_valid(Unfollow):
		BKMREngine.free_request(wrUnfollow, Unfollow)
	
	# Process the response if the status check is successful.
	if status_check:
		# Parse the response body as a JSON dictionary.
		var json_body: Dictionary = JSON.parse_string(body.get_string_from_utf8())
		
		# Store the response in the follow_response variable.
		follow_response = json_body
		
		# Emit the signal indicating that the unfollow action is complete.
		unfollow_complete.emit()

# Function to retrieve mutual followers between the authenticated player and other users.
func get_mutual() -> void:
	# Prepare HTTP request resources.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	Mutual = prepared_http_req.request
	wrMutual  = prepared_http_req.weakref
	
	# Connect the callback function for handling mutual followers request completion.
	var _mutuals: int = Mutual.request_completed.connect(_onGetMutual_request_completed)
	
	# Log the initiation of the request.
	BKMRLogger.info("Calling BKMREngine to get mutual followers data")
	
	# Specify the request URL for retrieving mutual followers data.
	var request_url: String = host + "/api/social/list/mutual"
	
	await BKMREngine.send_get_request(Mutual, request_url)

# Callback function invoked upon completion of the get_mutual request.
func _onGetMutual_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Free resources associated with the HTTP request if valid.
	if is_instance_valid(Mutual):
		BKMREngine.free_request(wrMutual, Mutual)
	
	# Process the response data if the status check is successful.
	if status_check:
		# Parse the response body as a JSON array.
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			# Assign the parsed data to the mutual_followers variable.
			mutual_followers = json_body
			
			# Emit the signal to indicate the completion of the get_mutual request.
			get_mutual_complete.emit(json_body)
		else:
			pass

func set_status_online(activity: String) -> Node:
	# Check the HTTP response status.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	OnlineStatus = prepared_http_req.request
	wrOnlineStatus = prepared_http_req.weakref
	
	# Connect the callback function to handle the completion of the follow request.
	var _set_status: int = OnlineStatus.request_completed.connect(_onSetStatus_Online_request_completed)
	
	var user_agent: String = OS.get_unique_id()
	var os_name: String = OS.get_name()

	# Prepare the payload with the activity and device info.
	var payload: Dictionary = { "activity": activity, "userAgent": user_agent, "osName": os_name }
	
	# Construct the request URL.
	var request_url: String = host + "/api/social/status/online"
	
	# Send the POST request to initiate the follow action.
	BKMREngine.send_post_request(OnlineStatus, request_url, payload)
	
	# Return the current node for method chaining.
	return self

func _onSetStatus_Online_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Free the request resources if the HTTP response is valid.
	if is_instance_valid(OnlineStatus):
		BKMREngine.free_request(wrOnlineStatus, OnlineStatus)
	
	# Process the response body if the HTTP status check is successful.
	if status_check:
		pass

func get_mutual_status() -> void:
	# Prepare HTTP request resources.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	MutualStatus = prepared_http_req.request
	wrMutualStatus  = prepared_http_req.weakref
	
	# Connect the callback function for handling mutual followers request completion.
	var _mutuals_status: int = MutualStatus.request_completed.connect(_on_MutualStatus_request_completed)
	var request_url: String = host + "/api/social/mutual/online"
	
	# Initiate the GET request and await its completion.
	await BKMREngine.send_get_request(MutualStatus, request_url)
	
# Callback function invoked upon completion of the get_mutual request.
func _on_MutualStatus_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	# Free resources associated with the HTTP request if valid.
	if is_instance_valid(MutualStatus):
		BKMREngine.free_request(wrMutualStatus, MutualStatus)
	
	# Process the response data if the status check is successful.
	if status_check:
		# Parse the response body as a JSON array.
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			# Assign the parsed data to the mutual_followers variable.
			mutual_status = json_body
			get_mutual_status_complete.emit()
		else:
			pass

func gift_card(card_gift_data: Dictionary) -> void:
	# Prepare the HTTP request.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	GiftCard = prepared_http_req.request
	wrGiftCard = prepared_http_req.weakref
	
	# Connect the callback function to handle the completion of the follow request.
	var _gift_card: int = GiftCard.request_completed.connect(_onGiftCard_request_completed)
	var payload: Dictionary = card_gift_data
	
	# Construct the request URL.
	var request_url: String = host + "/api/social/gift/card"
	BKMREngine.send_post_request(GiftCard, request_url, payload)
	
# Callback function triggered when a follow request is completed.
func _onGiftCard_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Free the request resources if the HTTP response is valid.
	if is_instance_valid(GiftCard):
		BKMREngine.free_request(wrGiftCard, GiftCard)
	
	# Process the response body if the HTTP status check is successful.
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			gift_card_complete.emit(json_body)
		else:
			gift_card_complete.emit({ "error": "Unknown server error"})
	else:
		gift_card_complete.emit({ "error": "Unknown server error"})
