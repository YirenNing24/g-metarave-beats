extends Control
# TODO: Loading wheel when logging in should be continous until login is completed
# TODO: LOGIN/REGISTRATION highligting

#TODO: Bug. unable to conitnue chat when chat window is closed 

# PACKED SCENES
@onready var message_slot: PackedScene = preload("res://Components/Chat/chat_message2.tscn")
@onready var conversing_message_slot: PackedScene = preload("res://Components/Chat/conversing_message.tscn")
@onready var chat_mutual_panel: PackedScene = preload("res://Components/Chat/chat_mutual_panel.tscn")

# SIGNALS
signal all_message_received(received_message: Dictionary)
signal close_pressed
signal view_profile_pressed(player_profile: Dictionary)

# SCENE NODES
@onready var message_tab: TabContainer = %MessageTab
@onready var message_input_line: LineEdit = %MessageInputLine

# ALL MESSAGES ROOM CONTAINERS
@onready var all_chat_vbox: VBoxContainer = %AllChatVBox
@onready var all_message_scroll: ScrollContainer = %AllMessageScroll
@onready var all_chat_v_scroll: VScrollBar = all_message_scroll.get_v_scroll_bar()

# PRIVATE MESSAGES ROOM CONTAINERS
@onready var mutual_chat_vbox: VBoxContainer = %MutualChatVBox
@onready var mutual_message_scroll: ScrollContainer = %MutualMessageScroll
@onready var mutual_chat_v_scroll: VScrollBar = mutual_message_scroll.get_v_scroll_bar()

# MUTUAL CHAT CONTAINERS
@onready var chat_mutual_scroll: ScrollContainer = %ChatMutualScroll
@onready var chat_mutual_vbox: VBoxContainer =  %ChatMutualVbox

# SERVER ENGINE VARIABLES
var host: String = BKMREngine.host_ip
var port: String = BKMREngine.port
var url: String = "ws://" + host + port + "/api/chats/all"

# STATE VARIABLES
var current_room: String = "all"
var chat_connected: bool = false
var is_opened: bool = false

# SETTER VARIABLES
var current_tab: int 
var username_conversing: String

func _ready() -> void: 
	# Connect signals to their corresponding functions
	BKMREngine.Websocket.chat_single.connect(_on_message_received)

	on_all_messages_opened()
	
	# Connect signals for vertical scroll changes in different containers
	var _all_v_scroll: int = all_chat_v_scroll.changed.connect(_on_new_all_message_received)
	var _mutual_v_scroll: int = mutual_chat_v_scroll.changed.connect(_on_new_mutual_message_received)

func _on_message_received(received_message: Dictionary) -> void:
	# Check if the received message is valid
	if !received_message:
		return
	
	# Check if the received message has a "roomId" property
	if !received_message.has("roomId"):
		return
	
	# Process the received message
	else:
		# Check and remove excess messages from different containers
		if all_chat_vbox.get_child_count() > 20:
			# Remove excess messages from the "All Messages" container
			remove_excess_message(all_chat_vbox, 20)
			
		if mutual_chat_vbox.get_child_count() > 40:
			# Remove excess messages from the private conversation container
			remove_excess_message(mutual_chat_vbox, 40)
		
		# Add the received message to the appropriate container
		add_message_to_container(received_message)

func add_message_to_container(received_message: Dictionary) -> void:
	# Extract information from the received message
	var sender_username: String = received_message.sender
	var message_text: String = received_message.message
	var ts_milliseconds: float = received_message.ts
	# Convert milliseconds to seconds
	var ts_seconds: int = roundi(ts_milliseconds / 1000)
	
	# Convert unix timestamp to ISO 8601 time string (HH:MM:SS)
	var _timestamp: String = Time.get_time_string_from_unix_time(ts_seconds)
	# Instantiate a new message slot control
	var slot_message: Control = message_slot.instantiate()

	# Set the text of UI elements in the message slot based on the received message
	slot_message.get_node('VBoxContainer/HBoxContainer/UsernameLabel').text = sender_username
	#slot_message.get_node('VBoxContainer/HBoxContainer/TimestampLabel').text = timestamp
	slot_message.get_node('VBoxContainer/TextureRect/HBoxContainer/VBoxContainer/MessageLabel').text = message_text
	slot_message.get_node("VBoxContainer/HBoxContainer/UsernameLabel/Button").pressed.connect(_on_view_profile_pressed.bind(sender_username))
	
	# Determine the destination container based on the room and sender
	if received_message.roomId == "all":
		# Add to the "All Messages" container and emit the all_message_received signal
		all_chat_vbox.add_child(slot_message)
		all_message_received.emit(received_message)
	else:
		if received_message.sender == PLAYER.username:
			# Add to the player's messages container in a private conversation
			mutual_chat_vbox.add_child(slot_message)
		else:
			# Instantiate a new message slot for the other user the player is having a chat with
			var conversing_message: Control = conversing_message_slot.instantiate()
			conversing_message.get_node('VBoxContainer/HBoxContainer/UsernameLabel').text = sender_username
			#conversing_message.get_node('VBoxContainer/HBoxContainer/TimestampLabel').text = timestamp
			conversing_message.get_node('VBoxContainer/TextureRect/HBoxContainer/VBoxContainer/MessageLabel').text = message_text
			conversing_message.get_node("VBoxContainer/HBoxContainer/UsernameLabel/Button").pressed.connect(_on_view_profile_pressed.bind(sender_username))
			mutual_chat_vbox.add_child(conversing_message)


