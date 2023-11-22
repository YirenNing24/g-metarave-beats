extends Control

# PACKED SCENES
@onready var message_slot: PackedScene = preload("res://Components/Chat/chat_message.tscn")
@onready var conversing_message_slot: PackedScene = preload("res://Components/Chat/conversing_message.tscn")
@onready var chat_mutual_panel: PackedScene = preload("res://Components/Chat/chat_mutual_panel.tscn")

# SIGNALS
signal sent_message(message: Dictionary)
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
@onready var chat_mutual_vbox: VBoxContainer = %ChatMutualVbox

# SERVER ENGINE VARIABLES
var host: String = BKMREngine.host_ip
var port: String = BKMREngine.port
var url: String = "ws://" + host + port + "/api/chats/all"

# STATE VARIABLES
var current_room: String = "all"
var chat_connected: bool = false
var is_opened: bool = false

# SETTER VARIABLES
var username_conversing: String

# Initialization function called when the node is ready.
#
# This function connects to the chat socket for the public "All Messages" room and sets up signals to handle various chat-related events.
# It specifically connects the '_on_message_received' function to the 'message_single' signal, '_on_all_messages_opened' to the 'messages' signal, 
# and '_on_chat_box_closed' to the 'closed' signal. Additionally, it connects signals for vertical scroll changes in different containers, 
# such as '_on_new_all_message_received' to the 'changed' signal of 'all_chat_v_scroll' and '_on_new_mutual_message_received' to the 'changed' signal 
# of 'mutual_chat_vbox'.
#
# Returns:
# - This function does not return a value; it operates by connecting signals to their corresponding functions.
#
# Example usage:
# ```gdscript
# _ready()
# ```
func _ready() -> void:
	# Connect to the chat socket for the public "All Messages" room
	await BKMREngine.Chat.connect_socket(url)

	# Connect signals to their corresponding functions
	BKMREngine.Chat.message_single.connect(_on_message_received)
	BKMREngine.Chat.messages.connect(_on_all_messages_opened)
	BKMREngine.Chat.closed.connect(_on_chat_box_closed)
	
	# Connect signals for vertical scroll changes in different containers
	var _all_v_scroll: int = all_chat_v_scroll.changed.connect(_on_new_all_message_received)
	var _mutual_v_scroll: int = mutual_chat_v_scroll.changed.connect(_on_new_mutual_message_received)
	
# Callback function when a new message is received.
#
# This function is called when a new message is received in the chat. It first checks the validity of the received message and ensures it has a "roomId" property.
# If the message is valid, it processes the message by removing excess messages from different containers to maintain a limit on the number of displayed messages.
# It then adds the received message to the appropriate container using the 'add_message_to_container' function.
#
# Parameters:
# - received_message (Dictionary): The dictionary containing the details of the received message.
#
# Returns:
# - This function does not return a value; it operates by processing and adding the received message to the appropriate container.
#
# Example usage:
# ```gdscript
# _on_message_received(received_message)
# ```

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

# Function to add a received message to the appropriate container.
#
# This function is responsible for adding a received message to the appropriate container in the chat UI. It extracts information from the received message,
# instantiates a new message slot control, sets the text of UI elements based on the received message, and determines the destination container based on the room and sender.
# If the message is in the "All Messages" room, it adds the message to the "All Messages" container and emits the 'all_message_received' signal. If the message is part of a private conversation,
# it adds the message to the player's or conversing user's messages container accordingly.
#
# Parameters:
# - received_message (Dictionary): The dictionary containing the details of the received message.
#
# Returns:
# - This function does not return a value; it operates by adding the received message to the appropriate container.
#
# Example usage:
# ```gdscript
# add_message_to_container(received_message)
# ```
func add_message_to_container(received_message: Dictionary) -> void:
	# Extract information from the received message
	var sender_username: String = received_message.sender
	var message_text: String = received_message.message
	var ts: int = received_message.ts
	var timestamp: String = Time.get_time_string_from_unix_time(ts)
	
	# Instantiate a new message slot control
	var slot_message: Control = message_slot.instantiate()

	# Set the text of UI elements in the message slot based on the received message
	slot_message.get_node('VBoxContainer/HBoxContainer/UsernameLabel').text = sender_username
	slot_message.get_node('VBoxContainer/HBoxContainer/TimestampLabel').text = timestamp
	slot_message.get_node('VBoxContainer/TextureRect/HBoxContainer/VBoxContainer/MessageLabel').text = message_text
	
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
			conversing_message.get_node('VBoxContainer/HBoxContainer/TimestampLabel').text = timestamp
			conversing_message.get_node('VBoxContainer/TextureRect/HBoxContainer/VBoxContainer/MessageLabel').text = message_text
			mutual_chat_vbox.add_child(conversing_message)

