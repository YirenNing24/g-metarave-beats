extends Node

# Preloaded scripts for utility functions and logging.
const BKMRUtils: Script = preload("res://BeatsKMREngine/utils/BKMRUtils.gd")
const BKMRLogger: Script = preload("res://BeatsKMREngine/utils/BKMRLogger.gd")

# BKMREngine.host URL for server communication.
# var BKMREngine.host: String = BKMREngine.BKMREngine.host

# HTTPRequest objects and WeakRefs for view profile, follow, unfollow, and get mutual followers.
var ViewProfile: HTTPRequest
var wrViewProfile: WeakRef
signal view_profile_complete(player_profile: Dictionary)

var Follow: HTTPRequest
var wrFollow: WeakRef
signal follow_complete(message: Dictionary)

var Unfollow: HTTPRequest
var wrUnfollow: WeakRef
signal unfollow_complete(message: Dictionary)

var Mutual: HTTPRequest
var wrMutual: WeakRef
signal get_mutual_complete(mutual_list: Array)

var FollowersFollowingCount: HTTPRequest
var wrFollowersFollowingCount: WeakRef
signal get_followers_following_count_complete(followers_following_count: Dictionary)


var FollowersFollowing: HTTPRequest
var wrFollowersFollowing: WeakRef
signal get_followers_following_complete(followers_following_count: Dictionary)

var OnlineStatus: HTTPRequest
var wrOnlineStatus: WeakRef

var MutualStatus: HTTPRequest
var wrMutualStatus: WeakRef
signal get_mutual_status_complete

var GiftCard: HTTPRequest
var wrGiftCard: WeakRef
signal gift_card_complete

var PostFanMoments: HTTPRequest
var wrPostFanMoments: WeakRef
signal post_fan_moments_complete(mesasge: Dictionary)

var GetHotFanMoments: HTTPRequest
var wrGetHotFanMoments: WeakRef
signal get_hot_fan_moments_complete(posts: Array)

var GetMyFanMoments: HTTPRequest
var wrGetMyFanMoments: WeakRef
signal get_my_fan_moments_complete(posts: Array)

var GetLatestFanMoments: HTTPRequest
var wrGetLatestFanMoments: WeakRef
signal get_latest_fan_moments_complete(posts: Array)

var GetFollowingFanMoments: HTTPRequest
var wrGetFollowingFanMoments: WeakRef
signal get_following_fan_moments_complete(posts: Array)

var LikeFanMoments: HTTPRequest
var wrLikeFanMoments: WeakRef
signal like_fan_moments_complete(mesasge: Dictionary)

var UnlikeFanMoments: HTTPRequest
var wrUnlikeFanMoments: WeakRef
signal unlike_fan_moments_complete(mesasge: Dictionary)

var CommentFanMoment: HTTPRequest
var wrCommentFanMoment: WeakRef
signal comment_fan_moment_complete(mesasge: Dictionary)

# Data containers for player profile, follow response, and mutual followers.
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
	var request_url: String = BKMREngine.host + "/api/social/viewprofile/" + username
	
	# Send the GET request to view the player's profile.
	BKMREngine.send_get_request(ViewProfile, request_url)
	
	
# Callback function executed when the view profile request is completed.
func _onViewProfile_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	

	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body.has("error"):
				view_profile_complete.emit(json_body.error)
			else:
				view_profile_complete.emit(json_body)
		else:
			view_profile_complete.emit({"error": "Unknown Server Error"})
	else:
		view_profile_complete.emit({"error": "Unknown Server Error"})
			
			
# Function to initiate a follow action for a player..
func follow(to_follow: String) -> void:
	# Prepare the HTTP request.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	Follow = prepared_http_req.request
	wrFollow = prepared_http_req.weakref
	
	# Connect the callback function to handle the completion of the follow request.
	var _follow: int = Follow.request_completed.connect(_onFollow_request_completed)
	
	# Prepare the payload with follower and to_follow usernames.
	var payload: Dictionary = { "toFollow": to_follow }
	
	# Construct the request URL.
	var request_url: String = BKMREngine.host + "/api/social/follow"
	
	# Send the POST request to initiate the follow action.
	BKMREngine.send_post_request(Follow, request_url, payload)
	
	
