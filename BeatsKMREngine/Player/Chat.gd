extends Node

const BKMRLogger: Script = preload("res://BeatsKMREngine/utils/BKMRLogger.gd")

signal connected(url: String)
signal connect_failed
signal received(data: Dictionary)
signal closing
signal closed(code, reason)

signal messages(room_messages: Array, roomId: String)
signal message_single(message: Dictionary)

var receive_limit: int = 0
var connection_timeout: int = 10

var socket_url: String
var socket: WebSocketPeer = WebSocketPeer.new()

var socket_state:
	get:
		socket.poll()
		return socket.get_ready_state()
		
var socket_connected: bool = false
var closing_started: bool = false
var counter: int = 0

func _process(_delta: float):
	socket.poll()
	if socket_state == WebSocketPeer.STATE_OPEN:
		socket_connected = true
		closing_started = false
		connected.emit(socket_url)
		var _available = socket.get_available_packet_count()
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
				var single_message: String = json.data
				message_single.emit(single_message)
				return
	if socket_state == WebSocketPeer.STATE_CLOSED:
		counter = 0
		socket_connected = false
		var code: int = socket.get_close_code()
		var reason: String = socket.get_close_reason()
		socket.poll()
		closed.emit(code, reason)
		if socket_url == "":
			counter = 0
			socket.close()
			
			
func socket_send_message(message: Dictionary) -> void:
	var msg = JSON.stringify(message)
	socket.send(msg)
	
func connect_socket(url: String) -> bool:
	if socket_connected:
		return true

	socket_url = url
	var err: Error = socket.connect_to_url(url)
	if err != OK: # or socket_state != WebSocketPeer.STATE_OPEN:
		BKMRLogger.error("Socket is unable to connect to " + url)
		return false
	return true