# Function to remove excess messages from a message container.
#
# This function checks if the number of child messages in a specified message container exceeds the specified limit.
# If the limit is exceeded, it retrieves the message control to be removed (beyond the limit) and frees up the resources associated with it.
#
# Parameters:
# - message_vbox (VBoxContainer): The VBoxContainer representing the message container.
# - limit (int): The maximum number of messages allowed in the container.
#
# Returns:
# - This function does not return a value; it operates by removing excess messages from the message container.
#
# Example usage:
# ```gdscript
# remove_excess_message(message_vbox, limit)
# ```
func remove_excess_message(message_vbox: VBoxContainer, limit: int) -> void:
	# Check if the number of child messages exceeds the specified limit
	if message_vbox.get_child_count() > limit:
		# Retrieve the message control to be removed (beyond the limit)
		var message_to_be_removed: Control = message_vbox.get_child(limit)
		# Free up the resources associated with the message control
		message_to_be_removed.queue_free()

# Callback function triggered when new messages are received in the "All Messages" room.
#
# This function adjusts the vertical scroll position to ensure the latest messages are visible in the "All Messages" tab.
#
# Returns:
# - This function does not return a value; it operates by adjusting the vertical scroll position.
#
# Example usage:
# ```gdscript
# _on_new_all_message_received()
# ```
func _on_new_all_message_received() -> void:
	# Adjust the vertical scroll position to show the latest messages on the "All Messages" tab
	all_message_scroll.scroll_vertical = all_chat_v_scroll.max_value

# Callback function triggered when new messages are received in the mutual chat.
#
# This function adjusts the vertical scroll position to ensure the latest mutual messages are visible in the mutual tab.
#
# Returns:
# - This function does not return a value; it operates by adjusting the vertical scroll position.
#
# Example usage:
# ```gdscript
# _on_new_mutual_message_received()
# ```
func _on_new_mutual_message_received() -> void:
	# Adjust the vertical scroll position to show the latest mutual messages on the mutual tab
	mutual_message_scroll.scroll_vertical = mutual_chat_v_scroll.max_value

# Callback function triggered when all messages are opened in a specific room.
#
# This function processes and displays the messages in the provided room, with special handling for the public "All Messages" room.
# It reverses the order of messages to display the latest ones first, formats the messages, and adds them to the appropriate container.
#
# Parameters:
# - `room_messages`: An array containing the messages in the room.
# - `room_id`: A string representing the ID of the room.
#
# Returns:
# - This function does not return a value; it operates by displaying messages in the appropriate container.
#
# Example usage:
# ```gdscript
# var room_messages = [...]  # An array containing messages in the room
# var room_id = "all"  # ID of the room
# _on_all_messages_opened(room_messages, room_id)
# ```
func _on_all_messages_opened(room_messages: Array, room_id: String) -> void:
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
			var ts: int = messages.ts
			
			# Disable the button if the message sender is the logged-in player
			if PLAYER.username == sender_username:
				all_message_slot.get_node("VBoxContainer/HBoxContainer/UsernameLabel/Button").disabled = true
			
			# Format and set the timestamp, sender, and message text in the message slot
			var timestamp: String = Time.get_time_string_from_unix_time(ts)
			all_message_slot.get_node('VBoxContainer/HBoxContainer/UsernameLabel').text = sender_username
			all_message_slot.get_node('VBoxContainer/HBoxContainer/TimestampLabel').text = timestamp
			all_message_slot.get_node('VBoxContainer/TextureRect/HBoxContainer/VBoxContainer/MessageLabel').text = message
			
			# Connect the button press to view the sender's profile
			all_message_slot.get_node("VBoxContainer/HBoxContainer/UsernameLabel/Button").pressed.connect(_on_view_profile.bind(sender_username))
			
			# Add the message slot to the "All Messages" container
			all_chat_vbox.add_child(all_message_slot)

