extends Control

#region Signals
signal chat_opened
signal mutuals_button_pressed

#endregion

#region UI Elements
@onready var mutuals_box: Control = %MutualsBox
@onready var hero: TextureRect = %Hero
@onready var player_name: Label = %PlayerName
@onready var player_rank: Label = %PlayerRank
@onready var filter_panel: Panel = %FilterPanel
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var beats_balance: Label = %BeatsBalance
@onready var native_balance: Label = %Native
@onready var gmr_balance: Label = %GMR
@onready var thump_balance: Label = %ThumpBalance
@onready var stats_wheel: TextureProgressBar = %StatsWheel
@onready var level: Label = %Level
@onready var menu_buttons_cont: VBoxContainer = %VBoxContainer
@onready var background_texture: TextureRect = %BackgroundTexture
@onready var store_button: TextureButton = %StoreButton
@onready var preview_username: Label = %PreviewUsername
@onready var preview_message: Label = %PreviewMessage
@onready var mutuals_button: TextureButton = %MutualsButton
@onready var server_time: Label = %ServerTime
@onready var cursor_spark: GPUParticles2D = %CursorSpark
#endregion

#region Modals
var profile_modal: Control = load("res://Components/Popups/profile_modal.tscn").instantiate()
var player_modal: Control = load("res://Components/Popups/player_modal.tscn").instantiate()
var stats_modal: Control = load("res://Components/Popups/stats_modal.tscn").instantiate()
var stats_tween: Tween
#endregion

#region Connection status
var chat_connected: bool = false
var is_opened: bool = false
#endregion

#region Initialization function called when the node is ready.
func _ready() -> void:
	#Initialize 
	signal_connect()
	add_components()

	hud_data()

	#Wait for animation completion before showing the mutuals box.
	await animation_player.animation_finished
	mutuals_box.show()

# Add modals (profile_modal, player_modal, stat_modal) to the filter panel.
func add_components() -> void:

	filter_panel.add_child(profile_modal)
	filter_panel.add_child(player_modal)
	filter_panel.add_child(stats_modal)
	stats_modal.visible = false

# Connect chat signals to their respective handlers.
func signal_connect() -> void:
	BKMREngine.Websocket.server_time.connect(_on_updated_server_time)
	BKMREngine.Websocket.connected.connect(_on_chat_connected)
	BKMREngine.Websocket.closed.connect(_on_chat_closed)
	BKMREngine.Profile.open_profile_pic_complete.connect(_on_open_profile_pic)
	
# Checks the user session.
func session_check() -> void:
	BKMREngine.Auth.auto_login_player()
	await BKMREngine.Auth.bkmr_session_check_complete

# Update HUD elements with player data.
func hud_data() -> void:
	player_name.text = BKMREngine.Auth.logged_in_player
	player_rank.text = PLAYER.player_rank
	beats_balance.text = PLAYER.beats_balance
	native_balance.text = PLAYER.native_balance
	gmr_balance.text = PLAYER.gmr_balance
	level.text = str(PLAYER.level)
	#BKMREngine.Profile.get_profile_pic()
	animate_hud()
	
func animate_hud() -> void:
	# Check if there are stat points to animate.
	if PLAYER.stat_points > 0:
		stats_wheel.value = 0
		stats_tween = get_tree().create_tween()
		var _tween_property: PropertyTweener = stats_tween.tween_property(
			stats_wheel, 
			"value", 
			100, 
			1.5).set_trans(Tween.TRANS_LINEAR)
		var _tween_callback: CallbackTweener = stats_tween.tween_callback(animate_hud)
#endregion


#region UI connected callbacks

# Event handler for the profile button press.
func _on_profile_button_pressed() -> void:
	# Show the profile modal and make the filter panel visible.
	profile_modal.visible = true
	filter_panel.visible = true
	player_modal.visible = false
	stats_modal.visible = false
	
# GUI input event handler for the filter panel.
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

# Open the store screen.
func _on_store_button_pressed() -> void:
	# Kill the stat tween if it exists
	if stats_tween: 
		stats_tween.kill()

	# Set previous and next textures for scene transition
	LOADER.previous_texture = background_texture.texture
	LOADER.next_texture = preload("res://UITextures/BGTextures/store_bg.png")

	# Load the store screen scene asynchronously
	var _change_scene: bool = await LOADER.load_scene(self, "res://UIScenes/store_screen2.tscn")

	# Disable buttons in the 'MainButtons' group during the scene transition
	for buttons: Button in get_tree().get_nodes_in_group('MainButtons'):
		buttons.disabled = true
	for buttons: Button in get_tree().get_nodes_in_group('MainButtons2'):
		buttons.disabled = true

