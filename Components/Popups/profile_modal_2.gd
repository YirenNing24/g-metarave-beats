extends Control

signal wallet_address_copied(wallet_address: String)
#signal settings_screen_button_pressed
signal picture_processing_complete


const CONTAINERS_PATH: String = "BackgroundTexture/PlayerContainer/TextureRect/VBoxContainer"
const plugin_name: String = "GodotGetImage"

const stalker_slot_scene: PackedScene = preload("res://Components/MyProfile/stalker.tscn")
const liker_slot_scene: PackedScene = preload("res://Components/Moments/liker_slot.tscn")
const history_slot_scene: PackedScene = preload("res://Components/MyProfile/history.tscn")

var get_image: Object

var profile_buttons: Array[Node]
var profile_containers: Array[Node]

var is_upload: bool = false
var is_following_button_pressed: bool = false
var is_followers_button_pressed: bool = false

var is_player_modal_active: bool = false

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


func _ready() -> void:
	add_buttons_to_array()
	connect_signals()
	stat_display()
	load_plugin()
	
	
func connect_signals() -> void:
	for button: TextureButton in profile_buttons:
		var _t: int = button.pressed.connect(_on_button_pressed.bind(button.name))
	BKMREngine.Social.view_profile_complete.connect(_on_view_profile_complete)
	BKMREngine.Score.get_retrieve_history_complete.connect(_on_get_retrieve_history)
	BKMREngine.Social.get_followers_following_complete.connect(_get_followers_following_complete)
	
	
func _on_view_profile_complete(profile_data: Dictionary) -> void:
	if profile_data.has("error"):
		print(profile_data.error)#error handling
		return
	if profile_data.username != PLAYER.username:
		return
	
	var stalkers: Array = profile_data.stalkers
	var followers_following: Dictionary = profile_data.followersFollowing
	
	_on_get_stalkers_complete(stalkers)
	_on_get_profile_pic_complete(profile_data.profilePics)
	_get_followers_following_complete(followers_following)
	
	
	
func load_plugin() -> void:
	if Engine.has_singleton(plugin_name):
		get_image = Engine.get_singleton(plugin_name)
		
	else:
		print("Could not load plugin: ", plugin_name)
		
	if get_image:
		var options: Dictionary[String, Variant] = {
		"image_height" : 200,
		"image_width" : 100,
		"keep_aspect" : true,
		"image_format" : "png"
	}
		get_image.setOptions(options)
		plugin_signal_connect()


func _on_get_retrieve_history(scores: Array) -> void:
	for history: Control in %HistoryContainer.get_children():
		history.queue_free()
	
	
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
	
	
func plugin_signal_connect() -> void:
	match OS.get_name():
		"Windows":
			return
		"Linux":
			return
	get_image.image_request_completed.connect(_on_image_request_completed)
	get_image.error.connect(_on_get_image_error)
	get_image.permission_not_granted_by_user.connect(_on_permission_not_granted_by_user)
	
	
func _on_image_request_completed(object_image: Dictionary) -> void:
	if len(object_image.values()) != 1:
			return
	for image_buffer: PackedByteArray in object_image.values():
		var image: Image = Image.new()
		var error: Error = image.load_png_from_buffer(image_buffer)
		if error != OK:
			print("Error loading image", error)
		else:
			BKMREngine.Profile.upload_profile_pic(image_buffer)
			print("We are now loading texture... ")
			var uploaded_pic: Texture =  ImageTexture.create_from_image(image)
			%ProfilePic.texture = uploaded_pic
			%ProfilePicSocial.texture = uploaded_pic
			%DPPanel.visible = false
			is_upload = true
	BKMREngine.Profile.get_profile_pic()
	
	
func _on_get_image_error(_error: String) -> void:
	pass
	
	
func _on_permission_not_granted_by_user() -> void:
	# Set the plugin to ask user for permission again
	get_image.resendPermission()
	
	
func stat_display() -> void:
	#Player profile
	%PlayerName.text = BKMREngine.Auth.logged_in_player
	%Level.text = str(PLAYER.level)
	%PlayerRank	.text = PLAYER.player_rank
	%WalletAddress.text = PLAYER.wallet_address
	#Social
	is_followers_button_pressed = true
	%SocialPlayerName.text = %PlayerName.text
	set_join_date()
	if %ProfilePic.texture != null:
		picture_processing_complete.emit()
	
	
func set_join_date() -> void:
	@warning_ignore("narrowing_conversion")
	var date: Dictionary = Time.get_datetime_dict_from_unix_time(PLAYER.signup_date / 1000)
	var month_name: String = month_names.get(date.month, "Unknown")
	var year: String = str(date.year)
	%JoinDate.text = "Joined " + str(month_name + " " + year)
	
	
func _on_get_stalkers_complete(stalkers_list: Array) -> void:
	if is_player_modal_active:
		return
		
	for stalker: Control in get_tree().get_nodes_in_group("StalkerSlot"):
		stalker.queue_free()
		
	var  stalker_slot: Control
	for stalker: Dictionary in stalkers_list:
		stalker_slot = stalker_slot_scene.instantiate()
		stalker_slot.on_stalker_button_pressed.connect(_on_stalker_button_pressed)
		if stalker.displayPic != null:
			stalker_slot.set_picture(stalker.displayPic, stalker.username)
		else:
			stalker_slot.set_picture("", stalker.username)
		stalker_slot.set_origin("Profile")
		%StalkerContainer.add_child(stalker_slot)
	
	
