extends Node

const BKMRLogger: Script = preload("res://BeatsKMREngine/utils/BKMRLogger.gd")
const BKMRUtils: Script = preload("res://BeatsKMREngine/utils/BKMRUtils.gd")

signal connected(url: String)
signal connect_failed
signal received(data: Dictionary)
signal closing
signal closed(code: int, reason: Dictionary)
signal get_inbox_messages_complete
signal messages(room_messages: Array, roomId: String)
signal message_single(message: Dictionary)

var host: String = BKMREngine.host

var Inbox: HTTPRequest
var wrInbox: WeakRef

var private_messages: Array

var receive_limit: int = 0
var connection_timeout: int = 10

var socket_url: String
var socket: WebSocketPeer = WebSocketPeer.new()
var socket_poll: String
var socket_state: WebSocketPeer.State

var socket_connected: bool = false
var closing_started: bool = false
var counter: int = 0

func _process(_delta: float) -> void:
	socket.poll()
	var auth_header: Array =  BKMREngine.add_jwt_token_headers()
	socket.set_handshake_headers(auth_header)

	socket_state = socket.get_ready_state()
	if socket_state == WebSocketPeer.STATE_OPEN:
		socket_connected = true
		closing_started = false
		connected.emit(socket_url)
		var _available: int = socket.get_available_packet_count()
		var message: String = socket.get_packet().get_string_from_utf8()
		var json: JSON = JSON.new()
		var error: Error = json.parse(message)
		if error == OK:
			if counter == 0:
				var room_messages: Array = json.data.data
				var room_id: String = json.data.handle
				messages.emit(room_messages, room_id)
				counter = 1
				return
			elif counter == 1:
				var single_message: Dictionary = json.data
				message_single.emit(single_message)
				return
	if socket_state == WebSocketPeer.STATE_CLOSED:
		counter = 0
		socket_connected = false
		var code: int = socket.get_close_code()
		var reason: String = socket.get_close_reason()
		closed.emit(code, reason)
		if socket_url == "":
			counter = 0
			socket.close()
			
func socket_send_message(message: Dictionary) -> void:
	var msg: String = JSON.stringify(message)
	var _message_sent: Error = socket.send_text(msg)
	
func connect_socket(url: String) -> bool:
	if socket_connected:
		return true
	socket_url = url
	var err: Error = socket.connect_to_url(url)
	if err != OK: # or socket_state != WebSocketPeer.STATE_OPEN:
		BKMRLogger.error("Socket is unable to connect to " + url)
		return false
	return true
	
func get_private_inbox_data(conversing_username: String) -> Node:
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	Inbox = prepared_http_req.request
	wrInbox  = prepared_http_req.weakref
	var _messages: int = Inbox.request_completed.connect(_onGetPrivateInboxData_request_completed)
	BKMRLogger.info("Calling BKMREngine to get mutual followers data")
	var request_url: String = host + "/api/social/mutual/" + conversing_username
	var _get_private_inbox_data: Error = await BKMREngine.send_get_request(Inbox, request_url)
	return self
	
func _onGetPrivateInboxData_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	if is_instance_valid(Inbox):
		BKMREngine.free_request(wrInbox, Inbox)
	if status_check:
		var json_body: Array = JSON.parse_string(body.get_string_from_utf8())
		private_messages = json_body
		get_inbox_messages_complete.emit()
