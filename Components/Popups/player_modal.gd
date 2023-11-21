extends Control

# UI Elements
@onready var player_name: Label = %PlayerName
@onready var player_rank: Label = %PlayerRank
@onready var player_level: Label = %Level
@onready var status: Label = %Status
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var follow_unfollow_button: TextureButton = %FollowUnfollowButton
@onready var follow_button_label: Label = %FollowLabel
@onready var follow_status_label: Label = %FollowStatusLabel

# Variables
var player_profile: Dictionary
var player_username: String

# Initialization function called when the node is ready.
#
# This function is called when the node is ready to perform initial setup. In this case, it connects
# the signal for displaying player stats to the "_on_stat_display" function. When the player profile
# is viewed through the social system, the "_on_stat_display" function will be triggered to handle
# the display of player statistics.
#
# Parameters:
# - No explicit parameters are passed to this function.
#
# Returns:
# - This function does not return a value; it operates by connecting the signal for displaying player stats.
#
# Example usage:
# ```gdscript
# _ready()
# ```
func _ready() -> void:
	# Connect signal for displaying player stats
	BKMREngine.Social.view_profile_complete.connect(_on_stat_display)

# Handle the display of player statistics.
#
# This function is triggered when the player profile is viewed through the social system, 
# specifically after retrieving player stats. It updates UI elements based on the player's 
# stats and relationship status (follow/unfollow).
#
# Parameters:
# - No explicit parameters are passed to this function.
#
# Returns:
# - This function does not return a value; it operates by updating UI elements based on player stats.
#
# Example usage:
# ```gdscript
# _on_stat_display()
# ```
func _on_stat_display() -> void:
	# Retrieve player stats from the player profile
	player_profile = BKMREngine.Social.player_profile
	
	# Check if the player profile is available
	if player_profile:
		var playerStats: String = player_profile.playerStats
		var player_stats: Dictionary = JSON.parse_string(playerStats)
		
		# Update follow/unfollow button and label based on user relationships
		if player_profile.followsUser:
			follow_button_label.text = "UNFOLLOW"
			follow_unfollow_button.modulate = "#89898994"
		else:
			follow_button_label.text = "FOLLOW"
			follow_unfollow_button.modulate = "#ffffff"
			
		# Update follow status label for mutual follows
		if player_profile.followedByUser:
			follow_status_label.text = "Follows you!"
			follow_button_label.text = "FOLLOW BACK"
			follow_unfollow_button.modulate = "#ffffff"
		
		# Display player information in the UI
		player_name.text = player_profile.username
		player_level.text = str(player_stats.level)
		player_rank.text = player_stats.rank
		
		player_username = player_profile.username

# Handle visibility changes for the control.
#
# This function is triggered when the visibility of the control changes. 
# It plays a fade-in animation when the control becomes visible.
#
# Parameters:
# - No explicit parameters are passed to this function.
#
# Returns:
# - This function does not return a value; it operates by playing a fade-in animation.
#
# Example usage:
# ```gdscript
# _on_visibility_changed()
# ```
func _on_visibility_changed() -> void:
	# Play fade-in animation when the control becomes visible
	if visible:
		animation_player.play("fade-in")


# Handle follow/unfollow button press.
#
# This function is triggered when the follow/unfollow button is pressed. 
# It performs the appropriate action based on the current follow status:
# - If the user is already following, it unfollows the user.
# - If the user is not following, it follows the user.
#
# Returns:
# - This function does not return a value; it operates by updating the UI and making API calls.
#
# Example usage:
# ```gdscript
# _on_follow_unfollow_button_pressed()
# ```
func _on_follow_unfollow_button_pressed() -> void:
	# Handle follow/unfollow button press
	
	# Unfollow if the user is already following
	if player_profile.followsUser:
		follow_unfollow_button.disabled = true
		BKMREngine.Social.unfollow(BKMREngine.Auth.logged_in_player, player_username)
		await BKMREngine.Social.unfollow_complete
		player_profile.followsUser = false
		follow_button_label.text = "FOLLOW"
		follow_unfollow_button.modulate = "#ffffff"
		follow_unfollow_button.disabled = false
	else:
		# Follow if the user is not following
		follow_unfollow_button.disabled = true
		BKMREngine.Social.follow(BKMREngine.Auth.logged_in_player, player_username)
		await BKMREngine.Social.follow_complete
		player_profile.followsUser = true
		follow_button_label.text = "UNFOLLOW"
		follow_unfollow_button.modulate = "#89898994"
		follow_unfollow_button.disabled = false
