extends Control

# Signals
signal session_check_done
signal chat_opened
signal mutuals_button_pressed

# UI Elements
@onready var mutuals_box: Control = %MutualsBox
@onready var hero: TextureRect = %Hero
@onready var player_name: Label = %PlayerName
@onready var player_rank: Label = %PlayerRank
@onready var filter_panel: Panel = %FilterPanel
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var beats_balance: Label = %BeatsBalance
@onready var native_balance: Label = %Native
@onready var kmr_balance: Label = %KMR
@onready var thump_balance: Label = %ThumpBalance
@onready var stats_wheel: TextureProgressBar = %StatsWheel
@onready var level: Label = %Level
@onready var menu_buttons_cont: VBoxContainer = %VBoxContainer
@onready var background_texture: TextureRect = %BackgroundTexture
@onready var store_button: TextureButton = %StoreButton
@onready var preview_username: Label = %PreviewUsername
@onready var preview_message: Label = %PreviewMessage
@onready var mutuals_button: TextureButton = %MutualsButton

# Modals
var profile_modal: Control = load("res://Components/Popups/profile_modal.tscn").instantiate()
var player_modal: Control = load("res://Components/Popups/player_modal.tscn").instantiate()
var stats_modal: Control = load("res://Components/Popups/stats_modal.tscn").instantiate()

# Tween
var stats_tween: Tween

# Connection status
var chat_connected: bool = false
var is_opened: bool = false

# Initialization function called when the node is ready.
#
# This function is automatically called when the node is ready to be used. It performs the following tasks:
# - Adds modals (profile_modal, player_modal, stat_modal) to the filter panel.
# - Initializes HUD data using the hud_data function.
# - Waits for the animation completion before showing the mutuals box.
# - Connects chat signals to their respective handlers (_on_chat_connected and _on_chat_closed).
#
# Returns:
# - This function does not return a value; it operates by performing the specified initialization tasks.
#
# Example usage:
# ```gdscript
# _ready()
# ```
func _ready() -> void:
	# Add modals (profile_modal, player_modal, stat_modal) to the filter panel.
	filter_panel.add_child(profile_modal)
	filter_panel.add_child(player_modal)
	filter_panel.add_child(stats_modal)

	# Initialize HUD data.
	hud_data()

	# Wait for animation completion before showing the mutuals box.
	await animation_player.animation_finished
	mutuals_box.show()

	# Connect chat signals to their respective handlers.
	BKMREngine.Chat.connected.connect(_on_chat_connected)
	BKMREngine.Chat.closed.connect(_on_chat_closed)

# Checks the user session.
#
# This function automatically attempts to log in the player by calling the auto_login_player method from the BKMREngine's Auth module.
# It then waits for the completion of the session check, ensuring that the user session is verified before proceeding.
#
# Returns:
# - This function does not return a value; it operates by automatically attempting to log in and waiting for the session check to complete.
#
# Example usage:
# ```gdscript
# session_check()
# ```

func session_check() -> void:
	# Automatically attempt to log in the player
	BKMREngine.Auth.auto_login_player()

	# Wait for the completion of the session check
	await BKMREngine.Auth.bkmr_session_check_complete

# Update HUD elements with player data.
#
# This function sets various HUD elements with player-related data, including player name, rank, balances, level, and stat points animation.
# It also checks if there are stat points to animate and updates the stats_wheel accordingly.
#
# Returns:
# - This function does not return a value; it operates by updating the HUD elements with player data.
#
# Example usage:
# ```gdscript
# hud_data()
# ```

func hud_data() -> void:
	# Set HUD elements with player data.
	player_name.text = BKMREngine.Auth.logged_in_player
	player_rank.text = PLAYER.player_rank
	beats_balance.text = PLAYER.beats_balance
	native_balance.text = PLAYER.native_balance
	kmr_balance.text = PLAYER.kmr_balance
	thump_balance.text = PLAYER.thump_balance
	level.text = str(PLAYER.level)

	# Check if there are stat points to animate.
	if PLAYER.stat_points > 0:
		stats_wheel.value = 0
		stats_tween = get_tree().create_tween()
		var _tween_property: PropertyTweener = stats_tween.tween_property(
			stats_wheel, 
			"value", 
			100, 
			1.5).set_trans(Tween.TRANS_LINEAR)
		var _tween_callback: CallbackTweener = stats_tween.tween_callback(hud_data)

# Event handler for the profile button press.
#
# This function is called when the profile button is pressed. It shows the profile modal and makes the filter panel visible.
#
# Returns:
# - This function does not return a value; it operates by showing the profile modal and making the filter panel visible.
#
# Example usage:
# ```gdscript
# _on_profile_button_pressed()
# ```
func _on_profile_button_pressed() -> void:
	# Show the profile modal and make the filter panel visible.
	profile_modal.visible = true
	filter_panel.visible = true