func remove_excess_message(message_vbox: VBoxContainer, limit: int) -> void:
	# Check if the number of child messages exceeds the specified limit
	if message_vbox.get_child_count() > limit:
		# Retrieve the message control to be removed (beyond the limit)
		var message_to_be_removed: Control = message_vbox.get_child(limit)
		# Free up the resources associated with the message control
		message_to_be_removed.queue_free()

func _on_new_all_message_received() -> void:
	# Adjust the vertical scroll position to show the latest messages on the "All Messages" tab
	all_message_scroll.scroll_vertical = int(all_chat_v_scroll.max_value)

func _on_new_mutual_message_received() -> void:
	# Adjust the vertical scroll position to show the latest mutual messages on the mutual tab
	mutual_message_scroll.scroll_vertical = int(mutual_chat_v_scroll.max_value)

func on_all_messages_opened() -> void:
	var room_messages: Array = BKMREngine.Websocket.chat_messages
	var room_id: String = BKMREngine.Websocket.chat_handle
	# Reverse the order of messages to display the latest ones first
	var all_room_messages: Array = room_messages
	all_room_messages.reverse()
	
	# Iterate through each message in the room
	for messages: Dictionary in all_room_messages:
		# Check if the room is the public "All Messages" room
		if room_id == "all":
			# Instantiate a new message slot control
			var all_message_slot: Control = message_slot.instantiate()
			
			# Extract information from the message
			var sender_username: String = messages.username
			var message: String = messages.message
			var _ts: float = messages.ts
			# Convert milliseconds to seconds
			var _ts_seconds: int = roundi(_ts/ 1000)
			#if sender_username == "GreenPill":
				#all_message_slot.get_node("VBoxContainer/TextureRect/HBoxContainer/DPIcon").texture = load("res://UITextures/Bundles/green_pill.png")
			#else:
				#all_message_slot.get_node("VBoxContainer/TextureRect/HBoxContainer/DPIcon").texture = load("res://UITextures/Bundles/beats_logo.png")
			# Disable the button if the message sender is the logged-in player
			if PLAYER.username == sender_username:
				
				all_message_slot.get_node("VBoxContainer/HBoxContainer/UsernameLabel/Button").disabled = true
			
			# Convert unix timestamp to ISO 8601 time string (HH:MM:SS)
			#var timestamp: String = Time.get_time_string_from_unix_time(ts_seconds)
			
			all_message_slot.get_node('VBoxContainer/HBoxContainer/UsernameLabel').text = sender_username
			#all_message_slot.get_node('VBoxContainer/HBoxContainer/TimestampLabel').text = timestamp
			all_message_slot.get_node('VBoxContainer/TextureRect/HBoxContainer/VBoxContainer/MessageLabel').text = message
			
			# Connect the button press to view the sender's profile
			if all_message_slot.get_node("VBoxContainer/HBoxContainer/UsernameLabel/Button").pressed.is_connected(_on_view_profile_pressed):
				all_message_slot.get_node("VBoxContainer/HBoxContainer/UsernameLabel/Button").pressed.disconnect(_on_view_profile_pressed)
				
			all_message_slot.get_node("VBoxContainer/HBoxContainer/UsernameLabel/Button").pressed.connect(_on_view_profile_pressed.bind(sender_username))
			
			# Add the message slot to the "All Messages" container
			all_chat_vbox.add_child(all_message_slot)


func _on_view_profile_pressed(username: String) -> void:
	BKMREngine.Social.view_profile(username)
	view_profile_pressed.emit()

