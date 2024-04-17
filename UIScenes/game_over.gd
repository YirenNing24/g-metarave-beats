extends Control
### GAME MODE CLASSIC ####
@onready var score_label: Label = %ScoreLabel
@onready var combo_label: Label = %ComboLabel
@onready var max_combo_label: Label = %MaxComboLabel
@onready var accuracy_label: Label = %AccuracyLabel
@onready var finished_label: Label = %FinishedLabel
@onready var k_perfect_label: Label = %KPerfectLabel
@onready var very_good_label: Label  = %VeryGoodLabel
@onready var good_label: Label = %GoodLabel
@onready var bad_label: Label = %BadLabel
@onready var miss_label: Label = %MissLabel

@onready var background_texture: TextureRect = %BackgroundTexture

var final_stats: Dictionary  = SONG.map_done_score
var note_stats: Dictionary = SONG .note_stats_score

var song_name: String = SONG.song_name
var artist: String = SONG.artist
var difficulty: String = SONG.difficulty

# Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#display_score()
	#save_score_classic()
	#
#func display_score() -> void:
	## VALUE STATS
	#score_label.text = format_scores(str(final_stats.score))
	#combo_label.text = format_scores(str(final_stats.combo))
	#max_combo_label.text = format_scores(str(final_stats.max_combo))
	#
	#var rounded_accuracy: float = snapped(final_stats.accuracy, 0.01)
	#accuracy_label.text = (str(rounded_accuracy) + "%")
	#
	#if !final_stats.finished:
		#finished_label.text = "TRY AGAIN!"
		#
	##NOTES STATS
	#k_perfect_label.text = format_scores(str(note_stats.perfect))
	#very_good_label.text = format_scores(str(note_stats.very_good))
	#good_label.text = format_scores(str(note_stats.good))
	#bad_label.text = format_scores(str(note_stats.bad))
	#miss_label.text = format_scores(str(note_stats.miss))

func save_score_classic() -> void:
	var highscore: bool = is_highscore()
	var classic_score_stats: Dictionary = {
		difficulty = SONG.difficulty,
		score = final_stats.score,
		highscore = highscore,
		finalStats = final_stats,
		note_stats = note_stats
	}
	
	BKMREngine.Score.save_classic_high_score(classic_score_stats)

func is_highscore() -> bool:
	if BKMREngine.Score.classic_scores == []:
		return true
		
	for scores: Dictionary in BKMREngine.Score.classic_scores:
		if scores.scoreStats.finalStats.songName == song_name:
			if final_stats.score > scores.scoreStats.finalStats.score:
				return true
			else:
				return false
	return true 

func format_scores(value: String) -> String:
	var parts: Array = value.split(".")
	var wholePart: String = parts[0]
	
	# Add commas for every three digits in the whole part.
	var formattedWholePart: String = ""
	var digitCount: int = 0
	for i: int in range(wholePart.length() - 1, -1, -1):
		formattedWholePart = wholePart[i] + formattedWholePart
		digitCount += 1
		if digitCount == 3 and i != 0:
			formattedWholePart = "," + formattedWholePart
			digitCount = 0
	return formattedWholePart

# ADD HIGHSCORE BOOLEAN 

func _on_close_button_pressed() -> void:
	LOADER.previous_texture = background_texture.texture
	LOADER.next_texture = preload("res://UITextures/BGTextures/main_city.png")
	var _change_scene: bool = await LOADER.load_scene(self, "res://UIScenes/main_screen.tscn")