# Open the inventory screen.
func _on_inventory_button_pressed() -> void:
	
	# Kill the stat tween if it exists
	if stats_tween: 
		stats_tween.kill()

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
	
# Open the song menu screen with a smooth transition.
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
func _on_stat_button_pressed() -> void:
	player_modal.visible = false
	profile_modal.visible = false
	filter_panel.visible = true
	stats_modal.visible = true
	
# View the profile from the chat box.
func _on_chat_box_view_profile_pressed(_player_profile: Dictionary) -> void:
	profile_modal.visible = false
	player_modal.visible = true
	filter_panel.visible = true

# Display the received message in the chat box
func _on_chat_box_2_all_message_received(received_message: Dictionary) -> void:
	preview_message.text = received_message.message
	preview_username.text = received_message.username + ": "

# Open the chat window with a sliding animation.
func _on_chat_window_button_pressed() -> void:
	chat_opened.emit()
	animation_player.play("chat_slide")

# Open the mutuals box with a sliding animation.
func _on_mutuals_button_pressed() -> void:
	mutuals_button_pressed.emit()
	animation_player.play("mutual_slide")
	await animation_player.animation_finished
	mutuals_button.visible = false
	mutuals_button.disabled = true

# Close the mutuals box with a sliding animation.
func _on_mutuals_box_slide_pressed(_is_open: bool) -> void:
	animation_player.play_backwards("mutual_slide")
	await animation_player.animation_finished
	mutuals_button.disabled = false
	mutuals_button.visible = true
	
# Close the chat box with a sliding animation.
func _on_chat_box_close_pressed() -> void:
	animation_player.play_backwards("chat_slide")
	for buttons: TextureButton in get_tree().get_nodes_in_group('MainButtons'):
		buttons.disabled = false
	for buttons: Button in get_tree().get_nodes_in_group('MainButtons2'):
		buttons.disabled = false

# Open chat with a mutual 
func _on_mutuals_box_chat_button_pressed(_conversing_username: String) -> void:
	for buttons: TextureButton in get_tree().get_nodes_in_group('MainButtons'):
		buttons.disabled = true
	for buttons: Button in get_tree().get_nodes_in_group('MainButtons2'):
		buttons.disabled = true
	
	animation_player.play_backwards("mutual_slide")
	await animation_player.animation_finished
	mutuals_button.visible = true
	animation_player.play("chat_slide")

# Change scene to leaderboard screen
func _on_leaderboard_button_pressed() -> void:
	# Kill the stat tween if it exists
	if stats_tween: 
		stats_tween.kill()

	# Set previous and next textures for scene transition
	LOADER.previous_texture = background_texture.texture
	LOADER.next_texture = preload("res://UITextures/BGTextures/main_city.png")

	# Load the main inventory scene asynchronously
	var _change_scene: bool = await LOADER.load_scene(self, "res://UIScenes/leaderboard_screen.tscn")

	# Disable buttons in the 'MainButtons' group during the scene transition
	for buttons: Button in get_tree().get_nodes_in_group('MainButtons'):
		buttons.disabled = true
	# Disable buttons in the 'MainButtons2' group during the scene transition
	for buttons: Button in get_tree().get_nodes_in_group('MainButtons2'):
		buttons.disabled = true
#endregion

#region Callbacks

# Use profile pic call back data
func _on_open_profile_pic(_profile_pics: Array) -> void:
	pass
	
# Set the server time in the UI
func _on_updated_server_time(time_server: String, _ping: float) -> void:
	server_time.text = time_server
	
# Handle the event when the chat is successfully connected
func _on_chat_connected(_url: String) -> void:
	chat_connected = true
	
# Handle the event when the chat is closed
func _on_chat_closed(_code: int, _reason: String) -> void:
	chat_connected = false
	if is_opened:
		pass  # Placeholder, additional handling can be added here if needed
		
# Function to close all modals.
func close_modals() -> void:
	# Close all modals
	filter_panel.visible = false
	profile_modal.visible = false
	stats_modal.visible = false
	player_modal.visible = false
#endregion

func _input(event: InputEvent) -> void:
	# Handle screen touch events.
	if event is InputEventScreenTouch:
		if event.pressed:
			# Check if the touch event is within the bounds of the notepicker node.
			var position_event: Vector2 = event.position
			cursor_spark.position = position_event
			cursor_spark.emitting = true
			play_pointer_sfx()
	elif event is InputEventScreenDrag:
		var position_event: Vector2 = event.position
		cursor_spark.position = position_event
		cursor_spark.emitting = true
	
func play_pointer_sfx() -> void:
	$AudioStreamPlayer.play()
	await $AudioStreamPlayer.finished
