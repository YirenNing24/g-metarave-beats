extends Node

# WebSocketClient handles the communication with a WebSocket server for chat functionality.
# It includes signals for various events such as connection status changes, message reception, and inbox data retrieval.

# Importing necessary scripts
const BKMRLogger: Script = preload("res://BeatsKMREngine/utils/BKMRLogger.gd")
const BKMRUtils: Script = preload("res://BeatsKMREngine/utils/BKMRUtils.gd")

# Signals emitted by the WebSocketClient
signal connected(url: String)
#signal connect_failed
#signal received(data: Dictionary)
#signal closing
signal closed(code: int, reason: Dictionary)
signal get_inbox_messages_complete(private_messages: Array)
#signal chats(room_messages: Array, roomId: String)
signal chat_single(message: Dictionary)
signal server_time(server_time: Dictionary, latency: Dictionary)

# Variables to configure the WebSocketClient
var host: String = BKMREngine.host_ip
var port: String = BKMREngine.port
var url: String = "ws://" + host + "/api/ws"
#var url: String = "ws://" + host + port + "/api/ws"

#var url: String = "ws://" + "localhost" + port + "/api/ws"

var http_host: String = BKMREngine.host

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

var chat_messages: Array
var chat_handle: String

# Process function to handle WebSocket interactions and manage connection states.
func _process(_delta: float) -> void:
	var auth_header: Array = BKMREngine.add_jwt_token_headers()
	if BKMREngine.session == false:
		return
	if auth_header == []:
		return
	# Poll the WebSocket for incoming messages and update its state
	socket.poll()

	# Set authentication headers for the WebSocket handshake
	socket.set_handshake_headers(auth_header)

	# Get the current state of the WebSocket
	socket_state = socket.get_ready_state()
	
	# Handle different WebSocket states
	match socket_state:
		WebSocketPeer.STATE_OPEN:
			# If the WebSocket is open, update connection status and process incoming messages
			socket_connected = true
			closing_started = false
			connected.emit(socket_url)
			var _available: int = socket.get_available_packet_count()
			var message: String = socket.get_packet().get_string_from_utf8()
			var json: JSON = JSON.new()
			var error: Error = json.parse(message)
			if error == OK:
				if json.data.has("chat"):
					receive_chat(json)
				elif json.data.has("roomId"):
					receive_chat(json)
				elif json.data[0].has("serverTime"):
					receive_server_time(json)
					
		WebSocketPeer.STATE_CLOSED:
			# If the WebSocket is closed, update connection status and emit the 'closed' signal
			socket_connected = false
			var code: int = socket.get_close_code()
			var reason: String = socket.get_close_reason()
			
			closed.emit(code, reason)
			# Reconnect
			var _connect: bool = connect_socket()

# Connect to a WebSocket server
func connect_socket() -> bool:
	if socket_connected:
		return true
	socket_url = url
	var err: Error = socket.connect_to_url(url)
	if err != OK:
		# Log an error message if the connection fails
		BKMRLogger.error("Socket is unable to connect to " + url)
		return false
	return true
	
# Send a message through the WebSocket
func  _socket_send_data(data: Dictionary) -> void:
	var socket_data: String = JSON.stringify(data)
	var _data_sent: Error = socket.send_text(socket_data)

#region send and receive chat
func send_chat(message_data: Dictionary) -> void:
	var chat_message: String = JSON.stringify(message_data)
	var _data_sent: Error = socket.send_text(chat_message)

func receive_chat(json: JSON) -> void:
	match counter:
		0:
			var data: Array = json.data.chat
			var room_id: String = json.data.handle
			chat_messages = data
			chat_handle = room_id
			counter = 1
		1:
			var single_message: Dictionary = json.data
			chat_single.emit(single_message)
			
			
#endregion

#region server time and ping
func get_server_time() -> void:
	match socket_state:
		WebSocketPeer.STATE_CLOSED:
			return
		WebSocketPeer.STATE_OPEN:
			var start_time: float = Time.get_ticks_msec()
			var message: Dictionary = {"type": "ping", "timestamp": start_time}
			_socket_send_data(message)
			
func receive_server_time(time_data: JSON) -> void:
	var time: String = time_data.data[0]["serverTime"]
	var end_time: float = Time.get_ticks_msec()
	var ping: float = end_time - time_data.data[1]["timestamp"]

	server_time.emit(time, ping) 
#endregion

# Function to retrieve private inbox data for a specified user.
func get_private_inbox_data(conversing_username: String) -> Node:
	# Prepare an HTTP request for fetching private inbox data.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	Inbox = prepared_http_req.request
	wrInbox  = prepared_http_req.weakref
	
	# Connect the callback function to handle the completion of the private inbox data request.
	var _messages: int = Inbox.request_completed.connect(_onGetPrivateInboxData_request_completed)
	
	# Log the initiation of the request to retrieve inbox messages.
	BKMRLogger.info("Calling BKMREngine to get inbox messages")
	
	# Construct the request URL for fetching private inbox data for the specified user.
	var request_url: String = http_host + "/api/social/mutual/" + conversing_username
	
	# Send a GET request to retrieve the private inbox data.
	await BKMREngine.send_get_request(Inbox, request_url)
	
	# Return the current node for method chaining.
	return self

# Callback function to handle the completion of the private inbox data retrieval request.
func _onGetPrivateInboxData_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check if the HTTP response indicates success.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Free the HTTP request resource if it is still valid.
	if is_instance_valid(Inbox):
		BKMREngine.free_request(wrInbox, Inbox)
	
	# If the HTTP response indicates success, parse the JSON response body.
	if status_check:
		# Parse the JSON response body.
		var json_body: Array = JSON.parse_string(body.get_string_from_utf8())

		# Assign the parsed private messages to the corresponding variable.
		private_messages = json_body
		
		# Emit the 'get_inbox_messages_complete' signal to notify the completion of private inbox data retrieval.
		get_inbox_messages_complete.emit(json_body)
