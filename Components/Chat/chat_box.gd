extends Control

@onready var all_slots: Node
@onready var slide_button: TextureButton = $SlideButton
@onready var message_scroll: ScrollContainer = %MessageScroll

@onready var all_vbox: VBoxContainer = %AllVBox
@onready var v_scroll: VScrollBar
@onready var message_line: LineEdit = %MessageLine

signal slide_pressed(is_opened: bool)
signal message_sent(message: Dictionary)
signal view_profile_pressed(player_profile: Dictionary)

var message_box: PackedScene = preload("res://Components/Chat/chat_message.tscn")
var username: String = PLAYER.username
var is_opened: bool = false
var all: Array


func _ready() -> void:
	BKMREngine.Chat.messages.connect(_on_messages_opened)
	BKMREngine.Chat.message_single.connect(_on_message_received)
	
	v_scroll = message_scroll.get_v_scroll_bar()
	var _v_scroll: int = v_scroll.changed.connect(_on_new_message)
	
	
func _on_slide_button_pressed() -> void:
	slide_pressed.emit(is_opened)
	
func _on_main_screen_chat_opened(state: bool) -> void:
	is_opened = state
	
func _on_messages_opened(room_messages: Array, room_id: String) -> void:
	match room_id:
		"all":
			all = room_messages
			all.reverse()
			for messages: Dictionary in all:
				all_slots = message_box.instantiate()
				var sender_username: String = messages.username
				var message: String = messages.message
				var ts: int = messages.ts
				
				var _timestamp: String = Time.get_time_string_from_unix_time(ts)
				all_slots.get_node('VBoxContainer/HBoxContainer/Username').text = sender_username
				all_slots.get_node('VBoxContainer/TextureRect/VBoxContainer/Message').text = message
				all_slots.get_node('VBoxContainer/HBoxContainer/Username/Button').pressed.connect(_on_view_profile.bind(username))
				
				all_vbox.add_child(all_slots)
				
				
func _on_message_received(message: Dictionary) -> void:
	if !message:
		return
	if !message.has("roomId"):
		return
	if message.roomId == "all":
		var msg_slot:Node
		msg_slot = message_box.instantiate()
		@warning_ignore("shadowed_variable")
		var username: String = message.username
		var msg: String = message.message
		var ts: int = message.ts
		var _timestamp:String = Time.get_time_string_from_unix_time(ts)
		
		msg_slot.get_node('VBoxContainer/HBoxContainer/Username').text = username
		msg_slot.get_node('VBoxContainer/TextureRect/VBoxContainer/Message').text = msg
		all_vbox.add_child(msg_slot)
			
func _on_new_message() -> void:
	message_scroll.scroll_vertical = v_scroll.max_value
	
func _on_message_line_text_submitted(message: String) -> void:
	if message == "":
		return
	message_sent.emit({"message": message, "roomId": "all", "username": username})
	message_line.text = ""

func _on_view_profile(_username: String) -> void:
	
	BKMREngine.Social.view_profile("nashar")
	view_profile_pressed.emit(BKMREngine.Social.player_profile)
