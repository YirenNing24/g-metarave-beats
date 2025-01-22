extends Control

const badge_scene: PackedScene = preload("res://Components/MyProfile/badge.tscn")
const liker_slot_scene: PackedScene = preload("res://Components/Moments/liker_slot.tscn")
const notification_scene: PackedScene = preload("res://Components/MyProfile/notification_slot.tscn")

# Player UI elements
@onready var player_name: Label =  %PlayerName
@onready var level: Label = %Level
@onready var player_rank: Label = %PlayerRank
@onready var wallet_address: Label = %WalletAddress
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var profile_pic: TextureRect = %ProfilePic
@onready var dp_option_panel: Panel = %DPOptionPanel
@onready var dp_panel: Panel = %DPPanel

@onready var moments: Control = %Moments
# Modals
@onready var view_picture: Control = %ViewPicture

#Get image plugin
var get_image: Object
const plugin_name: String = "GodotGetImage"

var is_upload: bool = false
var is_following_button_pressed: bool = false
var is_followers_button_pressed: bool = false


func _ready() -> void:
	signal_connect()
	stat_display()
	load_plugin()
	#get_notification()
	BKMREngine.Social.get_following_followers_count(player_name.text)
	
	
func signal_connect() -> void:
	#It connects the logout complete signal to the _on_Logout_Complete function for handling logout events.
	BKMREngine.Auth.bkmr_logout_complete.connect(_on_logout_complete)
	#BKMREngine.Profile.get_profile_pic_complete.connect(_on_get_profile_pic_complete)
	#BKMREngine.Profile.preference_get_complete.connect(_on_get_preference_complete)
	#BKMREngine.Profile.profile_pic_upload_complete.connect(_on_profile_pic_upload_complete)
	#BKMREngine.Profile.change_profile_pic_complete.connect(_on_change_profile_pic_complete)
	#BKMREngine.Social.get_followers_following_count_complete.connect(_get_followers_following_count_complete)
	#BKMREngine.Social.get_followers_following_complete.connect(_get_followers_following_complete)
	
	#BKMREngine.Notification.get_notifications_complete.connect(_on_get_notifications_complete)
	#BKMREngine.Reward.get_available_card_reward()
	
	
func get_notification() -> void:
	BKMREngine.Notification.get_notifications()
	var _timer: int = get_tree().create_timer(10.0).timeout.connect(get_notification)
	
	
#region UI Functions
# Display player statistics.
func stat_display() -> void:
	player_name.text = BKMREngine.Auth.logged_in_player
	level.text = str(PLAYER.level)
	player_rank.text = PLAYER.player_rank
	wallet_address.text = PLAYER.wallet_address
   

# Handle visibility change.
func _on_visibility_changed() -> void:
	if visible:
		BKMREngine.Social.get_following_followers_count(player_name.text)
		#BKMREngine.Profile.get_soul()
		if is_upload == false:
			BKMREngine.Profile.get_profile_pic()
		animation_player.play("fade-in")
		return
	else:
		reset_state()
	
	
# Handle logout button press.
func _on_logout_button_pressed() -> void:
	# Logout the player and quit the game
	BKMREngine.Auth.logout_player()
	await BKMREngine.Auth.bkmr_logout_complete
	get_tree().quit()
	
	
# Handle logout completion.
func _on_logout_complete() -> void:
	# Set textures for scene transition
	LOADER.previous_texture = load("res://UITextures/BGTextures/main.png")
	LOADER.next_texture = load("res://UITextures/BGTextures/blue_gradient.png")
#endregion


#region Get Image from Server
func load_plugin() -> void:
	if Engine.has_singleton(plugin_name):
		get_image = Engine.get_singleton(plugin_name)
		
	else:
		print("Could not load plugin: ", plugin_name)
		
	if get_image:
		var options: Dictionary = {
		"image_height" : 200,
		"image_width" : 100,
		"keep_aspect" : true,
		"image_format" : "png"
	}
		get_image.setOptions(options)
		plugin_signal_connect()


func plugin_signal_connect() -> void:
	match OS.get_name():
		"Windows":
			return
		"Linux":
			return
	get_image.image_request_completed.connect(_on_image_request_completed)
	get_image.error.connect(_on_get_image_error)
	get_image.permission_not_granted_by_user.connect(_on_permission_not_granted_by_user)
	
	
func _on_see_profile_pic_button_pressed() -> void:
	if view_picture.profile_pics_data.size() == 0:
		return
	animation_player.play_backwards('dp_options')
	view_picture.visible = true
	
	