# GUI input event handler for the filter panel.
#
# This function handles GUI input events in the filter panel. It checks for mouse button input and closes modals based on their visibility.
#
# Parameters:
# - event: InputEvent - The input event to handle.
#
# Returns:
# - This function does not return a value; it operates by closing modals based on the input event.
#
# Example usage:
# ```gdscript
# _on_filter_panel_gui_input(event)
# ```
func _on_filter_panel_gui_input(event: InputEvent) -> void:
	# Check for mouse button input
	if event is InputEventMouseButton:
		# Close panels based on visibility
		if profile_modal.visible:
			close_modals()
		elif stats_modal.visible:
			close_modals()
		elif player_modal.visible:
			close_modals()

# Function to close all modals.
#
# This function closes all modals and hides the filter panel.
#
# Returns:
# - This function does not return a value; it operates by closing all modals and hiding the filter panel.
#
# Example usage:
# ```gdscript
# close_modals()
# ```
func close_modals() -> void:
	# Close all modals
	filter_panel.visible = false
	profile_modal.visible = false
	stats_modal.visible = false
	player_modal.visible = false

# Open the store screen.
#
# This function is triggered when the store button is pressed. It handles the transition to the store screen, including killing any existing stat tween, setting previous and next textures for scene transition, loading the store screen scene asynchronously, and temporarily disabling buttons in the 'MainButtons' group during the transition.
#
# Returns:
# - This function does not return a value; it operates by initiating the transition to the store screen.
#
# Example usage:
# ```gdscript
# _on_store_button_pressed()
# ```
func _on_store_button_pressed() -> void:
	# Kill the stat tween if it exists
	if stats_tween: 
		stats_tween.kill()

	# Set previous and next textures for scene transition
	LOADER.previous_texture = background_texture.texture
	LOADER.next_texture = preload("res://UITextures/BGTextures/store_bg.png")

	# Load the store screen scene asynchronously
	var _change_scene: bool = await LOADER.load_scene(self, "res://UIScenes/store_screen.tscn")

	# Disable buttons in the 'MainButtons' group during the scene transition
	for buttons: Button in get_tree().get_nodes_in_group('MainButtons'):
		buttons.disabled = true
	for buttons: Button in get_tree().get_nodes_in_group('MainButtons2'):
		buttons.disabled = true

# Open the inventory screen.
#
# This function is triggered when the inventory button is pressed. It handles the transition to the inventory screen, including killing any existing stat tween, closing the chat socket with a specific code and reason, setting previous and next textures for scene transition, loading the inventory screen scene asynchronously, and temporarily disabling buttons in the 'MainButtons' and 'MainButtons2' groups during the transition.
#
# Returns:
# - This function does not return a value; it operates by initiating the transition to the inventory screen.
#
# Example usage:
# ```gdscript
# _on_inventory_button_pressed()
# ```
func _on_inventory_button_pressed() -> void:
	# Kill the stat tween if it exists
	if stats_tween: 
		stats_tween.kill()

	# Close the chat socket with a specific code and reason
	BKMREngine.Chat.socket.close(1000, "changed_scene")

	# Set previous and next textures for scene transition
	LOADER.previous_texture = background_texture.texture
	LOADER.next_texture = preload("res://UITextures/BGTextures/main_inventory_bg.png")

	# Load the main inventory scene asynchronously
	var _change_scene: bool = await LOADER.load_scene(self, "res://UIScenes/main_inventory.tscn")

	# Disable buttons in the 'MainButtons' group during the scene transition
	for buttons: Button in get_tree().get_nodes_in_group('MainButtons'):
		buttons.disabled = true
	# Disable buttons in the 'MainButtons2' group during the scene transition
	for buttons: Button in get_tree().get_nodes_in_group('MainButtons2'):
		buttons.disabled = true

# Handle the event when the chat is successfully connected
func _on_chat_connected(_url: String) -> void:
	chat_connected = true

# Handle the event when the chat is closed
func _on_chat_closed(_code: int, _reason: String) -> void:
	chat_connected = false
	if is_opened:
		pass  # Placeholder, additional handling can be added here if needed

# Open the song menu screen with a smooth transition.
#
# This function is triggered when the game mode button is pressed. It handles the transition to the song menu screen with a smooth transition. This involves disabling buttons in the 'MainButtons' and 'MainButtons2' groups during the transition, setting previous and next textures for the scene transition, and loading the song menu scene asynchronously.
#
# Returns:
# - This function does not return a value; it operates by initiating the transition to the song menu screen.
#
# Example usage:
# ```gdscript
# _on_game_mode_button_pressed()
# ```
func _on_game_mode_button_pressed() -> void:
	# Disable buttons in 'MainButtons' and 'MainButtons2' groups during the transition
	for buttons: TextureButton in get_tree().get_nodes_in_group('MainButtons'):
		buttons.disabled = true
	for buttons2: Button in get_tree().get_nodes_in_group('MainButtons2'):
		buttons2.disabled = true

	# Set previous and next textures for the scene transition
	LOADER.previous_texture = background_texture.texture
	LOADER.next_texture = preload("res://UITextures/BGTextures/song_menu_bg.png")

	# Load the song menu scene asynchronously
	var _change_scene: bool = await LOADER.load_scene(self, "res://UIScenes/song_menu.tscn")

