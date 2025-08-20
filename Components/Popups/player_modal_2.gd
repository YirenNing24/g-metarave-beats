extends Control

signal wallet_address_copied(wallet_address: String)
signal player_modal_close_button_press(origin: String)

const badge_scene: PackedScene = preload("res://Components/MyProfile/badge.tscn")
const liker_slot_scene: PackedScene = preload("res://Components/Moments/liker_slot.tscn")
const stalker_slot_scene: PackedScene = preload("res://Components/MyProfile/stalker.tscn")
const history_slot_scene: PackedScene = preload("res://Components/MyProfile/history.tscn")

const month_names: Dictionary[int, String] = {
	Time.Month.MONTH_JANUARY: "January",
	Time.Month.MONTH_FEBRUARY: "February",
	Time.Month.MONTH_MARCH: "March",
	Time.Month.MONTH_APRIL: "April",
	Time.Month.MONTH_MAY: "May",
	Time.Month.MONTH_JUNE: "June",
	Time.Month.MONTH_JULY: "July",
	Time.Month.MONTH_AUGUST: "August",
	Time.Month.MONTH_SEPTEMBER: "September",
	Time.Month.MONTH_OCTOBER: "October",
	Time.Month.MONTH_NOVEMBER: "November",
	Time.Month.MONTH_DECEMBER: "December"
}

var profile_buttons: Array[Node]
var profile_containers: Array[Node]

const followed_color: Color = Color("#89898994")
const default_color: Color = Color("#ffffff")

# Variables
var is_following_button_pressed: bool = false
var is_followers_button_pressed: bool = false

var player_username: String
var profile_player: Dictionary

var smart_wallet_address: String


# This function is called when the node is ready to perform initial setup. In this case, it connects``
func _ready() -> void:
	add_buttons_to_array()
	signal_connect()
	
	
func add_buttons_to_array() -> void:
	profile_buttons = get_tree().get_nodes_in_group("ProfileButtons")
	profile_containers = get_tree().get_nodes_in_group("ProfileContainer")
	
	
func signal_connect() -> void:
	for button: TextureButton in profile_buttons:
		var _t: int = button.pressed.connect(_on_button_pressed.bind(button.name))
	BKMREngine.Social.view_profile_complete.connect(_on_view_profile_complete)
	BKMREngine.Social.follow_complete.connect(_on_follow_complete)
	BKMREngine.Social.unfollow_complete.connect(_on_unfollow_complete)
	BKMREngine.Score.get_retrieve_history_complete.connect(_on_get_retrieve_history)
	BKMREngine.Social.get_followers_following_complete.connect(_get_followers_following_complete)
	
	
func _on_button_pressed(button_name: String) -> void:
	for button: TextureButton in profile_buttons:
		var is_selected: bool = button.name == button_name
		button.get_node("TextureRect").visible = is_selected
		button.self_modulate = Color(1, 1, 1, 1) if is_selected else Color(1, 1, 1, 0)
	# Update the UI container text
	%ContainerName.text = button_name
	select_container(button_name)
	
	
func select_container(container_name: String) -> void:
	for container: Variant in profile_containers:
		container.visible = (container.name.replace("Container", "") == container_name)
	
	
func _on_get_retrieve_history(scores: Array) -> void:
	for score: Dictionary in scores:
		var history_slot: Control = history_slot_scene.instantiate()
		var result_label: Label = history_slot.get_node("Panel/HBoxContainer/VBoxContainer/ResultLabel")
		var score_label: Label = history_slot.get_node("Panel/HBoxContainer/VBoxContainer2/Score")
		var difficulty_label: Label = history_slot.get_node("Panel/HBoxContainer/VBoxContainer3/DifficultyLabel")
		var time_label: Label = history_slot.get_node("Panel/HBoxContainer/VBoxContainer4/TimeLabel")
		if not score.has("accuracy"):
			result_label.text = "FAILED"
		else:
			result_label.text = "COMPLETE" if score.finished else "GAME OVER"
			score_label.text = format_balance(str(score.score))
			difficulty_label.text = score.difficulty.capitalize() + " - " + score.songName
			if score.has("createdAt"):
				time_label.text = format_created_at(str(score.createdAt))
			#time_label.text = score.createdAt
		%HistoryContainer.add_child(history_slot)
	
	
# Handle the display of player statistics.
func _on_view_profile_complete(profile_data: Dictionary) -> void:
	if profile_data.has("error"):
		print(profile_data.error)
		return
	reset_display()
	# Exit early if the profile is the current player's
	if profile_data.username == PLAYER.username:
		return
	reset_labels()
	if not profile_data.has("error"):
		profile_player = profile_data
		@warning_ignore("unsafe_call_argument")
		_on_get_profile_pic_complete(profile_data.profilePics)
		@warning_ignore("unsafe_call_argument")
		_on_get_stalkers_complete(profile_data.stalkers)
		_update_follow_buttons(profile_data)
		_update_player_info(profile_data)
		@warning_ignore("unsafe_call_argument")
		_get_followers_following_complete(profile_data.followersFollowing)
	@warning_ignore("unsafe_call_argument")
	%WalletAddress.text = PLAYER.formatAddress(profile_data.smartWalletAddress)
	smart_wallet_address = profile_data.smartWalletAddress
	set_join_date()
	is_followers_button_pressed = true
	visible = true

	