func _on_upload_profile_pic_button_pressed() -> void:
	#Select single images from gallery
	if get_image:
		get_image.getGalleryImage()
	else:
		print(plugin_name, " plugin not loaded!")
#endregion


#region Get Image call backs
func _on_image_request_completed(object_image: Dictionary) -> void:
	#Object image is a dictionary of image packed byte array[]
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
			profile_pic.texture = uploaded_pic
			animation_player.play_backwards('dp_options')
			is_upload = true
	BKMREngine.Profile.get_profile_pic()
	
	
func _on_get_profile_pic_complete(profile_pics: Variant) -> void:
	if typeof(profile_pics) != TYPE_ARRAY:
		return
	is_upload = true
	for pic: Dictionary in profile_pics:
		var image: Image = Image.new()
		var first_image: String = profile_pics[0].profilePicture
		var display_image: PackedByteArray = JSON.parse_string(first_image)
		var error: Error = image.load_png_from_buffer(display_image)
		if error != OK:
			print("Error loading image", error)
		else:
			var display_pic: Texture =  ImageTexture.create_from_image(image)
			profile_pic.texture = display_pic
		view_picture.profile_pics_data = profile_pics
		view_picture.display_picture()
			
			
func _on_get_image_error(_error: String) -> void:
	pass
	
	
func _on_permission_not_granted_by_user() -> void:
	# Set the plugin to ask user for permission again
	get_image.resendPermission()
	
#endregion

#region Button callback functions
func _on_profile_pic_options_button_pressed() -> void:
	animation_player.play('dp_options')


func _on_dp_panel_gui_input(event: InputEvent) -> void:
	if dp_option_panel.visible == true:
		if event is InputEventMouseButton:
			animation_player.play_backwards('dp_options')
#endregion


#region View Pictuer callback
func _on_view_picture_view_picture_close() -> void:
	visible = true


func _on_profile_pic_upload_complete(_message: Dictionary) -> void:
	BKMREngine.Profile.get_profile_pic() 
	
	
func _on_change_profile_pic_complete(_message: Dictionary) -> void:
	BKMREngine.Profile.get_profile_pic()


func _on_my_profile_button_pressed() -> void:
	var _change_scene: bool = await LOADER.load_scene(self, "res://UIScenes/my_profile.tscn")


#func _on_get_preference_complete(soul_data: Dictionary) -> void:
	#for badge: Control in badge_container.get_children():
		#badge.queue_free()
	#if !soul_data.is_empty():
		#var badge_created: bool = false
		#var soul_data_ownership: Array = soul_data.ownership
		#var soul_data_horoscope_match: Array = soul_data.horoscopeMatch
		#var soul_data_animal_match: Array = soul_data.animalMatch
		#var soul_data_weekly_first: Array = soul_data.weeklyFirst
	#
		#for card: String in soul_data_ownership:
			#if "No Doubt" in card and not badge_created:
				#var badge: Control = badge_scene.instantiate()
				#badge.get_node("Panel/BadgeIcon").texture = preload("res://UITextures/BadgeTextures/x_in_owner_badge.png")
				#badge_container.add_child(badge)
				#badge_created = true  # Set the flag to true to indicate a badge has been created
				#break  # Exit the loop since we only need one badge
		#for card: String in soul_data_horoscope_match:
			#if "No Doubt" in card:
				#var badge: Control = badge_scene.instantiate()
				#badge.get_node("Panel").modulate = "a8923e"
				#badge.get_node("Panel/BadgeIcon").texture = preload("res://UITextures/BadgeTextures/x_in_capricorn.png")
				#badge_container.add_child(badge)
				#badge_created = true  # Set the flag to true to indicate a badge has been created
				#break  # Exit the loop since we only need one badge
		#for card: String in soul_data_animal_match:
			#if "No Doubt" in card:
				#var badge: Control = badge_scene.instantiate()
				#badge.get_node("Panel").modulate = "46ff45"
				#badge.get_node("Panel/BadgeIcon").texture = preload("res://UITextures/BadgeTextures/x_in_animal.png")
				#badge_container.add_child(badge)
				#badge_created = true  # Set the flag to true to indicate a badge has been created
				#break  # Exit the loop since we only need one badge
		#for song: String in soul_data_weekly_first:
			#if "No Doubt" in song:
				#var badge: Control = badge_scene.instantiate()
				#badge.get_node("Panel").self_modulate = "8f8f8f"
				#badge.get_node("Panel/BadgeIcon").texture = preload("res://UITextures/BadgeTextures/x:in_award.png")
				#badge_container.add_child(badge)
				#badge_created = true  # Set the flag to true to indicate a badge has been created
				#break  # Exit the loop since we only need one badge
	#
	
