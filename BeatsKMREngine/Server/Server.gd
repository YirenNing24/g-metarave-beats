extends Node

signal server_checking_complete

# Preloaded scripts for utility functions and logging.
const BKMRUtils: Script = preload("res://BeatsKMREngine/utils/BKMRUtils.gd")
const BKMRLogger: Script = preload("res://BeatsKMREngine/utils/BKMRLogger.gd")

var websocket: WebSocketPeer = WebSocketPeer.new()
var latency_sum: float = 0.0
var ping_count: float = 0.0
const MAX_PINGS: float = 3.0
var start_time: float = 0.0
var complete: bool = false

const latency_test_urls: Array[String] = [
	"wss://api-vn.gmetarave.asia/api/placeholder",
	"wss://api-vn.gmetarave.asia/api/ping",
	"wss://api-sg.gmetarave.asia/api/ping",
	"wss://api-hk.gmetarave.asia/api/ping",
	"wss://api-kz.gmetarave.asia/api/ping",
	"wss://api-fn.gmetarave.asia/api/ping",
	"wss://api-mn.gmetarave.asia/api/ping",
	"wss://api-vn.gmetarave.asia/api/ping",
]
	
	
const api_server_urls: Array[String] = [
	"wss://api-vn.gmetarave.asia/api/placeholder",
	"https://api-vn.gmetarave.asia",
	"https://api-sg.gmetarave.asia",
	"https://api-hk.gmetarave.asia",
	"https://api-kz.gmetarave.asia",
	"https://api-fn.gmetarave.asia",
	"https://api-mn.gmetarave.asia",
	"https://api-vn.gmetarave.asia",
	
]
	
	
const game_server_urls: Array[String] = [
	"wss://api-vn.gmetarave.asia/api/placeholder",
	"wss://vn-game.gmetarave.asia",
	"wss://sg-game.gmetarave.asia",
	"wss://hk-game.gmetarave.asia",
	"wss://kz-game.gmetarave.asia",
	"wss://fn-game.gmetarave.asia",
	"wss://mn-game.gmetarave.asia",
	"wss://vn-game.gmetarave.asia",
]

var current_server_index: int = 0
var preferred_server: String = ""
var lowest_latency: float = INF  # Start with infinity as the initial lowest latency

var SavePreferredServer: HTTPRequest
var wrSavePreferredServer: WeakRef
signal save_preferred_server_complete(message: Dictionary)

const scene: PackedScene = preload("res://UIScenes/splash_screen.tscn")

func _ready() -> void:
	set_process(false)
	var _connect: int = save_preferred_server_complete.connect(_on_save_preferred_server_complete)
	
	
func player_server_check_complete() -> void:
	server_checking_complete.emit()
	
func set_server_urls() -> void:
	var preferred_server_api_index: int = latency_test_urls.find(preferred_server)
	
	BKMREngine.host = api_server_urls[preferred_server_api_index]
	BKMREngine.beats_host = game_server_urls[preferred_server_api_index]
	
	
func set_player_urls(player_server: String) -> void:
	var preferred_server_api_index: int = latency_test_urls.find(player_server)
	BKMREngine.host = "https://api-sg.gmetarave.asia"
	BKMREngine.beats_host = game_server_urls[preferred_server_api_index]
	preferred_server = BKMREngine.beats_host
	player_server_check_complete()
	
	
func connect_to_server() -> void:
	if current_server_index >= latency_test_urls.size():
		print("\n✅ Latency testing completed for all servers.")
		print("🏆 Preferred Server:", preferred_server, " | Lowest Latency:", lowest_latency, "ms")
		set_server_urls()
		return
	
	var server_url: String = latency_test_urls[current_server_index]
	print("\n🔍 Testing latency for:", server_url, " (", current_server_index + 1, "/", latency_test_urls.size(), ")")

	var err: int = websocket.connect_to_url(server_url)
	if err != OK:
		print("❌ Connection failed to:", server_url, " | Error Code:", err, "\n⏩ Moving to next server...")
		_on_connection_error()
	else:
		print("🟡 Connecting...")


func _process(_delta: float) -> void:
	websocket.poll()
	var state: int = websocket.get_ready_state()
	print("WebSocket State: ", state)

	if state == WebSocketPeer.STATE_OPEN:  # Connection established
		if ping_count == 0:
			_on_connection_established()
		
		while websocket.get_available_packet_count() > 0:
			var message: String = websocket.get_packet().get_string_from_utf8()
			var parsed_message: JSON = JSON.new()
			var parse_error: int = parsed_message.parse(message)
			
			if parse_error == OK:
				var data: Dictionary = parsed_message.data[0]
				
				if data.has("type") and data["type"] == "pong":
					handle_pong(data)
	elif state == WebSocketPeer.STATE_CONNECTING:  # Connection still in progress
		pass
	elif state == WebSocketPeer.STATE_CLOSED:  # Connection closed
		if preferred_server.is_empty():
			_on_connection_closed()
	