# Callback function triggered when a follow request is completed.
func _onFollow_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Process the response body if the HTTP status check is successful.
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body.has("error"):
				follow_complete.emit(json_body.error)
			else:
				follow_complete.emit(json_body)
		else:
			follow_complete.emit({ "error": "Unknown Server Error" })
	else:
		follow_complete.emit({ "error": "Unknown Server Error" })


# Function to send a request to unfollow a player.
func unfollow(to_unfollow: String) -> void:
	# Prepare the HTTP request.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	Unfollow = prepared_http_req.request
	wrUnfollow = prepared_http_req.weakref
	
	# Connect the callback function to the request completion signal.
	var _follow: int = Unfollow.request_completed.connect(_onUnfollow_request_completed)
	
	# Prepare the payload for the unfollow request.
	var payload: Dictionary = { "toUnfollow": to_unfollow }
	
	# Set the request URL for the unfollow action.
	var request_url: String = BKMREngine.host + "/api/social/unfollow"
	
	# Send the POST request to unfollow the specified player.
	BKMREngine.send_post_request(Unfollow, request_url, payload)
	
	
# Callback function triggered when the unfollow request is completed.
func _onUnfollow_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Process the response if the status check is successful.
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body.has("error"):
				unfollow_complete.emit(json_body.error)
			else:
				unfollow_complete.emit(json_body)
		else:
			unfollow_complete.emit({ "error": "Unknown Server Error" })
	else:
		unfollow_complete.emit({ "error": "Unknown Server Error" })
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
	var request_url: String = BKMREngine.host + "/api/social/list/mutual"
	
	BKMREngine.send_get_request(Mutual, request_url)


# Callback function invoked upon completion of the get_mutual request.
func _onGetMutual_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
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


func get_following_followers_count(username: String = "") -> void:
	# Prepare HTTP request resources.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	FollowersFollowingCount = prepared_http_req.request
	wrFollowersFollowingCount  = prepared_http_req.weakref
	
	# Connect the callback function for handling mutual followers request completion.
	var _mutuals: int = FollowersFollowingCount.request_completed.connect(_onGetFollowingFollowersCount_request_completed)
	
	# Log the initiation of the request.
	BKMRLogger.info("Calling BKMREngine to get mutual followers data")
	
	# Specify the request URL for retrieving mutual followers data, using the username as a path parameter.
	var request_url: String = BKMREngine.host + "/api/social/follower-following/count/" + username
	
	BKMREngine.send_get_request(FollowersFollowingCount, request_url)


# Callback function invoked upon completion of the get_mutual request.
func _onGetFollowingFollowersCount_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Process the response data if the status check is successful.
	if status_check:
		# Parse the response body as a JSON array.
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body.has("error"):
				get_followers_following_count_complete.emit({ "error": json_body.error })
			else:
				get_followers_following_count_complete.emit(json_body)
		else:
			get_followers_following_count_complete.emit({ "error": "Unknown Server Error" })
	else:
		get_followers_following_count_complete.emit({ "error": "Unknown Server Error" })


func get_following_followers(username: String = "") -> void:
	# Prepare HTTP request resources.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	FollowersFollowing = prepared_http_req.request
	wrFollowersFollowing = prepared_http_req.weakref
	
	# Connect the callback function for handling mutual followers request completion.
	var _mutuals: int = FollowersFollowing.request_completed.connect(_onGetFollowingFollowers_request_completed)
	
	# Log the initiation of the request.
	BKMRLogger.info("Calling BKMREngine to get mutual followers data")
	
	# Construct the request URL, optionally including the username as a path parameter.
	var request_url: String = BKMREngine.host + "/api/social/follower-following"
	if username != "":
		request_url += "/" + username  # Append the username if provided
	
	# Send the GET request to the server.
	BKMREngine.send_get_request(FollowersFollowing, request_url)



