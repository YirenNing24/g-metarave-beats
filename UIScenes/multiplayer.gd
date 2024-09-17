extends Node

# Signals to communicate with other nodes or scripts.
signal player_peer_id_received(id: int)  # Emitted when the player's unique peer ID is received.
signal loading_start(peer_id: int)  # Emitted to indicate the start of the loading screen.
signal server_game_started  # Emitted when the server has started the game.
signal classic_game_over_completed()  # Emitted when the classic game over process is completed.


# Sends the beatmap and audio file information to the server.
func load_song(beatmap: String, audio_file: String, picker_y_position: float) -> void:
	send_beatmap_info_to_server.rpc_id(1, BKMREngine.Auth.access_token, beatmap, audio_file, picker_y_position)
	
	
# Called when the loading is finished and the game is ready to start.
func loading_finished(peer_id: int) -> void:
	start_game.rpc(peer_id)
	server_game_started.emit(peer_id)


# Remote procedure call to send the unique peer ID to the player.
@rpc
func send_unique_id_to_player(id_peer: int) -> void:
	print("unique ng ba: ", id_peer)
	PLAYER.peer_id = id_peer
	player_peer_id_received.emit(id_peer)


# Remote procedure call to signal the start of the loading process.
@rpc
func start_loading(peer_id: int) -> void:
	print("loading peer id: ", peer_id)
	loading_start.emit(peer_id)
	
	
# Remote procedure call to signal that the classic game over process is completed.
@rpc
func classic_game_over() -> void:
	classic_game_over_completed.emit()


# Remote procedure call to send beatmap and audio file information to the server.
@rpc
func send_beatmap_info_to_server(_token: String, _beatmap: String, _audio_file: String, _picker_y_position: float) -> void:
	pass
	
	
# Remote procedure call to start the game.
@rpc
func start_game() -> void:
	pass
