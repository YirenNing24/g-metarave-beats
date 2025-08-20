extends Control

signal leaderboard_loading
signal leaderboard_loading_complete
const leaderboard_entry: PackedScene = preload("res://Components/Leaderboard/leaderboard_entry.tscn")

#region variables
@onready var personal_rank: Label = %PersonalRank
@onready var personal_name: Label = %PersonalName
@onready var personal_score: Label = %PersonalScore

@onready var background_texture: TextureRect = %BackgroundTexture
@onready var song_bg: TextureRect = %SongBG

@onready var period_option: OptionButton = %PeriodOption
@onready var difficulty_option: OptionButton = %DifficultyOption
@onready var leaderboard_entry_container: VBoxContainer = %LeaderboardEntryContainer

var song_matches: Array[Panel] = []
var songs: Array[Node]

var current_song_title: String
var song_title: String

var song_difficulty: String
var period: String


#endregion
func open_laderboard(current_song: String, difficulty: String) -> void:
	%SongName.text = current_song
	song_title = current_song
	song_difficulty = difficulty
	classic_mode_selected()
	visible = true
	
	
func change_difficulty_option_selected() -> void:
	var difficulty_map: Dictionary[String, int]= {
		"easy": 0,
		"medium": 1,
		"hard": 2,
		"ultra hard": 3
	}

	if song_difficulty in difficulty_map:
		%DifficultyOption.selected = difficulty_map[song_difficulty]
	
	
func _on_close_button_pressed() -> void:
	visible = false
	
	
#region init_ready 
func _ready() -> void:
	%PlayerRank.text = PLAYER.player_rank
	%PlayerName.text = PLAYER.username
	
	add_filter_options()
	connect_signals()


func connect_signals() -> void: 
	BKMREngine.Leaderboard.get_classic_leaderboard_complete.connect(on_get_classic_leaderboard_complete)
#endregion


#region init_filters
func add_filter_options() -> void:
	add_period_option()
	add_difficulty_option()
	
func add_period_option() -> void:
	period_option.add_item("Daily")
	period_option.add_item("Weekly")
	period_option.add_item("Monthly")

func add_difficulty_option() -> void:
	difficulty_option.add_item("Easy")
	difficulty_option.add_item("Medium")
	difficulty_option.add_item("Hard")
	difficulty_option.add_item("Ultra Hard")
#endregion



func _on_period_option_item_selected(_index: int) -> void:
	if song_title == "":
		return
	game_mode_classic_selected()
	
	
func _on_difficulty_option_item_selected(index: int) -> void:
	song_difficulty = difficulty_option.get_item_text(index)
	if song_title == "":
		return
	game_mode_classic_selected()
	
	
func game_mode_classic_selected() -> void:
	if song_title == "":
		return
	
	classic_mode_selected()
	
	
func classic_mode_selected() -> void:
	if song_title == "":
		return
	clear_entries()
	change_difficulty_option_selected()
	leaderboard_loading.emit()
	var selected_period: int = period_option.selected
	period = period_option.get_item_text(selected_period)
	
	# Ensure songName is correctly formatted
	var song_name: String = song_title.strip_edges()# Trim whitespace
	song_name = song_name.replace(" ", "%20") # Encode spaces as %20 for URLs
	
	# Ensure difficulty matches database format (all lowercase)
	var song_difficulty_fixed: String = song_difficulty.to_lower().replace(" ", "%20")
	
	# Ensure song_bg_name formatting remains correct
	var song_bg_name: String = song_title.replace(" ", "_")

	# Call the leaderboard with properly formatted strings
	BKMREngine.Leaderboard.get_classic_leaderboard(song_name, song_difficulty_fixed, period)
	animate_song_bg(song_bg_name)

	
	
func game_mode_versus_selected() -> void:
	pass
	
	
func set_personal_entry(leaderboard: Array) -> void:
	personal_rank.text = ""
	personal_name.text = ""
	personal_score.text = ""
	for entry: Dictionary in leaderboard:
		if entry.username == PLAYER.username:
			var rank: String = str(leaderboard.find(entry) + 1)
			personal_rank.text = rank
			personal_name.text = entry.username
			@warning_ignore("unsafe_call_argument")
			personal_score.text = str(int(entry.score))
			%PlayerScore.text = personal_score.text 
			break
	
	
func animate_song_bg(song_name: String) -> void:
	var song_bg_texture_name: String = song_name.replace(" ", "_").to_lower() + "_bg.png"
	var song_bg_texture: Texture = load("res://UITextures/BGTextures/Leaderboard/" + song_bg_texture_name)
	
	var bg_texture_name: String = song_name.to_lower()
	var bg_texture: Texture = load("res://UITextures/BGTextures/Leaderboard/" + bg_texture_name + "_leaderboard_bg.png")
	
	background_texture.texture = bg_texture 
	song_bg.texture = song_bg_texture
	%AnimationPlayer.play("SongBG")
	
#endregion


#region http_api_calls
func on_get_classic_leaderboard_complete(weekly_lederboard: Array) -> void:
	for entry: Dictionary in weekly_lederboard:
		var rank: String = str(weekly_lederboard.find(entry) + 1)
		var entry_leaderboard: Control = leaderboard_entry.instantiate()
		entry_leaderboard.name = entry.username
		entry_leaderboard.get_node("Panel/HBoxContainer/VBoxContainer/Rank").text = rank
		entry_leaderboard.get_node("Panel/HBoxContainer/HBoxContainer/HBoxContainer/PlayerName").text = entry.username
		@warning_ignore("unsafe_call_argument")
		entry_leaderboard.get_node("Panel/HBoxContainer/VBoxContainer3/Score").text = str(int(entry.score))
		entry_leaderboard.player_profile_button_pressed.connect(_on_player_profile_button_pressed)
		if not entry.image.is_empty():
			entry_leaderboard.set_picture(entry.image)
		leaderboard_entry_container.add_child(entry_leaderboard)
	set_personal_entry(weekly_lederboard)
	leaderboard_loading_complete.emit()
	
	
func _on_player_profile_button_pressed(username: String, texture: Texture) -> void:
	if username == PLAYER.username:
		return
	%PlayerModal._on_leaderboard_view_profile_pressed(username, texture)

#endregion


#region utilities
func clear_entries() -> void:
	if leaderboard_entry_container.get_child_count() != 0:
		for entry: Control in leaderboard_entry_container.get_children():
			entry.queue_free()
#endregion
