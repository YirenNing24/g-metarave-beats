##TODO ADD loading screen 
extends Node

signal player_peer_id_received(id: int)
signal loading_start
signal server_game_started
signal classic_game_over_completed(	)

const server_peer_id: int = 1


func load_song(beatmap: String, audio_file: String) -> void:
	send_beatmap_info_to_server.rpc_id(server_peer_id, BKMREngine.Auth.access_token, beatmap, audio_file)
	

func loading_finished() -> void:
	start_game.rpc()
	server_game_started.emit()


@rpc
func send_unique_id_to_player(id_peer: int) -> void:
	player_peer_id_received.emit(id_peer)

@rpc
func start_loading() -> void:
	loading_start.emit()
	
	
@rpc
func classic_game_over() -> void:
	classic_game_over_completed.emit()


@rpc
func send_beatmap_info_to_server(_token: String, _beatmap: String) -> void:
	pass


@rpc
func start_game() -> void:
	pass
	
	