# Open the stat modal and show the filter panel.
#
# This function is triggered when the stat button is pressed. It displays the stat modal and makes the filter panel visible.
#
# Returns:
# - This function does not return a value; it operates by showing the stat modal and the filter panel.
#
# Example usage:
# ```gdscript
# _on_stat_button_pressed()
# ```
func _on_stat_button_pressed() -> void:
	filter_panel.show()
	stats_modal.show()

# View the profile from the chat box.
#
# This function is called when the "View Profile" button is pressed in the chat box. It sets the player modal and filter panel to be visible.
#
# Parameters:
# - `_player_profile`: A dictionary containing the player's profile information.
#
# Returns:
# - This function does not return a value; it operates by making the player modal and filter panel visible.
#
# Example usage:
# ```gdscript
# _on_chat_box_view_profile_pressed(player_profile_data)
# ```
func _on_chat_box_view_profile_pressed(_player_profile: Dictionary) -> void:
	player_modal.visible = true
	filter_panel.visible = true

# Display the received message in the chat box.
#
# This function is called when a message is received in the chat box. It updates the preview message and username text in the chat box based on the received message data.
#
# Parameters:
# - `received_message`: A dictionary containing the received message data, including the message content and username.
#
# Returns:
# - This function does not return a value; it operates by updating the preview message and username text in the chat box.
#
# Example usage:
# ```gdscript
# _on_chat_box_2_all_message_received(received_message_data)
# ```
func _on_chat_box_2_all_message_received(received_message: Dictionary) -> void:
	preview_message.text = received_message.message
	preview_username.text = received_message.username + ": "

# Open the chat window with a sliding animation.
#
# This function is called when the chat window button is pressed, triggering a sliding animation to open the chat window.
#
# Returns:
# - This function does not take any parameters, and it does not return a value; it operates by playing the "chat_slide" animation.
#
# Example usage:
# ```gdscript
# _on_chat_window_button_pressed()
# ```
func _on_chat_window_button_pressed() -> void:
	animation_player.play("chat_slide")

# Open the mutuals box with a sliding animation.
#
# This function is called when the mutuals button is pressed, triggering a sliding animation to open the mutuals box.
# It waits for the animation to finish before hiding the mutuals button.
#
# Returns:
# - This function does not take any parameters, and it does not return a value; it operates by playing the "mutual_slide" animation.
#
# Example usage:
# ```gdscript
# _on_mutuals_button_pressed()
# ```
func _on_mutuals_button_pressed() -> void:
	animation_player.play("mutual_slide")
	await animation_player.animation_finished
	mutuals_button.visible = false

# Close the mutuals box with a sliding animation.
#
# This function is called when the mutuals box slide button is pressed, triggering a reverse sliding animation to close the mutuals box.
# It waits for the animation to finish before making the mutuals button visible again.
#
# Parameters:
# - `_isOpen` (bool): Indicates whether the mutuals box is currently open (not used in the function logic).
#
# Returns:
# - This function does not return a value; it operates by playing the reverse "mutual_slide" animation.
#
# Example usage:
# ```gdscript
# _on_mutuals_box_slide_pressed(true)
# ```
func _on_mutuals_box_slide_pressed(_isOpen: bool) -> void:
	animation_player.play_backwards("mutual_slide")
	await animation_player.animation_finished
	mutuals_button.visible = true

# Close the chat box with a sliding animation.
#
# This function is triggered when the close button in the chat box is pressed, initiating a reverse sliding animation to close the chat box.
#
# Returns:
# - This function does not return a value; it operates by playing the reverse "chat_slide" animation.
#
# Example usage:
# ```gdscript
# _on_chat_box_2_close_pressed()
# ```
func _on_chat_box_close_pressed() -> void:
	animation_player.play_backwards("chat_slide")
	
	for buttons: TextureButton in get_tree().get_nodes_in_group('MainButtons'):
		buttons.disabled = false
	for buttons: Button in get_tree().get_nodes_in_group('MainButtons2'):
		buttons.disabled = false

func _on_mutuals_box_chat_button_pressed(_conversing_username: String) -> void:
	for buttons: TextureButton in get_tree().get_nodes_in_group('MainButtons'):
		buttons.disabled = true
	for buttons: Button in get_tree().get_nodes_in_group('MainButtons2'):
		buttons.disabled = true
	
	animation_player.play_backwards("mutual_slide")
	await animation_player.animation_finished
	mutuals_button.visible = true
	
	animation_player.play("chat_slide")
