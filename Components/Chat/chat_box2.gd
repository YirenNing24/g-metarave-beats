extends Control

@onready var message_slot: PackedScene = preload("res://Components/Chat/chat_message2.tscn")
@onready var chat_mutual_panel: Control = preload("res://Components/Chat/chat_mutual_panel.tscn").instantiate()

signal sent_message(message: Dictionary)
signal all_message_received(received_message: Dictionary)
signal close_pressed

@onready var message_input_line: LineEdit = %MessageInputLine
@onready var all_chat_vbox: VBoxContainer = %AllChatVBox
@onready var all_message_scroll: ScrollContainer = %AllMessageScroll
@onready var all_chat_v_scroll: VScrollBar = all_message_scroll.get_v_scroll_bar()

@onready var mutual_chat_vbox: VBoxContainer = %MutualChatVBox
@onready var mutual_message_scroll: ScrollContainer = %MutualMessageScroll
@onready var mutual_chat_v_scroll: VScrollBar = mutual_message_scroll.get_v_scroll_bar()

var host: String = BKMREngine.host_ip
var url: String = "ws://" + host + "/api/chats/"
var username: String = PLAYER.username

var current_room: String = "all"

var chat_connected: bool = false
var is_opened: bool = false

func _ready() -> void:
	await BKMREngine.Chat.connect_socket(url + "all")
	BKMREngine.Chat.message_single.connect(_on_message_received)
	BKMREngine.Chat.messages.connect(_on_all_messages_opened)
	BKMREngine.Chat.closed.connect(_on_chat_box_closed)
	
	var _v_scroll: int = all_chat_v_scroll.changed.connect(_on_new_all_message_received)
	
	
func _on_message_received(received_message: Dictionary) -> void:
	if !received_message:
		return
		
	if !received_message.has("roomId"):
		return
	else:
		if received_message.roomId == "all":
			if all_chat_vbox.get_child_count() > 30:
				var remove_message: Control = all_chat_vbox.get_child(30)
				remove_message.queue_free()

			all_message_received.emit(received_message)
			
			var sender_username: String = received_message.username
			var message_text: String = received_message.message
			var ts: int = received_message.ts
			var timestamp: String = Time.get_time_string_from_unix_time(ts)
			
			var slot_message: Control = message_slot.instantiate()
			slot_message.get_node('VBoxContainer/HBoxContainer/UsernameLabel').text = sender_username
			slot_message.get_node('VBoxContainer/HBoxContainer/TimestampLabel').text = timestamp
			slot_message.get_node('VBoxContainer/TextureRect/HBoxContainer/VBoxContainer/MessageLabel').text = message_text
			all_chat_vbox.add_child(slot_message)
			
		elif received_message.roomId == PLAYER.username:
			if mutual_chat_vbox.get_child_count() > 30:
				var remove_message: Control = mutual_chat_vbox.get_child(30)
				remove_message.queue_free()
				
			var sender_username: String = received_message.username
			var message_text: String = received_message.message
			var ts: int = received_message.ts
			var timestamp: String = Time.get_time_string_from_unix_time(ts)
			
			var slot_message: Control = message_slot.instantiate()
			slot_message.get_node('VBoxContainer/HBoxContainer/UsernameLabel').text = sender_username
			slot_message.get_node('VBoxContainer/HBoxContainer/TimestampLabel').text = timestamp
			slot_message.get_node('VBoxContainer/TextureRect/VBoxContainer/MessageLabel').text = message_text
			mutual_chat_vbox.add_child(slot_message)

func _on_new_all_message_received() -> void:
	all_message_scroll.scroll_vertical = all_chat_v_scroll.max_value

func _on_all_messages_opened(room_messages: Array, room_id: String) -> void:
	if room_id == "all":
		var all_room_messages: Array
		all_room_messages = room_messages
		all_room_messages.reverse()
		for messages: Dictionary in all_room_messages:
			var all_message_slot: Control = message_slot.instantiate()
			
			var sender_username: String = messages.username
			var message: String = messages.message
			var ts: int = messages.ts
			#if BKMREngine.Auth.logged_in_player == sender_username:
				#all_message_slots.get_node("VBoxContainer/HBoxContainer/Username/Button").disabled = true
			var timestamp: String = Time.get_time_string_from_unix_time(ts)
			all_message_slot.get_node('VBoxContainer/HBoxContainer/UsernameLabel').text = sender_username
			all_message_slot.get_node('VBoxContainer/HBoxContainer/TimestampLabel').text = timestamp
			all_message_slot.get_node('VBoxContainer/TextureRect/HBoxContainer/VBoxContainer/MessageLabel').text = message
			#all_message_slots.get_node('VBoxContainer/HBoxContainer/Username/Button').pressed.connect(_on_view_profile.bind(sender_username))
			all_chat_vbox.add_child(all_message_slot)

func _on_message_line_text_submitted(message: String) -> void:
	if message == "":
		return
		
	var message_data: Dictionary = { 
		"message": message, 
		"roomId": current_room, 
		"username": username 
		}
		
	var send_message: String = JSON.stringify(message_data)
	BKMREngine.Chat.socket.send_text(send_message)
	message_input_line.text = ""
	
func _on_send_message_button_pressed() -> void:
	var message: String = message_input_line.text
	if message == "":
		return
	if current_room == "all":
		var message_data: Dictionary = { 
			"message": message, 
			"roomId": current_room, 
			"username": username 
			}
		var send_message: String = JSON.stringify(message_data)
		BKMREngine.Chat.socket.send_text(send_message)
	else:
		var message_data: Dictionary = { 
			"message": message, 
			"roomId": current_room, 
			"username": username,
			"receiver": current_room
			}
		var send_message: String = JSON.stringify(message_data)
		BKMREngine.Chat.socket.send_text(send_message)
		
	message_input_line.text = ""

func _on_chat_box_closed(_code: int, _reason: String) -> void:
	BKMREngine.Chat.connect_socket(url + "all")
	if is_opened:
		pass
		
func _on_tab_container_tab_clicked(tab: int) -> void:
	if tab == 0:
		current_room = "all"
		BKMREngine.Chat.messages.connect(_on_all_messages_opened)
	if tab == 1:
		current_room = PLAYER.username
		
func _on_close_button_button_up() -> void:
	close_pressed.emit()