func _on_stalker_button_pressed(username: String, texture: Texture) -> void:

	is_player_modal_active = true
	%PlayerModal.visible = true
	%PlayerModal._on_leaderboard_view_profile_pressed(username, texture)
	
	
func _get_followers_following_complete(followers_following: Dictionary) -> void:
	if not followers_following.has("error"):
		if is_player_modal_active:
			return

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
	if is_player_modal_active:
		return
	reset_display()

	var follower_slot: Control
	for follower: Dictionary in followers:
		if follower.username == null:
			return
		follower_slot = liker_slot_scene.instantiate()
		follower_slot.on_liker_button_pressed.connect(_on_liker_button_pressed)
		follower_slot.slot_data(follower, "Profile")
		%FollowersFollowingContainer.add_child(follower_slot)
	
	
	
func populate_following(followings: Array) -> void:
	if is_player_modal_active:
		return
	reset_display()
	var following_slot: Control
	for following: Dictionary in followings:
		if following.playerStats == null:
			return
		following_slot = liker_slot_scene.instantiate()
		following_slot.on_liker_button_pressed.connect(_on_liker_button_pressed)
		following_slot.slot_data(following, "Profile")
		%FollowersFollowingContainer.add_child(following_slot)
	
	
func _on_liker_button_pressed(username: String) -> void:
	is_player_modal_active = true
	%PlayerModal._on_leaderboard_view_profile_pressed(username, %ProfilePic.texture)
	
	
func _get_followers_following_count_complete(follower: int, following: int) -> void:
	if is_player_modal_active:
		return
	%FollowingButton.text = str(following) + " " + "Following"
	%FollowersButton.text = str(follower) + " " + "Followers"
		
		
func reset_display() -> void:
	if is_player_modal_active:
		return
	for child: Control in %FollowersFollowingContainer.get_children():
		child.queue_free()
		

func _on_get_profile_pic_complete(profile_pics: Variant) -> void:
	if is_player_modal_active:
		return
	if not profile_pics is Array or profile_pics.is_empty():
		return
	is_upload = true
	# Get the first profile picture
	var first_pic_data: String = profile_pics[0].profilePicture
	var image: Image = Image.new()
	# Convert JSON string to PackedByteArray and load image
	var display_image: PackedByteArray = JSON.parse_string(first_pic_data)
	if image.load_png_from_buffer(display_image) != OK:
		print("Error loading image")
		picture_processing_complete.emit()
		return
	# Create texture and update UI
	%ProfilePic.texture = ImageTexture.create_from_image(image)
	%ProfilePicSocial.texture = %ProfilePic.texture
	
	%ViewPicture.profile_pics_data = profile_pics
	%ViewPicture.display_picture()
	# Emit signal only once
	picture_processing_complete.emit()

	
func show_profile_modal() -> void:
	BKMREngine.Social.view_profile(PLAYER.username)
	visible = true
	
	
func add_buttons_to_array() -> void:
	profile_buttons = get_tree().get_nodes_in_group("ProfileButtons")
	profile_containers = get_tree().get_nodes_in_group("ProfileContainer")
	
	
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
	
	
func _on_visibility_changed() -> void:
	if visible:
		stat_display()
		%AnimationPlayer.play("fade-in")
		BKMREngine.Social.get_following_followers(%PlayerName.text)
	
	
func _on_close_button_pressed() -> void:
	visible = false
	is_player_modal_active = false


func _on_profile_pic_options_button_pressed() -> void:
	%DPPanel.visible = true
	
	
func _on_dp_panel_gui_input(event: InputEvent) -> void:
	if %DPPanel.visible == true:
		if event is InputEventMouseButton:
			%DPPanel.visible = false
	
	
func _on_see_profile_pic_button_pressed() -> void:
	if %ViewPicture.profile_pics_data.size() == 0:
		return
	%ViewPicture.visible = true
	
	
func _on_copy_button_pressed() -> void:
	var address_wallet: String = PLAYER.wallet_data.smartWalletAddress
	%AnimationPlayer.play("copy_button_pressed")
	DisplayServer.clipboard_set(address_wallet)
	wallet_address_copied.emit(address_wallet)


func _on_following_button_pressed() -> void:
	if %FollowingButton.text != "0 Following":
		BKMREngine.Social.get_following_followers(%PlayerName.text)
		is_following_button_pressed = true
		following_follower_buttons()


func _on_followers_button_pressed() -> void:
	BKMREngine.Social.get_following_followers(%PlayerName.text)
	is_followers_button_pressed = true
	following_follower_buttons()
	
	
func following_follower_buttons() -> void:
	%FollowersFollowingContainer.visible = true
	
	
func _on_logout_button_pressed() -> void:
	BKMREngine.Auth.logout_player()
	await BKMREngine.Auth.bkmr_logout_complete
	get_tree().quit()
	
	
func _on_player_modal_player_modal_close_button_press(_origin: String) -> void:
	is_player_modal_active = false


func _on_upload_profile_pic_button_pressed() -> void:
	#Select single images from gallery
	if get_image:
		get_image.getGalleryImage()
	else:
		print(plugin_name, " plugin not loaded!")
	
	
func _on_history_container_visibility_changed() -> void:
	for history: Control in %HistoryContainer.get_children():
		history.queue_free()
	BKMREngine.Score.retrieve_history(%PlayerName.text)


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


func format_created_at(date_string: String) -> String:
	var date: Dictionary = Time.get_datetime_dict_from_datetime_string(date_string, false)
	var month_name: String = month_names.get(date.month, "Unknown")
	
	var time: String = month_name + " " + str(date.day) + ", " + str(date.year)
	return time