func _on_message_line_text_submitted(message: String) -> void:
	if username_conversing != "":
		current_room = username_conversing
	var stripped_message: String = message.strip_edges()
	# Check if the stripped message is empty; if so, return without sending
	if stripped_message == "":
		return
	# Prepare message data based on the current room
	var message_data: Dictionary = {}
	
	match current_room:
		"":
			return
		"all":
			# Public chat room message
			message_data = { 
				"message": message, 
				"roomId": current_room, 
				"sender": PLAYER.username,
				"username": PLAYER.username
			}
			
		username_conversing:
			# Private message to a specific user
			message_data = { 
				"message": message, 
				"roomId": PLAYER.username, 
				"sender": PLAYER.username,
				"receiver": username_conversing,
				"seen": false
			}
	BKMREngine.Websocket.send_chat(message_data)
	# Clear the input line after sending the message
	message_input_line.text = ""

func _on_voice_recording_button_toggled(is_recording: bool) -> void:
	var recorder_bus: int = AudioServer.get_bus_index("Record")
	var effect: AudioEffectRecord = AudioServer.get_bus_effect(recorder_bus, 0) as AudioEffectRecord
	var timer: SceneTreeTimer
	if is_recording:
		effect.set_recording_active(true)
		%AudioStreamPlayer.play()
		# Create a one-shot timer that will stop the recording after 5 seconds
		timer = get_tree().create_timer(5.0)
		var _connect: int = timer.timeout.connect(_stop_recording)
	else:
		_stop_recording()

func _stop_recording() -> void:
	var recorder_bus: int = AudioServer.get_bus_index("Record")
	var effect: AudioEffectRecord = AudioServer.get_bus_effect(recorder_bus, 0) as AudioEffectRecord
	
	effect.set_recording_active(false)
	var _record_data: AudioStreamWAV = effect.get_recording()
	%AudioStreamPlayer.stop()
	#send_voice_recording(record_data.data)
		
func send_voice_recording(recording_data: PackedByteArray) -> void:
	if username_conversing != "" or !current_room == "all":
		# Private message to a specific user
		var _message_data: Dictionary = { 
			"roomId": PLAYER.username, 
			"sender": PLAYER.username,
			"message": "",
			"voiceRecording": recording_data,
			"receiver": username_conversing,
			"seen": false
		}

func _on_message_tab_tab_changed(tab: int) -> void:
	# Check which tab is selected in the message tab container
	if tab == 0: 
		# Switched to the "All Messages" tab
		current_room = "all"
		username_conversing = ""
		if current_tab == 1:
			for message: Control in  %ChatMutualVbox.get_children():
				message.queue_free()
				
			for slot: Control in  %ChatMutualVbox.get_children():
				slot.visible = false
				var button: Button = slot.get_node('Button')
				button.modulate = "ffffff"
				
			current_tab = 0
		# Connect the signal to handle opening all messages
		#BKMREngine.Chat.messages.connect(_on_all_messages_opened)
	elif tab == 1:
		# Switched to the "Mutual Messages" tab
		current_room = ""
		for slot: Control in  %ChatMutualVbox.get_children():
			slot.visible = true
			
		current_tab = 1
		# Switched to a different tab (e.g., private messages)

func _on_close_button_button_up() -> void:
	current_room = ""
	username_conversing = ""
	message_tab.current_tab = 0
	for message: Control in mutual_chat_vbox.get_children():
		message.queue_free()
	close_pressed.emit()
	
func _on_mutuals_box_chat_button_pressed(conversing_username: String) -> void:
	# Request private inbox data for the specified user
	BKMREngine.Websocket.get_private_inbox_data(conversing_username)
	await BKMREngine.Websocket.get_inbox_messages_complete
	
	# Retrieve private messages for the conversation
	var private_messages: Array = BKMREngine.Websocket.private_messages
	private_messages.reverse()
	# Create or update the chat panel for the conversation
	add_chat_panel_from_mutual_box(conversing_username)
	
	# Display received messages in the appropriate containers
	display_received_messages(private_messages)
	
	# Set the current room, conversing username, and switch to the chat tab
	username_conversing = conversing_username
	
	for slot: Control in  %ChatMutualVbox.get_children():
		if slot.name == current_room:
			slot.get_node('Button').modulate = "ffffff00"
	
	message_tab.current_tab = 1
	current_tab = 1

func add_chat_panel_from_mutual_box(conversing_username: String) -> void:
	for slot: Control in  %ChatMutualVbox.get_children():
		if slot.name == conversing_username:
			# The panel with the given name already exists, no need to add it again.
			return
	var chat_mutual_panel_count: int =  %ChatMutualVbox.get_child_count()
	if chat_mutual_panel_count == 4:
		var excess_panel: Control =  %ChatMutualVbox.get_child(3)
		excess_panel.queue_free()
	# Create a new chat panel since it doesn't exist
	var panel_chat_mutual: Control = chat_mutual_panel.instantiate()
	panel_chat_mutual.name = conversing_username
	panel_chat_mutual.get_node('Panel/VBoxContainer/Username').text = conversing_username
	panel_chat_mutual.get_node('Button').modulate = "ffffff00"
	
	if panel_chat_mutual.get_node('Button').pressed.is_connected(_on_panel_chat_mutual_pressed):
		panel_chat_mutual.get_node('Button').pressed.disconnect(_on_panel_chat_mutual_pressed)
	panel_chat_mutual.get_node('Button').pressed.connect(_on_panel_chat_mutual_pressed.bind(conversing_username))
	
	%ChatMutualVbox.add_child(panel_chat_mutual)