#func _on_my_notes_button_pressed() -> void:
	#pass
	##%MyNote.visible = true


func plugin_signal_disconnect() -> void:
	match OS.get_name():
		"Windows":
			return
		"Linux":
			return
	get_image.image_request_completed.disconnect(_on_image_request_completed)
	get_image.error.disconnect(_on_get_image_error)
	get_image.permission_not_granted_by_user.disconnect(_on_permission_not_granted_by_user)
	
	
func _on_notes_line_edit_text_changed(_new_text: String) -> void:
	pass # Replace with function body.


func _on_fan_moments_button_pressed() -> void:
	moments.user_profile_picture = profile_pic.texture
	moments.visible = true


func _on_moments_visibility_changed() -> void:
	if not %Moments.visible:
		plugin_signal_connect()
	else:
		plugin_signal_disconnect()
		

func _get_followers_following_count_complete(followers_following_count: Dictionary) -> void:
	if not followers_following_count.is_empty() and not followers_following_count.has("error"):
		if player_name.text == PLAYER.username:
			%FollowingButton.text = str(followers_following_count.followingCount) + " " + "Following"
			%FollowersButton.text = str(followers_following_count.followerCount) + " " + "Followers"


func _on_following_button_pressed() -> void:
	BKMREngine.Social.get_following_followers(player_name.text)
	is_following_button_pressed = true
	following_follower_buttons()


func _on_followers_button_pressed() -> void:
	BKMREngine.Social.get_following_followers(player_name.text)
	is_followers_button_pressed = true
	following_follower_buttons()


func following_follower_buttons() -> void:
	%FollowersFollowingContainer.visible = true
	%CloseButton.visible = true
	%HistoryContainer.visible = false
	%NotificationsContainer.visible = false
	


func _get_followers_following_complete(followers_following: Dictionary) -> void:
	if is_following_button_pressed:
		var following: Array = followers_following.following
		populate_following(following)
		is_following_button_pressed = false
	elif is_followers_button_pressed:
		var followers: Array = followers_following.followers
		populate_followers(followers)
		is_followers_button_pressed = false
		

func populate_followers(followers: Array) -> void:
	clear_followers_following_container()
	var follower_slot: Control
	for follower: Dictionary in followers:
		follower_slot = liker_slot_scene.instantiate()
		follower_slot.slot_data(follower, "Profile")
		%FollowersFollowingContainer.add_child(follower_slot)
	
	
func populate_following(followings: Array) -> void:
	clear_followers_following_container()
	var following_slot: Control
	for following: Dictionary in followings:
		following_slot = liker_slot_scene.instantiate()
		following_slot.slot_data(following, "Profile")
		%FollowersFollowingContainer.add_child(following_slot)
	
	
func clear_followers_following_container() -> void:
	for child: Control in %FollowersFollowingContainer.get_children():
		child.queue_free()



func _on_get_notifications_complete(notification_data: Array) -> void:
	var notification_slot: Control
	for notif: Dictionary in notification_data:
		var already_exists: bool = false
		
		# Check if a notification with the same ID already exists in the container
		for slots: Control in %NotificationsContainer.get_children():
			if slots.id == notif.id:
				already_exists = true
				break
		
		# Only add the new notification if it doesn't already exist
		if not already_exists:
			notification_slot = notification_scene.instantiate()
			notification_slot.notification_slot_data(notif)
			%NotificationsContainer.add_child(notification_slot)



func _on_copy_button_pressed() -> void:
	var address_wallet: String = PLAYER.wallet_data.smartWalletAddress
	DisplayServer.clipboard_set(address_wallet)


func _on_close_button_pressed() -> void:
	reset_state()
	
func reset_state() -> void:
	%HistoryContainer.visible = true
	
	%FollowersFollowingContainer.visible = false
	%NotificationsContainer.visible = false
	%CloseButton.visible = false


func _on_notifications_button_pressed() -> void:
	%HistoryContainer.visible = false
	
	%FollowersFollowingContainer.visible = false
	%NotificationsContainer.visible = true
	%CloseButton.visible = true
