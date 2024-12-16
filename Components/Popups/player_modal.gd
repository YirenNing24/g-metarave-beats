extends Control

# UI Elements
const badge_scene: PackedScene = preload("res://Components/MyProfile/badge.tscn")
const liker_slot_scene: PackedScene = preload("res://Components/Moments/liker_slot.tscn")

const followed_color: Color = Color("#89898994")
const default_color: Color = Color("#ffffff")

@onready var player_name: Label = %PlayerName
@onready var player_rank: Label = %PlayerRank
@onready var player_level: Label = %Level
@onready var status: Label = %Status
@onready var follow_unfollow_button: TextureButton = %FollowUnfollowButton
@onready var follow_button_label: Label = %FollowLabel
@onready var follow_status_label: Label = %FollowStatusLabel

# Modals
@onready var view_player_picture: Control = %ViewPlayerPicture
@onready var profile_pic: TextureRect = %ProfilePic

# Variables

var is_following_button_pressed: bool = false
var is_followers_button_pressed: bool = false

var player_username: String
var profile_player: Dictionary


# This function is called when the node is ready to perform initial setup. In this case, it connects``
func _ready() -> void:
	signal_connect()


func signal_connect() -> void:
	BKMREngine.Social.view_profile_complete.connect(_on_stat_display)
	BKMREngine.Social.follow_complete.connect(_on_follow_complete)
	BKMREngine.Social.unfollow_complete.connect(_on_unfollow_complete)
	BKMREngine.Profile.get_player_profile_pic_complete.connect(_on_get_player_profile_pic_complete)
	BKMREngine.Social.get_followers_following_count_complete.connect(_get_followers_following_count_complete)
	BKMREngine.Social.get_followers_following_complete.connect(_get_followers_following_complete)
	
	
# Handle the display of player statistics.
func _on_stat_display(player_profile: Dictionary) -> void:
	profile_player = player_profile
	# Check if the player profile is available
	if player_profile:
		var player_stats: Dictionary = player_profile.playerStats
		
		# Update follow/unfollow button and label based on user relationships
		if player_profile.followsUser:
			follow_button_label.text = "UNFOLLOW"
			follow_unfollow_button.modulate = "#89898994"
		else:
			follow_button_label.text = "FOLLOW"
			follow_unfollow_button.modulate = "#ffffff"
			
		# Update follow status label for mutual follows
		if player_profile.followedByUser and player_profile.followsUser:
			follow_button_label.text = "UNFOLLOW"
			follow_unfollow_button.modulate = "#89898994"
			
		elif player_profile.followedByUser:
			follow_status_label.text = "Follows you!"
			
			follow_button_label.text = "FOLLOW BACK"
			follow_unfollow_button.modulate = "#ffffff"
		
		# Display player information in the UI
		player_name.text = player_profile.username
		player_level.text = str(player_stats.level)
		player_rank.text = player_stats.rank
	#_on_get_preference_complete(player_profile)
	_on_chat_box_view_profile_pressed()


func _on_chat_box_view_profile_pressed() -> void:
	visible = true
	BKMREngine.Profile.get_player_profile_pic(%PlayerName.text)
	BKMREngine.Social.get_following_followers_count(%PlayerName.text)
	
	
	
func _on_follow_unfollow_button_pressed() -> void:
	if profile_player.followsUser:
		follow_unfollow_button.disabled = true
		BKMREngine.Social.unfollow(%PlayerName.text)
	else:
		follow_unfollow_button.disabled = true
		BKMREngine.Social.follow(%PlayerName.text)


func _on_follow_complete(message: Dictionary) -> void:
	if message.has("error"):
		follow_unfollow_button.button_pressed = false
	else:
		follow_button_label.text = "UNFOLLOW"
		follow_unfollow_button.modulate = "#89898994"
		profile_player.followsUser = true
	follow_unfollow_button.disabled = false
	
	
func _on_unfollow_complete(message: Dictionary) -> void:
	if message.has("error"):
		follow_unfollow_button.button_pressed = true
	else:
		follow_button_label.text = "FOLLOW"
		follow_unfollow_button.modulate = "#ffffff"
		profile_player.followsUser = false
	follow_unfollow_button.disabled = false
	
	
func _on_profile_pic_options_button_pressed() -> void:
	if view_player_picture.profile_pics_data.size() == 0:
		return
	view_player_picture.visible = true


func _on_get_player_profile_pic_complete(profile_pics: Variant) -> void:
	if typeof(profile_pics) != TYPE_ARRAY:
		return
	else:
		if profile_pics.is_empty():
			profile_pic.texture = preload("res://UITextures/Icons/change_pic_icon.png")
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
					view_player_picture.profile_pics_data = profile_pics
					view_player_picture.display_picture()
		

func _on_panel_2_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if visible:
			visible = false


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


func _get_followers_following_count_complete(followers_following_count: Dictionary) -> void:
	print("teti: ", followers_following_count)
	if not followers_following_count.is_empty() and not followers_following_count.has("error"):
		if player_name.text != PLAYER.username:
			%FollowingButton.text = str(followers_following_count.followingCount) + " " + "Following"
			%FollowersButton.text = str(followers_following_count.followerCount) + " " + "Followers"


func _on_following_button_pressed() -> void:
	BKMREngine.Social.get_following_followers(player_name.text)
	is_following_button_pressed = true


func _on_followers_button_pressed() -> void:
	BKMREngine.Social.get_following_followers(player_name.text)
	is_followers_button_pressed = true
