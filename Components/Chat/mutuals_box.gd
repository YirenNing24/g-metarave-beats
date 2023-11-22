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
var mutuals_list: Array

# Initialization function called when the node is ready.
#
# This function is called when the node is ready, and it performs the following tasks:
# 1. Retrieves mutual followers from the social system using BKMREngine.Social.get_mutual().
# 2. Waits for the completion of the mutual followers retrieval using await BKMREngine.Social.get_mutual_complete.
# 3. Populates the mutuals list in the UI by calling the populate_mutuals_list() function.
# 4. Connects the VScrollBar signal to handle new messages received using _on_new_all_message_received function.
#
# Returns:
# - This function does not return a value; it operates by initializing and populating the UI.
#
# Example usage:
# ```gdscript
# _ready()
# ```
func _ready() -> void:
	# Get mutual followers from the social system
	BKMREngine.Social.get_mutual()
	await BKMREngine.Social.get_mutual_complete
	mutuals_list = BKMREngine.Social.mutual_followers
	# Populate the mutuals list in the UI
	populate_mutuals_list()

# Function to populate the mutuals list in the UI.
#
# This function iterates through the mutual followers list and creates UI slots for each follower.
# It sets UI labels with relevant information such as username, level, and rank.
# Additionally, it connects the chat button signal to handle chat initiation through the _on_chat_button_pressed function.
#
# Returns:
# - This function does not return a value; it operates by populating the mutuals list in the UI.
#
# Example usage:
# ```gdscript
# populate_mutuals_list()
# ```
func populate_mutuals_list() -> void:
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
#
# This function emits a signal to toggle the visibility of the mutuals window.
# The signal includes the current state of the window (opened or closed).
#
# Returns:
# - This function does not return a value; it operates by emitting a signal to toggle the visibility of the mutuals window.
#
# Example usage:
# ```gdscript
# _on_slide_button_pressed()
# ```
func _on_slide_button_pressed() -> void:
	# Emit signal to toggle the visibility of the mutuals window
	slide_pressed.emit(is_opened)

# Function to handle the event when the user wants to view the profile of a specific username.
#
# This function triggers the Social engine to view the profile of the selected user and emits a signal
# indicating that the view profile button was pressed, passing the player profile as a parameter.
#
# Parameters:
# - `username`: The username of the user whose profile is to be viewed.
#
# Returns:
# - This function does not return a value; it operates by viewing the profile and emitting a signal.
#
# Example usage:
# ```gdscript
# _on_view_profile("selected_username")
# ```
func _on_view_profile(username: String) -> void:
	# View the profile of the selected user
	BKMREngine.Social.view_profile(username)
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
	print(conversing_username)