# Callback function invoked upon completion of the get_mutual request.
func _onGetFollowingFollowers_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Process the response data if the status check is successful.
	if status_check:
		# Parse the response body as a JSON array.
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body.has("error"):
				get_followers_following_complete.emit({ "error": json_body.error })
			else:
				get_followers_following_complete.emit(json_body)
				print(json_body)
		else:
			get_followers_following_complete.emit({ "error": "Unknown Server Error" })
	else:
		get_followers_following_complete.emit({ "error": "Unknown Server Error" })



func set_status_online(activity: String) -> void:
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
	var request_url: String = BKMREngine.host + "/api/social/status/online"
	
	# Send the POST request to initiate the follow action.
	BKMREngine.send_post_request(OnlineStatus, request_url, payload)
	
	
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
	var request_url: String = BKMREngine.host + "/api/social/mutual/online"
	
	# Initiate the GET request and await its completion.
	BKMREngine.send_get_request(MutualStatus, request_url)
	
	
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
	var request_url: String = BKMREngine.host + "/api/social/gift/card"
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

# Function to initiate a follow action for a player..
func post_fan_moments(fan_moment_data: Dictionary) -> void:
	# Prepare the HTTP request.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	PostFanMoments = prepared_http_req.request
	wrPostFanMoments = prepared_http_req.weakref
	
	# Connect the callback function to handle the completion of the follow request.
	var _follow: int = PostFanMoments.request_completed.connect(_onPostFanMoment_request_completed)
	
	# Prepare the payload with follower and to_follow usernames.
	var payload: Dictionary = fan_moment_data
	
	# Construct the request URL.
	var request_url: String = BKMREngine.host + "/api/social/fanmoments/post"
	
	# Send the POST request to initiate the follow action.
	BKMREngine.send_post_request(PostFanMoments, request_url, payload)
	
	
# Callback function triggered when a follow request is completed.
func _onPostFanMoment_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Free the request resources if the HTTP response is valid.
	if is_instance_valid(PostFanMoments):
		BKMREngine.free_request(wrPostFanMoments, PostFanMoments)
	
	# Process the response body if the HTTP status check is successful.
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body.has("success"):
				post_fan_moments_complete.emit(json_body)
			else:
				post_fan_moments_complete.emit(json_body.error)
		else:
			post_fan_moments_complete.emit({ "error": "Unknown server error" })
	else:
		post_fan_moments_complete.emit({ "error": "Unknown server error" })


func get_hot_fan_moments(limit: int, offset: int) -> void:
	# Prepare HTTP request resources.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	GetHotFanMoments = prepared_http_req.request
	wrGetHotFanMoments = prepared_http_req.weakref
	
	# Connect the callback function for handling mutual followers request completion.
	var _mutuals_status: int = GetHotFanMoments.request_completed.connect(_on_GetHotFanMoments_request_completed)
	var request_url: String = BKMREngine.host + "/api/social/hot/fanmoments?limit=%d&offset=%d" % [limit, offset]
	
	# Initiate the GET request and await its completion.
	BKMREngine.send_get_request(GetHotFanMoments, request_url)


func _on_GetHotFanMoments_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Free the request resources if the HTTP response is valid.
	if is_instance_valid(GetHotFanMoments):
		BKMREngine.free_request(wrGetHotFanMoments, GetHotFanMoments)
	
	# Process the response body if the HTTP status check is successful.
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body.has("error"):
				get_hot_fan_moments_complete.emit(json_body.error)
			else:
				get_hot_fan_moments_complete.emit(json_body)
		else:
			get_hot_fan_moments_complete.emit({ "error": "Unknown server error" })
	else:
		get_hot_fan_moments_complete.emit({ "error": "Unknown server error" })


func get_my_fan_moments(limit: int, offset: int) -> void:
	# Prepare HTTP request resources.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	GetMyFanMoments = prepared_http_req.request
	wrGetMyFanMoments  = prepared_http_req.weakref
	
	# Connect the callback function for handling mutual followers request completion.
	var _mutuals_status: int = GetMyFanMoments.request_completed.connect(_on_GetMyFanMoments_request_completed)
	var request_url: String = BKMREngine.host + "/api/social/my/fanmoments?limit=%d&offset=%d" % [limit, offset]
	
	# Initiate the GET request and await its completion.
	BKMREngine.send_get_request(GetMyFanMoments, request_url)