func set_join_date() -> void:
	@warning_ignore("narrowing_conversion", "unsafe_call_argument")
	var date: Dictionary = Time.get_datetime_dict_from_unix_time(profile_player.signupDate / 1000)
	var month_name: String = month_names.get(date.month, "Unknown")
	var year: String = str(date.year)
	%JoinDate.text =  "Joined " + str(month_name + " " + year)
	
	
func reset_labels() -> void:
	%FollowingButton.text = str(0) + " " + "Following"
	%FollowersButton.text = str(0) + " " + "Followers"
	
	
func _update_follow_buttons(player_profile: Dictionary) -> void:
	# Update follow/unfollow button and label based on user relationships
	if player_profile.followsUser:
		_set_follow_button("UNFOLLOW", "#89898994")
	else:
		_set_follow_button("FOLLOW", "#ffffff")
		
	# Update follow status label for mutual follows
	if player_profile.followedByUser and player_profile.followsUser:
		_set_follow_button("UNFOLLOW", "#89898994")
	elif player_profile.followedByUser:
		_set_follow_button("FOLLOW BACK", "#ffffff")
	
	
func reset_display() -> void:
	%ProfilePic.texture = null
	%ProfilePicSocial.texture = null
	%ViewPicture.profile_pics_data = []
	
	
func _set_follow_button(label_text: String, color: String) -> void:
	%FollowLabel.text = label_text
	%FollowUnfollowButton.modulate = color
	
	
func _update_player_info(player_profile: Dictionary) -> void:
	var player_stats: Dictionary = player_profile.playerStats
	%PlayerName.text = player_profile.username
	%SocialPlayerName.text = player_profile.username
	@warning_ignore("unsafe_call_argument")
	%Level.text = str(int(player_stats.level))
	%PlayerRank.text = player_stats.rank
	
	
func _on_get_stalkers_complete(Stalkers: Array) -> void:
	for stalkers: Control in get_tree().get_nodes_in_group("StalkerSlot"):
		if stalkers.origin == "":
			stalkers.queue_free()
	var  stalker_slot: Control
	for stalker: Dictionary in Stalkers:
		stalker_slot = stalker_slot_scene.instantiate()
		stalker_slot.on_stalker_button_pressed.connect(_on_stalker_button_pressed)
		if stalker.displayPic != null:
			stalker_slot.set_picture(stalker.displayPic, stalker.username)
		%StalkerContainer.add_child(stalker_slot)
	
		
func _on_stalker_button_pressed(username: String, texture: Texture) -> void:
	_on_leaderboard_view_profile_pressed(username, texture)
	
	
	
	
	
func _on_leaderboard_view_profile_pressed(username: String, texture: Texture) -> void:
	%PlayerName.text = username
	%SocialPlayerName.text = username
	%ProfilePic.texture = texture
	%ProfilePicSocial.texture = texture
	BKMREngine.Social.get_following_followers(username)
	BKMREngine.Social.view_profile(username)
	BKMREngine.Social.save_stalkers(username)
	is_followers_button_pressed = true
	
	
	
func _on_chat_box_view_profile_pressed() -> void:
	visible = true
	
	
func _on_follow_unfollow_button_pressed() -> void:
	if profile_player.followsUser:
		%FollowUnfollowButton.disabled = true
		BKMREngine.Social.unfollow(%PlayerName.text)
	else:
		%FollowUnfollowButton.disabled = true
		BKMREngine.Social.follow(%PlayerName.text)
	
	
func _on_follow_complete(message: Dictionary) -> void:
	if message.has("error"):
		%FollowUnfollowButton.button_pressed = false
	else:
		%FollowLabel.text = "UNFOLLOW"
		%FollowUnfollowButton.modulate = "#89898994"
		profile_player.followsUser = true
	%FollowUnfollowButton.disabled = false
	
	
func _on_unfollow_complete(message: Dictionary) -> void:
	if message.has("error"):
		%FollowUnfollowButton.button_pressed = true
	else:
		%FollowLabel.text = "FOLLOW"
		%FollowUnfollowButton.modulate = "#ffffff"
		profile_player.followsUser = false
	%FollowUnfollowButton.disabled = false
	
	
func _on_profile_pic_options_button_pressed() -> void:
	if %ViewPicture.profile_pics_data.size() == 0:
		return
	%ViewPicture.visible = true