# Callback function triggered when the "View Profile" button is pressed.
#
# This function uses the Social engine to view the profile of the specified username.
# It emits a signal, indicating that the "View Profile" button was pressed, and passes the player profile information.
#
# Parameters:
# - `username`: A string representing the username for which the profile is to be viewed.
#
# Returns:
# - This function does not return a value; it operates by viewing the profile and emitting a signal.
#
# Example usage:
# ```gdscript
# var username = "example_player"  # The username for which the profile is to be viewed
# _on_view_profile(username)
# ```
func _on_view_profile(username: String) -> void:
	# View the profile of the specified username through the Social engine
	BKMREngine.Social.view_profile(username)
	
	# Emit a signal indicating that the "View Profile" button was pressed, passing the player profile
	view_profile_pressed.emit(BKMREngine.Social.player_profile)

# Callback function triggered when the text input line is submitted.
#
# This function checks if the submitted message is empty; if so, it returns without sending.
# It prepares message data based on the current room and sends the message through the chat socket.
# The input line is cleared after sending the message.
#
# Parameters:
# - `message`: A string representing the submitted message.
#
# Returns:
# - This function does not return a value; it operates by preparing and sending the message.
#
# Example usage:
# ```gdscript
# var message = "Hello, world!"  # The message to be submitted
# _on_message_line_text_submitted(message)
# ```
func _on_message_line_text_submitted(message: String) -> void:
	# Check if the submitted message is empty; if so, return without sending
	if message == "":
		return
	
	# Prepare message data based on the current room
	var message_data: Dictionary = {}
	if current_room == "all":
		# Public chat room message
		message_data = { 
			"message": message, 
			"roomId": current_room, 
			"sender": PLAYER.username,
			"username": PLAYER.username
		}
	elif current_room == username_conversing:
		# Private message to a specific user
		message_data = { 
			"message": message, 
			"roomId": PLAYER.username, 
			"sender": PLAYER.username,
			"receiver": username_conversing,
			"seen": false
		}
	# Convert message data to JSON format
	var send_message: String = JSON.stringify(message_data)
	
	# Send the message through the chat socket
	BKMREngine.Chat.socket.send_text(send_message)
	
	# Clear the input line after sending the message
	message_input_line.text = ""

# Callback function triggered when the send message button is pressed.
#
# This function retrieves the message from the input line, checks if it is empty, and returns without sending if so.
# It prepares message data based on the current room and sends the message through the chat socket.
# The input line is cleared after sending the message.
#
# Returns:
# - This function does not have explicit parameters as it retrieves the message from the input line and uses the current room context.
# - It operates by preparing and sending the message.
#
# Example usage:
# ```gdscript
# _on_send_message_button_pressed()
# ```
func _on_send_message_button_pressed() -> void:
	# Get the message from the input line
	var message: String = message_input_line.text
	
	# Check if the message is empty; if so, return without sending
	if message == "":
		return
	
	# Prepare message data based on the current room
	var message_data: Dictionary
	if current_room == "all":
		# Public chat room message
		message_data = { 
			"message": message, 
			"roomId": "all",
			"username": PLAYER.username
		}
	elif current_room == username_conversing:
		# Private message to a specific user
		message_data = { 
			"message": message, 
			"roomId": PLAYER.username, 
			"sender": PLAYER.username,
			"receiver": username_conversing,
			"seen": false
		}
	# Convert message data to JSON format
	var send_message: String = JSON.stringify(message_data)
	
	# Send the message through the chat socket
	BKMREngine.Chat.socket.send_text(send_message)
	
	# Clear the input line after sending the message
	message_input_line.text = ""

