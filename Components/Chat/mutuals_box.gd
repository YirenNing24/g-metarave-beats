extends Control

# SIGNALS
signal slide_pressed(is_opened: bool)
signal view_profile_pressed(player_profile: Dictionary)
signal chat_button_pressed(conversing_username: String)

# BUTTON FOR TOGGLING THE MUTUALS WINDOW TO CLOSE
@onready var slide_button: TextureButton = $SlideButton

# SCROLL CONTAINER AND SCROLL BAR FOR MUTUALS WINDOW
@onready var mutual_scroll: ScrollContainer = %MutualsScroll
@onready var mutual_vbox: VBoxContainer = %MutualsVBox

# INSTANCE SCENE COMPONENTS FOR MUTUALS WINDOW
var mutual_slot: PackedScene = preload("res://Components/Chat/mutual_slot.tscn")

# GLOBAL SCENE VARIABLES
var username: String = PLAYER.username
var conversing_username: String
var is_opened: bool = false

var private_messages: Array

# Initialization function called when the node is ready.
func _ready() -> void:
	# Get mutual followers from the social system
	BKMREngine.Social.get_mutual()
	BKMREngine.Social.get_mutual_complete.connect(populate_mutuals_list)
	# Populate the mutuals list in the UI
	call_deferred("set_status_and_activity")

func set_status_and_activity() -> void:
	BKMREngine.Social.set_status_online('main')
	BKMREngine.Social.get_mutual_status()
	
# Function to populate the mutuals list in the UI.
func populate_mutuals_list(mutuals_list: Array) -> void:
	# Iterate through mutual followers and create UI slots for each
	for mutuals: Dictionary in mutuals_list:
		var slot_mutuals: Control = mutual_slot.instantiate()
		var playerStats: String = mutuals.playerStats
		var player_stats: Dictionary = JSON.parse_string(playerStats)

		var level: String = str(player_stats.level)
		conversing_username = mutuals.username

		# Set UI labels with relevant information
		slot_mutuals.get_node('Panel/VBoxContainer/VBoxContainer/UsernameLabel').text = mutuals.username
		slot_mutuals.get_node('Panel/VBoxContainer/HBoxContainer/HBoxContainer2/LevelLabel').text = "Level: " + level
		slot_mutuals.get_node('Panel/VBoxContainer/HBoxContainer/HBoxContainer2/RankLabel').text = player_stats.rank
		# Connect the chat button signal to handle chat initiation
		slot_mutuals.get_node('Panel/VBoxContainer/HBoxContainer/HBoxContainer2/HBoxContainer/HBoxContainer/ChatButton').pressed.connect(_on_chat_button_pressed)
		# Add the UI slot to the VBox
		mutual_vbox.add_child(slot_mutuals)

# Function to handle the slide button press event.
func _on_slide_button_pressed() -> void:
	print("yehey")
	slide_button.disabled = true
	# Emit signal to toggle the visibility of the mutuals window
	slide_pressed.emit(is_opened)

# Function to handle the event when the user wants to view the profile of a specific username.
func _on_view_profile(userName: String) -> void:
	# View the profile of the selected user
	BKMREngine.Social.view_profile(userName)
	view_profile_pressed.emit(BKMREngine.Social.player_profile)

# Function to handle the event when the user presses the chat button to initiate a conversation.
#
# This function emits a signal to indicate that the chat button was pressed, passing the username
# of the selected user as a parameter. This signal can be connected to a function that initiates
# a chat or opens a chat window with the selected user.
#
# Parameters:
# - No explicit parameters are passed to this function, as the username is derived from the context.
#
# Returns:
# - This function does not return a value; it operates by emitting a signal with the selected username.
#
# Example usage:
# ```gdscript
# _on_chat_button_pressed()
# ```
func _on_chat_button_pressed() -> void:
	# Emit signal to initiate a chat with the selected user
	chat_button_pressed.emit(conversing_username)

func _on_main_screen_mutuals_button_pressed() -> void:
	slide_button.disabled = false


func _on_slide_button_2_pressed() -> void:
	print("tae")
	pass # Replace with function body.
