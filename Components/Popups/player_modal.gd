extends Control

# UI Elements
var badge_scene: PackedScene = preload("res://Components/MyProfile/badge.tscn")

const followed_color: Color = Color("#89898994")
const default_color: Color = Color("#ffffff")

@onready var player_name: Label = %PlayerName
@onready var player_rank: Label = %PlayerRank
@onready var player_level: Label = %Level
@onready var status: Label = %Status
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var follow_unfollow_button: TextureButton = %FollowUnfollowButton
@onready var follow_button_label: Label = %FollowLabel
@onready var follow_status_label: Label = %FollowStatusLabel


@onready var badge_container: HBoxContainer = %BadgeContainer
# Variables
var player_profile: Dictionary
var player_username: String


# This function is called when the node is ready to perform initial setup. In this case, it connects``
func _ready() -> void:
	# Connect signal for displaying player stats
	BKMREngine.Social.view_profile_complete.connect(_on_stat_display)

# Handle the display of player statistics.
func _on_stat_display() -> void:
	# Retrieve player stats from the player profile
	player_profile = BKMREngine.Social.player_profile
	
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
		
		player_username = player_profile.username
	
	if player_profile.username == "GreenPill":
		%ProfilePic.texture = load("res://UITextures/Bundles/green_pill.png")
	else:
		%ProfilePic.texture = load("res://UITextures/Bundles/beats_logo.png")
	_on_get_preference_complete()
	
func _on_get_preference_complete() -> void:
	
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
				
# Handle visibility changes for the control.
func _on_visibility_changed() -> void:
	# Play fade-in animation when the control becomes visible
	if visible:
		animation_player.play("fade-in")

# Handle follow/unfollow button press.
func _on_follow_unfollow_button_pressed() -> void:
	if player_profile.followsUser:
		follow_unfollow_button.disabled = true
		BKMREngine.Social.unfollow(BKMREngine.Auth.logged_in_player, player_username)
		await BKMREngine.Social.unfollow_complete
		player_profile.followsUser = false
		follow_button_label.text = "FOLLOW"
		follow_unfollow_button.modulate = "#ffffff"
		follow_unfollow_button.disabled = false
	else:
		follow_unfollow_button.disabled = true
		BKMREngine.Social.follow(BKMREngine.Auth.logged_in_player, player_username)
		await BKMREngine.Social.follow_complete
		player_profile.followsUser = true
		follow_button_label.text = "UNFOLLOW"
		follow_unfollow_button.modulate = "#89898994"
		follow_unfollow_button.disabled = false