func _on_get_profile_pic_complete(profile_pics: Variant) -> void:
	if typeof(profile_pics) != TYPE_ARRAY:
		return
	else:
		if profile_pics.is_empty():
			%ProfilePic.texture = preload("res://UITextures/Icons/change_pic_icon.png")
		else:
			for pic: Dictionary in profile_pics:
				if %PlayerName.text == pic.userName:
					var image: Image = Image.new()
					var first_image: String = profile_pics[0].profilePicture
					var display_image: PackedByteArray = JSON.parse_string(first_image)
					var error: Error = image.load_png_from_buffer(display_image)
					if error != OK:
						print("Error loading image", error)
					else:
						var display_pic: Texture =  ImageTexture.create_from_image(image)
						%ProfilePic.texture = display_pic
						%ProfilePicSocial.texture = display_pic
					%ViewPicture.profile_pics_data = profile_pics
					%ViewPicture.display_picture()
		

func _on_panel_2_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if visible:
			visible = false
	
	
func _get_followers_following_complete(followers_following: Dictionary) -> void:
	if not followers_following.has("error"):
		var followerCount: int = 0
		var followingCount: int = 0

		# Count valid following entries
		var following: Array = followers_following.following
		for user: Dictionary in following:
			# Check if the dictionary contains a valid username.
			# If the username key exists and is not null, count it.
			if user.has("username") and user["username"] != null:
				followingCount += 1

		# Count valid follower entries
		var followers: Array = followers_following.followers
		for user: Dictionary in followers:
			if user.has("username") and user["username"] != null:
				followerCount += 1

		# Call your count completion function with the counts
		_get_followers_following_count_complete(followerCount, followingCount)
		# Populate lists based on the button pressed
		if is_following_button_pressed:
			populate_following(following)
			is_following_button_pressed = false
		elif is_followers_button_pressed:
			populate_followers(followers)
			is_followers_button_pressed = false
	
	
func populate_followers(followers: Array) -> void:
	var follower_slot: Control
	for follower: Dictionary in followers:
		if follower.username == null:
			return
		follower_slot = liker_slot_scene.instantiate()
		follower_slot.slot_data(follower, "Profile")
		%FollowersFollowingContainer.add_child(follower_slot)
	
	
func populate_following(followings: Array) -> void:
	clear_followers_following_container()
	for following: Dictionary in followings:
		if following.username == null:
			return
		var following_slot: Control = liker_slot_scene.instantiate()
		following_slot.slot_data(following, "Profile")
		%FollowersFollowingContainer.add_child(following_slot)
	
	
func clear_followers_following_container() -> void:
	for follower: Control in %FollowersFollowingContainer.get_children():
		follower.queue_free()
	
	
	
func _get_followers_following_count_complete(follower: int, following: int) -> void:
	%FollowingButton.text = str(following) + " " + "Following"
	%FollowersButton.text = str(follower) + " " + "Followers"
	
	
func _on_visibility_changed() -> void:
	if visible:
		clear_followers_following_container() 
		
	
	
func _on_close_button_pressed() -> void:
	player_modal_close_button_press.emit("child_modal")
	for player_modal: Control in get_tree().get_nodes_in_group("PlayerModal"):
		player_modal.visible = false
	
	
func _on_dp_panel_gui_input(event: InputEvent) -> void:
	if %DPPanel.visible == true:
		if event is InputEventMouseButton:
			%DPPanel.visible = false
	
	
func _on_see_profile_pic_button_pressed() -> void:
	if %ViewPicture.profile_pics_data.size() == 0:
		return
	%ViewPicture.visible = true
	
	
func _on_copy_button_pressed() -> void:
	%AnimationPlayer.play("copy_button_pressed")
	DisplayServer.clipboard_set(smart_wallet_address)
	wallet_address_copied.emit(smart_wallet_address)
	
	
func _on_followers_button_pressed() -> void:
	clear_followers_following_container()
	if %FollowersButton.text != "0 Followers":
		BKMREngine.Social.get_following_followers(%PlayerName.text)
		is_followers_button_pressed = true
		following_follower_buttons()
	
	
func _on_following_button_pressed() -> void:
	clear_followers_following_container()
	if %FollowingButton.text != "0 Following":
		BKMREngine.Social.get_following_followers(%PlayerName.text)
		is_following_button_pressed = true
		
	
func following_follower_buttons() -> void:
	%FollowersFollowingContainer.visible = true
	
	
func _on_history_container_visibility_changed() -> void:
	for history: Control in %HistoryContainer.get_children():
		history.queue_free()
	BKMREngine.Score.retrieve_history(%PlayerName.text)
	
	
func format_created_at(date_string: String) -> String:
	var date: Dictionary = Time.get_datetime_dict_from_datetime_string(date_string, false)
	var month_name: String = month_names.get(date.month, "Unknown")
	
	var time: String = month_name + " " + str(date.day) + ", " + str(date.year)
	return time
	
	
func format_balance(value: String) -> String:
	var parts: Array = value.split(".")
	var wholePart: String = parts[0]
	
	# Add commas for every three digits in the whole part.
	var formattedWholePart: String = ""
	var digitCount: int = 0
	for i: int in range(wholePart.length() - 1, -1, -1):
		formattedWholePart = wholePart[i] + formattedWholePart
		digitCount += 1
		if digitCount == 3 and i != 0:
			formattedWholePart = "," + formattedWholePart
			digitCount = 0
	return formattedWholePart
