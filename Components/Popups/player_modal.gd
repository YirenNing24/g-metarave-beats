extends Control

@onready var player_name: Label = %PlayerName
@onready var player_rank: Label = %PlayerRank
@onready var player_level: Label = %Level
@onready var status: Label = %Status
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var follow_unfollow_button: TextureButton =  %FollowUnfollowButton
@onready var follow_button_label: Label = %FollowLabel
@onready var follow_status_label: Label = %FollowStatusLabel

var player_profile: Dictionary
var player_username: String

func _ready() -> void:
	BKMREngine.Social.view_profile_complete.connect(_on_stat_display)

func _on_stat_display() -> void:
	player_profile = BKMREngine.Social.player_profile
	
	if player_profile:
		print(player_profile, " anu po laman po")
		var playerStats: String = player_profile.playerStats
		var player_stats: Dictionary = JSON.parse_string(playerStats)
		
		if player_profile.followsUser:
			follow_button_label.text = "UNFOLLOW"
			follow_unfollow_button.modulate = "#89898994"
		else:
			follow_button_label.text = "FOLLOW"
			follow_unfollow_button.modulate = "#ffffff"
			
		if player_profile.followedByUser:
			follow_status_label.text = "Follows you!"
			follow_button_label.text = "FOLLOW BACK"
			follow_unfollow_button.modulate = "#ffffff"
		#else:
			#follow_status_label.text = ""
			#follow_button_label.text = "FOLLOW"
			#follow_unfollow_button.self_modulate = "#ffffff"
			
		player_name.text = player_profile.username
		player_level.text = str(player_stats.level)
		player_rank.text = player_stats.rank
		
		player_username = player_profile.username
		
		#wallet_address.text = PLAYER.wallet_address

func _on_visibility_changed() -> void:
	if visible:
		animation_player.play("fade-in")

func _on_follow_unfollow_button_pressed() -> void:
	if player_profile.followsUser:
		follow_unfollow_button.disabled = true
		BKMREngine.Social.unfollow(BKMREngine.Auth.logged_in_player, player_username)
		await BKMREngine.Social.unfollow_complete
		player_profile.followsUser = false
		follow_button_label.text = "FOLLOW"
		follow_unfollow_button.self_modulate = "#ffffff"
		follow_unfollow_button.disabled = false
	else:
		follow_unfollow_button.disabled = true
		BKMREngine.Social.follow(BKMREngine.Auth.logged_in_player, player_username)
		await BKMREngine.Social.follow_complete
		player_profile.followsUser = true
		follow_button_label.text = "UNFOLLOW"
		follow_unfollow_button.self_modulate = "#89898994"
		follow_unfollow_button.disabled = false