func _on_GetMyFanMoments_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Free the request resources if the HTTP response is valid.
	if is_instance_valid(GetMyFanMoments):
		BKMREngine.free_request(wrGetMyFanMoments, GetMyFanMoments)
	
	# Process the response body if the HTTP status check is successful.
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body.has("error"):
				get_my_fan_moments_complete.emit(json_body.error)
			else:
				get_my_fan_moments_complete.emit(json_body)
		else:
			get_my_fan_moments_complete.emit({ "error": "Unknown server error" })
	else:
		get_my_fan_moments_complete.emit({ "error": "Unknown server error" })


func get_latest_fan_moments(limit: int, offset: int) -> void:
	# Prepare HTTP request resources.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	GetLatestFanMoments = prepared_http_req.request
	wrGetLatestFanMoments  = prepared_http_req.weakref
	
	# Connect the callback function for handling mutual followers request completion.
	var _mutuals_status: int = GetLatestFanMoments.request_completed.connect(_on_GetMyLatestMoments_request_completed)
	var request_url: String = BKMREngine.host + "/api/social/latest/fanmoments?limit=%d&offset=%d" % [limit, offset]
	
	# Initiate the GET request and await its completion.
	BKMREngine.send_get_request(GetLatestFanMoments, request_url)


func _on_GetMyLatestMoments_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Free the request resources if the HTTP response is valid.
	if is_instance_valid(GetLatestFanMoments):
		BKMREngine.free_request(wrGetLatestFanMoments, GetLatestFanMoments)
	
	# Process the response body if the HTTP status check is successful.
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body.has("error"):
				get_latest_fan_moments_complete.emit(json_body.error)
			else:
				get_latest_fan_moments_complete.emit(json_body)
		else:
			get_latest_fan_moments_complete.emit({ "error": "Unknown server error" })
	else:
		get_latest_fan_moments_complete.emit({ "error": "Unknown server error" })


func get_following_fan_moments(limit: int, offset: int) -> void:
	# Prepare HTTP request resources.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	GetFollowingFanMoments = prepared_http_req.request
	wrGetFollowingFanMoments  = prepared_http_req.weakref
	
	# Connect the callback function for handling mutual followers request completion.
	var _mutuals_status: int = GetFollowingFanMoments.request_completed.connect(_on_GetFollowingFanMoments_request_completed)
	var request_url: String = BKMREngine.host + "/api/social/following/fanmoments?limit=%d&offset=%d" % [limit, offset]
	
	# Initiate the GET request and await its completion.
	BKMREngine.send_get_request(GetFollowingFanMoments, request_url)


func _on_GetFollowingFanMoments_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Free the request resources if the HTTP response is valid.
	if is_instance_valid(GetFollowingFanMoments):
		BKMREngine.free_request(wrGetFollowingFanMoments, GetFollowingFanMoments)
	
	# Process the response body if the HTTP status check is successful.
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body.has("error"):
				get_following_fan_moments_complete.emit(json_body.error)
			else:
				get_following_fan_moments_complete.emit(json_body)
		else:
			get_following_fan_moments_complete.emit({ "error": "Unknown server error" })
	else:
		get_following_fan_moments_complete.emit({ "error": "Unknown server error" })


func like_fan_moment(moment_id: String) -> void:
	# Prepare the HTTP request and associated resources.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	LikeFanMoments = prepared_http_req.request
	wrLikeFanMoments  = prepared_http_req.weakref
	
	# Connect the callback function to the request_completed signal.
	var _like: int = LikeFanMoments.request_completed.connect(_on_LikeFanMoment_request_completed)
	
	# Prepare the payload with the image data.
	var payload: Dictionary = { "id": moment_id }
	
	# Specify the request URL for profile picture upload.
	var request_url: String = BKMREngine.host + "/api/social/fanmoments/like"
	
	# Send a POST request to upload the profile picture.
	BKMREngine.send_post_request(LikeFanMoments, request_url, payload)
	
	
