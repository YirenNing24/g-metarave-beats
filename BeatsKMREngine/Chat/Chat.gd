extends Node

# WebSocketClient handles the communication with a WebSocket server for chat functionality.
# It includes signals for various events such as connection status changes, message reception, and inbox data retrieval.

# Importing necessary scripts
const BKMRLogger: Script = preload("res://BeatsKMREngine/utils/BKMRLogger.gd")
const BKMRUtils: Script = preload("res://BeatsKMREngine/utils/BKMRUtils.gd")

# Signals emitted by the WebSocketClient
signal connected(url: String)
signal connect_failed
signal received(data: Dictionary)
signal closing
signal closed(code: int, reason: Dictionary)
signal get_inbox_messages_complete
signal messages(room_messages: Array, roomId: String)
signal message_single(message: Dictionary)

# Variables to configure the WebSocketClient
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

# Process function to handle WebSocket interactions and manage connection states.
# Parameters:
# - _delta (float): The time elapsed since the last frame.
# Returns:
# - void
func _process(_delta: float) -> void:
	# Poll the WebSocket for incoming messages and update its state
	socket.poll()
	
	# Set authentication headers for the WebSocket handshake
	var auth_header: Array = BKMREngine.add_jwt_token_headers()
	socket.set_handshake_headers(auth_header)

	# Get the current state of the WebSocket
	socket_state = socket.get_ready_state()
	
	# Handle different WebSocket states
	if socket_state == WebSocketPeer.STATE_OPEN:
		# If the WebSocket is open, update connection status and process incoming messages
		socket_connected = true
		closing_started = false
		connected.emit(socket_url)
		var _available: int = socket.get_available_packet_count()
		var message: String = socket.get_packet().get_string_from_utf8()
		var json: JSON = JSON.new()
		var error: Error = json.parse(message)
		if error == OK:
			if counter == 0:
				# Process room messages and emit the 'messages' signal
				var room_messages: Array = json.data.data
				var room_id: String = json.data.handle
				messages.emit(room_messages, room_id)
				counter = 1
				return
			elif counter == 1:
				# Process single messages and emit the 'message_single' signal
				var single_message: Dictionary = json.data
				message_single.emit(single_message)
				return
	elif socket_state == WebSocketPeer.STATE_CLOSED:
		# If the WebSocket is closed, update connection status and emit the 'closed' signal
		counter = 0
		socket_connected = false
		var code: int = socket.get_close_code()
		var reason: String = socket.get_close_reason()
		closed.emit(code, reason)
		if socket_url == "":
			# Close the WebSocket if the URL is empty
			counter = 0
			socket.close()

# Send a message through the WebSocket
func socket_send_message(message: Dictionary) -> void:
	var msg: String = JSON.stringify(message)
	var _message_sent: Error = socket.send_text(msg)

# Connect to a WebSocket server
func connect_socket(url: String) -> bool:
	if socket_connected:
		return true
	socket_url = url
	var err: Error = socket.connect_to_url(url)
	if err != OK:
		# Log an error message if the connection fails
		BKMRLogger.error("Socket is unable to connect to " + url)
		return false
	return true

# Function to retrieve private inbox data for a specified user.
# Parameters:
# - conversing_username (String): The username of the user for whom the private inbox data is retrieved.
# Returns:
# - Node: The current node for method chaining.
func get_private_inbox_data(conversing_username: String) -> Node:
	# Prepare an HTTP request for fetching private inbox data.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	Inbox = prepared_http_req.request
	wrInbox  = prepared_http_req.weakref
	
	# Connect the callback function to handle the completion of the private inbox data request.
	var _messages: int = Inbox.request_completed.connect(_onGetPrivateInboxData_request_completed)
	
	# Log the initiation of the request to retrieve mutual followers data.
	BKMRLogger.info("Calling BKMREngine to get mutual followers data")
	
	# Construct the request URL for fetching private inbox data for the specified user.
	var request_url: String = host + "/api/social/mutual/" + conversing_username
	
	# Send a GET request to retrieve the private inbox data.
	var _get_private_inbox_data: Error = await BKMREngine.send_get_request(Inbox, request_url)
	
	# Return the current node for method chaining.
	return self

# Callback function to handle the completion of the private inbox data retrieval request.
# Parameters:
# - _result (int): The result of the HTTP request.
# - response_code (int): The HTTP response code.
# - headers (Array): The array of HTTP headers received in the response.
# - body (PackedByteArray): The packed byte array containing the response body.
# Returns:
# - void
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
		get_inbox_messages_complete.emit()