func _on_chat_box_closed(_code: int, _reason: String) -> void:
	BKMREngine.Chat.connect_socket(url)
	if is_opened:
		pass

# Callback function triggered when the message tab changes.
#
# This function checks which tab is selected in the message tab container and updates the current room accordingly.
# If the "All Messages" tab is selected, it connects the signal to handle opening all messages.
# If a different tab is selected (e.g., private messages), it updates the current room accordingly.
#
# Parameters:
# - tab: The index of the selected tab.
#
# Returns:
# - This function operates by updating the current room and connecting signals based on the selected tab.
#
# Example usage:
# ```gdscript
# _on_message_tab_tab_changed(0)
# ```
func _on_message_tab_tab_changed(tab: int) -> void:
	# Check which tab is selected in the message tab container
	if tab == 0:
		# Switched to the "All Messages" tab
		current_room = "all"
		# Connect the signal to handle opening all messages
		BKMREngine.Chat.messages.connect(_on_all_messages_opened)
	elif tab == 1:
		pass
		# Switched to a different tab (e.g., private messages)
		#current_room = ""

# Callback function triggered when the close button is released.
#
# This function emits a signal indicating that the close button was pressed.
# It provides a way for other parts of the code to respond to the close button action.
#
# Returns:
# - This function operates by emitting the close_pressed signal.
#
# Example usage:
# ```gdscript
# _on_close_button_button_up()
# ```
func _on_close_button_button_up() -> void:
	close_pressed.emit()

# Callback function triggered when the chat button in the mutuals box is pressed.
#
# This function initiates a private conversation with the specified user.
# It requests private inbox data, retrieves messages, updates the chat panel, and displays the messages.
# Finally, it sets the current room, conversing username, and switches to the chat tab.
#
# Parameters:
# - `conversing_username`: The username of the user with whom the private conversation is initiated.
#
# Returns:
# - This function does not return a value; it operates by updating the chat panel and displaying messages.
#
# Example usage:
# ```gdscript
# _on_mutuals_box_chat_button_pressed("example_user")
# ```
func _on_mutuals_box_chat_button_pressed(conversing_username: String) -> void:
	# Request private inbox data for the specified user
	BKMREngine.Chat.get_private_inbox_data(conversing_username)
	await BKMREngine.Chat.get_inbox_messages_complete
	
	# Retrieve private messages for the conversation
	var private_messages: Array = BKMREngine.Chat.private_messages
	
	# Create or update the chat panel for the conversation
	add_chat_panel_from_mutual_box(conversing_username)
	
	# Display received messages in the appropriate containers
	display_received_messages(private_messages)
	
	# Set the current room, conversing username, and switch to the chat tab
	current_room = conversing_username
	username_conversing = conversing_username
	
	message_tab.current_tab = 1