# Callback function triggered when the profile picture upload request is completed.
func _on_LikeFanMoment_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Free resources associated with the HTTP request.
	BKMREngine.free_request(wrLikeFanMoments, LikeFanMoments)
	
	# Parse the response body as a JSON dictionary.
	var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
	if json_body != null:
	# Check if the upload was successful based on the JSON response.
		if status_check:
			if json_body.has("success"):
				like_fan_moments_complete.emit(json_body)
			elif json_body.has("error"):
				like_fan_moments_complete.emit(json_body.error)
			else:
				like_fan_moments_complete.emit({ "error": "Unknown Server Error" })
		else:
			like_fan_moments_complete.emit({ "error": "Unknown Server Error" })
	else:
		like_fan_moments_complete.emit({ "error": "Unknown Server Error" })
		
		
func unlike_fan_moment(moment_id: String) -> void:
	# Prepare the HTTP request and associated resources.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	UnlikeFanMoments = prepared_http_req.request
	wrUnlikeFanMoments  = prepared_http_req.weakref
	
	# Connect the callback function to the request_completed signal.
	var _like: int = UnlikeFanMoments.request_completed.connect(_on_UnlikeFanMoment_request_completed)
	
	# Prepare the payload with the image data.
	var payload: Dictionary = { "id": moment_id }
	
	# Specify the request URL for profile picture upload.
	var request_url: String = BKMREngine.host + "/api/social/fanmoments/unlike"
	
	# Send a POST request to upload the profile picture.
	BKMREngine.send_post_request(UnlikeFanMoments, request_url, payload)
	
	
func _on_UnlikeFanMoment_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Free resources associated with the HTTP request.
	BKMREngine.free_request(wrUnlikeFanMoments, UnlikeFanMoments)
	
	# Parse the response body as a JSON dictionary.
	var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
	if json_body != null:
	# Check if the upload was successful based on the JSON response.
		if status_check:
			if json_body.has("success"):
				unlike_fan_moments_complete.emit(json_body)
			elif json_body.has("error"):
				unlike_fan_moments_complete.emit(json_body.error)
			else:
				unlike_fan_moments_complete.emit({ "error": "Unknown Server Error" })
		else:
			unlike_fan_moments_complete.emit({ "error": "Unknown Server Error" })
	else:
		unlike_fan_moments_complete.emit({ "error": "Unknown Server Error" })
		
		
func comment_fan_moment(comment_data: Dictionary) -> void:
	# Prepare the HTTP request and associated resources.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	CommentFanMoment = prepared_http_req.request
	wrCommentFanMoment  = prepared_http_req.weakref
	
	# Connect the callback function to the request_completed signal.
	var _like: int = CommentFanMoment.request_completed.connect(_on_CommentFanMoment_request_completed)
	
	# Prepare the payload with the image data.
	var payload: Dictionary = comment_data
	
	# Specify the request URL for profile picture upload.
	var request_url: String = BKMREngine.host + "/api/social/fanmoments/comment"
	
	# Send a POST request to upload the profile picture.
	BKMREngine.send_post_request(CommentFanMoment, request_url, payload)
	
	
func _on_CommentFanMoment_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Free resources associated with the HTTP request.
	BKMREngine.free_request(wrCommentFanMoment, CommentFanMoment)
	
	# Parse the response body as a JSON dictionary.
	var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
	if json_body != null:
	# Check if the upload was successful based on the JSON response.
		if status_check:
			if json_body.has("success"):
				comment_fan_moment_complete.emit(json_body)
			elif json_body.has("error"):
				comment_fan_moment_complete.emit(json_body.error)
			else:
				comment_fan_moment_complete.emit({ "error": "Unknown Server Error" })
		else:
			comment_fan_moment_complete.emit({ "error": "Unknown Server Error" })
	else:
		comment_fan_moment_complete.emit({ "error": "Unknown Server Error" })
		
