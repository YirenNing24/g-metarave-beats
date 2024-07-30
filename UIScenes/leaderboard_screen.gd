extends Control

#region variables
const leaderboard_entry: PackedScene = preload("res://Components/Leaderboard/leaderboard_entry.tscn")

@onready var game_mode_option: OptionButton = %GameModeOption
@onready var period_option: OptionButton = %PeriodOption
@onready var difficulty_option: OptionButton = %DifficultyOption
@onready var song_picker: LineEdit = %SongPicker

@onready var leaderboard_entry_container: VBoxContainer = %LeaderboardEntryContainer
@onready var song_list_container: VBoxContainer = %SongListContainer

@onready var personal_rank: Label = %PersonalRank
@onready var personal_name: Label = %PersonalName
@onready var personal_score: Label = %PersonalScore

@onready var background_texture: TextureRect = %BackgroundTexture
@onready var song_bg: TextureRect = %SongBG

var song_matches: Array[Panel] = []
var songs: Array[Node]

var current_song_title: String
var song_title: String

var song_difficulty: String
var period: String
#endregion

#region init_ready 
func _ready() -> void:
	%PlayerRank.text = PLAYER.player_rank
	%PlayerName.text = PLAYER.username
	
	songs = song_list_container.get_children()
	add_filter_options()
	connect_signals()


func _process(_delta: float) -> void:
	if difficulty_option.get_popup().visible or period_option.get_popup().visible or game_mode_option.get_popup().visible:
		song_list_container.visible = false
		
		
func connect_signals() -> void: 
	BKMREngine.Leaderboard.get_classic_leaderboard_complete.connect(on_get_classic_leaderboard_complete)

	for button: Button in get_tree().get_nodes_in_group("SongButtons"):
		var _connect: int = button.pressed.connect(on_song_button_pressed.bind(button.get_parent().name))
#endregion


#region init_filters
func add_filter_options() -> void:
	add_game_mode_option()
	add_period_option()
	add_difficulty_option()
	
	
func add_game_mode_option() -> void: 
	game_mode_option.add_item("Classic")
	#game_mode_option.add_item("Versus")
	
	
func add_period_option() -> void:
	period_option.add_item("Daily")
	period_option.add_item("Weekly")
	period_option.add_item("Monthly")


func add_difficulty_option() -> void:
	difficulty_option.add_item("Easy")
	difficulty_option.add_item("Normal")
	difficulty_option.add_item("Hard")
	difficulty_option.add_item("Ultra Hard")
#endregion


#region filter_button_signals
func _on_song_picker_focus_entered() -> void:
	song_list_container.visible = true
	
	
func _on_game_mode_option_item_selected(index: int) -> void:
	if song_title == "":
		return
	
	match index:
		0:
			game_mode_classic_selected()
		1:
			game_mode_versus_selected()
	
	
func _on_difficulty_option_item_selected(index: int) -> void:
	song_difficulty = difficulty_option.get_item_text(index)
	if song_title == "":
		return
		
	match game_mode_option.selected:
		0: # Classic
			game_mode_classic_selected()
		1: # Versus
			game_mode_versus_selected()


func _on_period_option_item_selected(_index: int) -> void:
	if song_title == "":
		return
		
	match game_mode_option.selected:
		0: # Classic
			game_mode_classic_selected()
		1: # Versus
			game_mode_versus_selected()
	
	
func _on_song_picker_text_changed(song_name: String) -> void:
	song_name = song_name.to_lower()
	if song_name == "":
		song_list_container.visible = true
	song_matches.clear()

	for song: Panel in songs:
		if song_name in song.name.to_lower():
			song_matches.append(song)
			
	for song: Panel in songs:
		if song in song_matches:
			song.show()
		else:
			song.hide()
			if song_name == "":
				song.show()
				
				
func on_song_button_pressed(song_name: String) -> void:
	if ui_changed_on_song_button_pressed(song_name) == false:
		return
	
	match game_mode_option.selected:
		0: # Classic
			game_mode_classic_selected()
		1: # Versus
			game_mode_versus_selected()
#endregion


#region filter_button_press_functions
func ui_changed_on_song_button_pressed(song_name: String) -> bool:
	if current_song_title == song_name:
		if song_picker.text == "":
			song_picker.text = song_name
		song_list_container.visible = false
		return false
		
	song_list_container.visible = false
	song_picker.text = song_name
	song_title = song_name
	current_song_title = song_name
	return true
	
	
func game_mode_classic_selected() -> void:
	if song_title == "":
		return
	
	classic_mode_selected()
	
	
func classic_mode_selected() -> void:
	
	if song_title == "":
		return
	clear_entries()
	
	var selected_difficulty: int = difficulty_option.selected
	song_difficulty = difficulty_option.get_item_text(selected_difficulty)
	var selected_period: int = period_option.selected
	period = period_option.get_item_text(selected_period)
	
	var song_name: String = song_title.replace(" ", "")
	
	
	BKMREngine.Leaderboard.get_classic_leaderboard(song_name, song_difficulty, period)
	animate_song_bg(song_name)
	
	
func game_mode_versus_selected() -> void:
	pass
	
	
func set_personal_entry(leaderboard: Array) -> void:
	for entry: Dictionary in leaderboard:
		if entry.username == PLAYER.username:
			var rank: String = str(leaderboard.find(entry) + 1)
			personal_rank.text = rank
			personal_name.text = entry.username
			personal_score.text = str(entry.score)
			%PlayerScore.text = str(entry.score)
			break
	
	
func animate_song_bg(song_name: String) -> void:
	var song_bg_texture_name: String = song_name.replace(" ", "_").to_lower() + "_bg.png"
	var song_bg_texture: Texture = load("res://UITextures/BGTextures/" + song_bg_texture_name)
	
	var bg_texture_name: String = song_name.to_lower()
	var bg_texture: Texture = load("res://UITextures/BGTextures/" + bg_texture_name + "_leaderboard_bg.png")
	
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
		entry_leaderboard.get_node("Panel/HBoxContainer/HBoxContainer/PlayerName").text = entry.username
		entry_leaderboard.get_node("Panel/HBoxContainer/VBoxContainer3/Score").text = str(entry.score)
		leaderboard_entry_container.add_child(entry_leaderboard)
	set_personal_entry(weekly_lederboard)
	
	
#endregion


#region utilities
func clear_entries() -> void:
	if leaderboard_entry_container.get_child_count() != 0:
		for entry: Control in leaderboard_entry_container.get_children():
			entry.queue_free()
#endregion


func _on_close_button_pressed() -> void:
	# Perform actions on close button press.
	BKMREngine.Auth.auto_login_player()

	# Update scene transition textures and load the main screen scene.
	LOADER.previous_texture = background_texture.texture
	LOADER.next_texture = preload("res://UITextures/BGTextures/main.png")
	var _change_scene: bool = await LOADER.load_scene(self, "res://UIScenes/main_screen.tscn")
