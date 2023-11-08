extends Control

@onready var player_name: Label = %PlayerName
@onready var player_rank: Label = %PlayerRank
@onready var player_level: Label = %Level
@onready var status: Label = %Status

var player_profile: Dictionary

func _ready() -> void:
	BKMREngine.Social.view_profile_complete.connect(_on_stat_display)

func _on_stat_display() -> void:
	player_profile = BKMREngine.Social.player_profile
	if player_profile:
		print(player_profile, " anu po laman po")
		var playerStats: String = player_profile.playerStats
		var player_stats: Dictionary = JSON.parse_string(playerStats)
		
		player_name.text = player_profile.username
		player_level.text = str(player_stats.level)
		player_rank.text = player_stats.rank
	#wallet_address.text = PLAYER.wallet_address

func _on_visibility_changed() -> void:
	if visible:
		%AnimationPlayer.play("fade-in")
