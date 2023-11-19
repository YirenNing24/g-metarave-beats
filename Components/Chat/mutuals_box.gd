extends Control

# SIGNALS
signal slide_pressed(is_opened: bool)
signal view_profile_pressed(player_profile: Dictionary)
signal chat_button_pressed(private_message: Array, conversing_username: String)

# BUTTON FOR TOGGLING THE MUTUALS WINDOW TO CLOSE
@onready var slide_button: TextureButton = $SlideButton

# SCROLL CONTAINER AND SCROLL BAR FOR MUTUALS WINDOW
@onready var mutual_scroll: ScrollContainer = %MutualsScroll
@onready var mutual_vbox: VBoxContainer = %MutualsVBox
@onready var mutual_v_scroll: VScrollBar = mutual_scroll.get_v_scroll_bar()

# INSTANCE SCENE COMPONENTS FOR MUTUALS WINDOW
var mutual_slot: PackedScene = preload("res://Components/Chat/mutual_slot.tscn")

# GLOBAL SCENE VARIABLES
var username: String = PLAYER.username
var conversing_username: String
var is_opened: bool = false

var private_messages: Array
var mutuals_list: Array

func _ready() -> void:
	BKMREngine.Social.get_mutual()
	await BKMREngine.Social.get_mutual_complete
	mutuals_list = BKMREngine.Social.mutual_followers
	populate_mutuals_list()
	
	var _v_scroll: int = mutual_v_scroll.changed.connect(_on_new_all_message_received)
	
func populate_mutuals_list() -> void:
	for mutuals: Dictionary in mutuals_list:
		var slot_mutuals: Control = mutual_slot.instantiate()
		var playerStats: String = mutuals.playerStats
		var player_stats: Dictionary = JSON.parse_string(playerStats)
		
		var level: String = str(player_stats.level)
		conversing_username = mutuals.username
		slot_mutuals.get_node('Panel/VBoxContainer/VBoxContainer/UsernameLabel').text = mutuals.username
		slot_mutuals.get_node('Panel/VBoxContainer/HBoxContainer/HBoxContainer2/LevelLabel').text = "Level: " + level
		slot_mutuals.get_node('Panel/VBoxContainer/HBoxContainer/HBoxContainer2/RankLabel').text = player_stats.rank
		slot_mutuals.get_node('Panel/VBoxContainer/HBoxContainer/HBoxContainer2/HBoxContainer/HBoxContainer/ChatButton').pressed.connect(_on_chat_button_pressed)
		mutual_vbox.add_child(slot_mutuals)
	
func _on_slide_button_pressed() -> void:
	slide_pressed.emit(is_opened)
	
func _on_new_all_message_received() -> void:
	mutual_scroll.scroll_vertical = mutual_v_scroll.max_value
	
func _on_view_profile(username: String) -> void:
	BKMREngine.Social.view_profile(username)
	view_profile_pressed.emit(BKMREngine.Social.player_profile)

func _on_chat_button_pressed() -> void:
	BKMREngine.Chat.get_private_inbox_data(conversing_username)
	await BKMREngine.Chat.get_inbox_messages_complete
	chat_button_pressed.emit(BKMREngine.Chat.private_messages, conversing_username)