func _on_connection_established() -> void:
	print("Connected to server")
	send_ping()
	
	
func _on_connection_closed() -> void:
	print("Connection closed: Moving to the next server.")
	reset_ping_state()
	move_to_next_server()

func _on_connection_error() -> void:
	print("Connection error occurred. Moving to the next server.")

	reset_ping_state()
	move_to_next_server()



func send_ping() -> void:
	start_time = Time.get_ticks_msec()  # Millisecond precision
	var ping_message: Dictionary = { "type": "ping", "timestamp": start_time }
	var ping_json: String = JSON.stringify(ping_message)
	
	var err: int = websocket.send_text(ping_json)
	if err != OK:
		print("Failed to send ping: ", err)


func handle_pong(data: Dictionary) -> void:
	if not data.has("timestamp"):
		print("⚠️ Malformed pong message received.")
		return

	var client_sent_time: float = data["timestamp"]
	var round_trip_time: float = Time.get_ticks_msec() - client_sent_time
	latency_sum += round_trip_time
	ping_count += 1

	print("✅ Ping #", ping_count, " | Server:", latency_test_urls[current_server_index])
	print("   ↳ Latency:", round_trip_time, "ms")

	if ping_count < MAX_PINGS:
		send_ping()
	else:
		var average_latency: float = latency_sum / MAX_PINGS
		print("\n📊 Latency Test Complete for:", latency_test_urls[current_server_index])
		print("   ↳ Average Latency:", average_latency, "ms\n")

		if average_latency < lowest_latency:
			lowest_latency = average_latency
			preferred_server = latency_test_urls[current_server_index]

		websocket.close()
		reset_ping_state()
		move_to_next_server()


func reset_ping_state() -> void:
	if current_server_index == 0:
		current_server_index += 1
	# Reset latency and ping counters 
	latency_sum = 0.0
	ping_count = 0.0


func move_to_next_server() -> void:
	current_server_index += 1
	print("⏩ Moving to next server... (", current_server_index, "/", latency_test_urls.size(), ")")

	if current_server_index < latency_test_urls.size():
		connect_to_server()
	else:
		print("\n🏆 Best Server Selected:", preferred_server)
		print("   ↳ Lowest Latency:", lowest_latency, "ms")
	
	
func save_preferred_server(server_preferred: String) -> void:
	# Prepare an HTTP request for fetching private inbox data.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	SavePreferredServer = prepared_http_req.request
	wrSavePreferredServer= prepared_http_req.weakref
	
	# Connect the callback function to handle the completion of the private inbox data request.
	var _cards: int = SavePreferredServer.request_completed.connect(_onSavePreferedServer_request_completed)
	
	# Construct the request URL for fetching private inbox data for the specified user.
	var request_url: String = BKMREngine.host + "/api/save-preferred-server"
	var payload: Dictionary = { "link": server_preferred }
	# Send a GET request to retrieve the private inbox data.
	BKMREngine.send_post_request(SavePreferredServer, request_url, payload)
	
	
func _onSavePreferedServer_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check if the HTTP response indicates success.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# If the HTTP response indicates success, parse the JSON response body.
	if status_check:
		# Parse the JSON response body.
		var json_body: Dictionary = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body.has("error"):
				BKMRLogger.info(json_body.error)
				save_preferred_server_complete.emit(json_body)
			else:
				# Emit the 'get_inbox_messages_complete' signal to notify the completion of private inbox data retrieval.
				save_preferred_server_complete.emit(json_body)
		else:
			save_preferred_server_complete.emit({"error": "Unknown server error"})
	else:
		save_preferred_server_complete.emit({"error": "Unknown server error"})
	
	
func no_preferred_server() -> void:
	set_process(true)  # Ensure `_process` is running
	while preferred_server.is_empty():
		await get_tree().create_timer(10).timeout # Wait for a short period to avoid locking the main thread
		print("Waiting for preferred server...")
	save_preferred_server(preferred_server)
	set_process(false)
	
	for nodes: Variant  in get_tree().get_nodes_in_group("Splash"):
		nodes.queue_free()
	var _reload: Error = get_tree().change_scene_to_packed(scene)
	
	
func _on_save_preferred_server_complete(message: Dictionary) -> void:
	player_server_check_complete()
	if not message.has("error"):
		print("let's go!!!")
