extends Control

# UI Elements
var badge_scene: PackedScene = preload("res://Components/MyProfile/badge.tscn")

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

@onready var badge_container: HBoxContainer = %BadgeContainer
# Variables

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
	_on_get_preference_complete(player_profile)
	_on_chat_box_view_profile_pressed()


func _on_chat_box_view_profile_pressed() -> void:
	
	BKMREngine.Profile.get_player_profile_pic(%PlayerName.text)
	visible = true
	
	
func _on_get_preference_complete(player_profile: Dictionary) -> void:
	var soul_data: Dictionary = player_profile.userSoul
	for badge: Control in badge_container.get_children():
		badge.queue_free()
	if !soul_data.is_empty():
		var badge_created: bool = false
		var soul_data_ownership: Array = soul_data.ownership
		var soul_data_horoscope_match: Array = soul_data.horoscopeMatch
		var soul_data_animal_match: Array = soul_data.animalMatch
		var soul_data_weekly_first: Array = soul_data.weeklyFirst
	
		for card: String in soul_data_ownership:
			if "No Doubt" in card and not badge_created:
				var badge: Control = badge_scene.instantiate()
				badge.get_node("Panel/BadgeIcon").texture = preload("res://UITextures/BadgeTextures/x_in_owner_badge.png")
				badge_container.add_child(badge)
				badge_created = true  # Set the flag to true to indicate a badge has been created
				break  # Exit the loop since we only need one badge
		for card: String in soul_data_horoscope_match:
			if "No Doubt" in card:
				var badge: Control = badge_scene.instantiate()
				badge.get_node("Panel").modulate = "a8923e"
				badge.get_node("Panel/BadgeIcon").texture = preload("res://UITextures/BadgeTextures/x_in_capricorn.png")
				badge_container.add_child(badge)
				badge_created = true  # Set the flag to true to indicate a badge has been created
				break  # Exit the loop since we only need one badge
		for card: String in soul_data_animal_match:
			if "No Doubt" in card:
				var badge: Control = badge_scene.instantiate()
				badge.get_node("Panel").modulate = "46ff45"
				badge.get_node("Panel/BadgeIcon").texture = preload("res://UITextures/BadgeTextures/x_in_animal.png")
				badge_container.add_child(badge)
				badge_created = true  # Set the flag to true to indicate a badge has been created
				break  # Exit the loop since we only need one badge
		for song: String in soul_data_weekly_first:
			if "No Doubt" in song:
				var badge: Control = badge_scene.instantiate()
				badge.get_node("Panel").self_modulate = "8f8f8f"
				badge.get_node("Panel/BadgeIcon").texture = preload("res://UITextures/BadgeTextures/x:in_award.png")
				badge_container.add_child(badge)
				badge_created = true  # Set the flag to true to indicate a badge has been created
				break  # Exit the loop since we only need one badge

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