func _on_panel_chat_mutual_pressed(conversing_username: String) -> void:
	if current_room != conversing_username:
		for messages: Control in mutual_chat_vbox.get_children():
			messages.queue_free()

		BKMREngine.Websocket.get_private_inbox_data(conversing_username)
		await BKMREngine.Websocket.get_inbox_messages_complete
		
		# Retrieve private messages for the conversation
		var private_messages: Array = BKMREngine.Websocket.private_messages
		display_received_messages(private_messages)
	else:
		pass
	for slot: Control in  %ChatMutualVbox.get_children():
		if slot.name == conversing_username:
			# Selected slot
			slot.get_node('Button').modulate = "ffffff00"
		else:
			# Unselected slots
			slot.get_node('Button').modulate = "ffffff"
			
	username_conversing = conversing_username

func _on_send_message_button_pressed() -> void:
	if username_conversing != "":
		current_room = username_conversing

	# Get the message from the input line
	var message: String = message_input_line.text
	
	var stripped_message: String = message.strip_edges()
	# Check if the stripped message is empty; if so, return without sending
	if stripped_message == "":
		return
	
	# Call the send_message function to handle sending the message
	send_message(message)

	# Clear the input line after sending the message
	message_input_line.text = ""

func prepare_message_data(message: String) -> Dictionary:
	# Prepare message data based on the current room
	var message_data: Dictionary = {}
	
	match current_room:
		"":
			return {}
		"all":
			# Public chat room message
			message_data = { 
				"message": message, 
				"roomId": current_room, 
				"sender": PLAYER.username,
				"username": PLAYER.username
			}
		username_conversing:
			# Private message to a specific user
			message_data = { 
				"message": message, 
				"roomId": PLAYER.username, 
				"sender": PLAYER.username,
				"receiver": username_conversing,
				"seen": false
			}
	
	return message_data

func send_message(message: String) -> void:
	# Get the prepared message data
	var message_data: Dictionary = prepare_message_data(message)
	
	# If message_data is empty, return without sending
	if message_data.is_empty():
		return
	
	# Send the message through the chat socket
	BKMREngine.Websocket.send_chat(message_data)

func display_received_messages(private_messages: Array) -> void:
	# Iterate through each received message in the private_messages array
	for received_message: Dictionary in private_messages:
		# Extract information from the received message
		var sender_username: String = received_message.sender
		var message_text: String = received_message.message
		var ts_milliseconds: float = received_message.ts
		# Convert milliseconds to seconds
		var ts_seconds: int = roundi(ts_milliseconds / 1000)
		
		# Convert unix timestamp to ISO 8601 time string (HH:MM:SS)
		var timestamp: String = Time.get_time_string_from_unix_time(ts_seconds)
		
		# Instantiate a new message slot control
		if received_message.sender == PLAYER.username:
			var slot_message: Control = message_slot.instantiate()
			# Set the text of UI elements in the message slot based on the received message
			slot_message.get_node('VBoxContainer/HBoxContainer/UsernameLabel').text = sender_username
			slot_message.get_node('VBoxContainer/HBoxContainer/TimestampLabel').text = timestamp
			slot_message.get_node('VBoxContainer/TextureRect/HBoxContainer/VBoxContainer/MessageLabel').text = message_text
			mutual_chat_vbox.add_child(slot_message)
		else:
			var conversing_message: Control = conversing_message_slot.instantiate()
			conversing_message.get_node('VBoxContainer/HBoxContainer/UsernameLabel').text = sender_username
			conversing_message.get_node('VBoxContainer/HBoxContainer/TimestampLabel').text = timestamp
			conversing_message.get_node('VBoxContainer/TextureRect/HBoxContainer/VBoxContainer/MessageLabel').text = message_text
			mutual_chat_vbox.add_child(conversing_message)

func _on_gift_button_pressed() -> void:
	$GiftingWindow.visible = true
	
func _on_gifting_window_gift_card_data(gift_card_data: Dictionary) -> void:
	gift_card_data.receiver = username_conversing
	BKMREngine.Social.gift_card(gift_card_data)


func _on_main_screen_chat_opened() -> void:
	current_room = "all"
	message_tab.current_tab = 0
