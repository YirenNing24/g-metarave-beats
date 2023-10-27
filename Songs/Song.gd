extends Node

signal set_selected_map(audio_file: String)

var map_selected: Dictionary
var map_done_score: int

var note_stats_score: int
var note_stats: int
var song_name: String
var locked: bool = false

#var equipment_data
#var loot_data = {}
#
#var kmr
#var beats
#var doubleup_score
#
#var game_mode
#var difficulty_mode
#
var artist: String


func set_map(audio_file: String) -> void:
	set_selected_map.emit(audio_file)
	
	