# Function to create or update the chat panel for a private conversation.
#
# This function iterates through existing chat panels in the mutuals box and checks if a panel
# for the specified conversing username already exists. If it does, the function does nothing;
# mutuals_button.visible = trueotherwise, it creates a new chat panel, sets the username, and adds it to the mutuals box.
#
# Parameters:
# - `conversing_username`: The username of the user with whom the private conversation is initiated.
#
# Returns:
# - This function does not return a value; it operates by creating or updating the chat panel.
#
# Example usage:
# ```gdscript
# update_chat_panel("example_user")
# ```
func add_chat_panel_from_mutual_box(conversing_username: String) -> void:
	for slot: Control in chat_mutual_vbox.get_children():
		if slot.name == conversing_username:
			# The panel with the given name already exists, no need to add it again.
			return
	var chat_mutual_panel_count: int = chat_mutual_vbox.get_child_count()
	if chat_mutual_panel_count == 4:
		var excess_panel: Control = chat_mutual_vbox.get_child(3)
		excess_panel.queue_free()
	# Create a new chat panel since it doesn't exist
	var panel_chat_mutual: Control = chat_mutual_panel.instantiate()
	panel_chat_mutual.name = conversing_username
	panel_chat_mutual.get_node('Panel/VBoxContainer/Username').text = conversing_username
	panel_chat_mutual.get_node('Button').modulate = "ffffff00"
	panel_chat_mutual.get_node('Button').pressed.connect(_on_panel_chat_mutual_pressed.bind(conversing_username))
	
	chat_mutual_vbox.add_child(panel_chat_mutual)

func _on_panel_chat_mutual_pressed(conversing_username: String) -> void:
	if current_room != conversing_username:
		for messages: Control in mutual_chat_vbox.get_children():
			messages.queue_free()

			
		BKMREngine.Chat.get_private_inbox_data(conversing_username)
		await BKMREngine.Chat.get_inbox_messages_complete
		
		# Retrieve private messages for the conversation
		var private_messages: Array = BKMREngine.Chat.private_messages
		display_received_messages(private_messages)
	else:
		pass
	for slot: Control in chat_mutual_vbox.get_children():
		if slot.name == conversing_username:
			# Selected slot
			slot.get_node('Button').modulate = "ffffff00"
		else:
			# Unselected slots
			slot.get_node('Button').modulate = "ffffff"
			
	current_room = conversing_username
	
# Function to display received messages in the appropriate containers.
#
# This function iterates through each received message in the private_messages array and extracts
# information such as sender username, message text, and timestamp. It then instantiates a new message
# slot control, sets the text of UI elements based on the received message, and adds the message to the
# appropriate container (player's messages container or conversing user's messages container).
#
# Parameters:
# - `private_messages`: An array containing the received private messages.
#
# Returns:
# - This function does not return a value; it operates by displaying messages in the containers.
#
# Example usage:
# ```gdscript
# var received_messages = [{"username": "sender_user", "message": "Hello!", "ts": 1637389200}]
# display_received_messages(received_messages)
# ```
func display_received_messages(private_messages: Array) -> void:
	# Iterate through each received message in the private_messages array
	for received_message: Dictionary in private_messages:
		# Extract information from the received message
		var sender_username: String = received_message.sender
		var message_text: String = received_message.message
		var ts: int = received_message.ts
		var timestamp: String = Time.get_time_string_from_unix_time(ts)
		
		# Instantiate a new message slot control
		if received_message.sender == PLAYER.username:
			var slot_message: Control = message_slot.instantiate()
			# Set the text of UI elements in the message slot based on the received message
			slot_message.get_node('VBoxContainer/HBoxContainer/UsernameLabel').text = sender_username
			slot_message.get_node('VBoxContainer/HBoxContainer/TimestampLabel').text = timestamp
			slot_message.get_node('VBoxContainer/TextureRect/HBoxContainer/VBoxContainer/MessageLabel').text = message_text
			mutual_chat_vbox.add_child(slot_message)
		else:
			var conversing_message: Control = message_slot.instantiate()
			conversing_message.get_node('VBoxContainer/HBoxContainer/UsernameLabel').text = sender_username
			conversing_message.get_node('VBoxContainer/HBoxContainer/TimestampLabel').text = timestamp
			conversing_message.get_node('VBoxContainer/TextureRect/HBoxContainer/VBoxContainer/MessageLabel').text = message_text
			mutual_chat_vbox.add_child(conversing_message)
