extends Node

signal set_selected_map(audio_file)

var map_selected = null
var map_done_score

var note_stats_score
var note_stats
var song_name
var locked = false

var equipment_data
var loot_data = {}

var kmr
var beats
var doubleup_score

var game_mode
var difficulty_mode

var artist


func set_map(audio_file):
	set_selected_map.emit(audio_file)
	
	


