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

var recharge_progress: float = 0.0
var time_until_next_recharge : int
var recharge_interval : int = 60 * 60 * 1000 # 1 hour in milliseconds

var song_name: String = SONG.song_name
var artist: String = SONG.artist
var difficulty: String = SONG.difficulty
var peer_id: int = PLAYER.peer_id


func _ready() -> void:
	%LoadingPanel.fake_loader()
	hud_data()
	signal_connect()
	var _1: int = MULTIPLAYER.classic_game_over_completed.connect(display_score)
	#BKMREngine.Score.get_classic_high_score_single(peer_id)
	#BKMREngine.Score.get_classic_highscore_single.connect(_on_get_classic_highscore_single)
	
	#display_score()
	
func signal_connect() -> void:
	var _connect: int = PLAYER.new_data_received.connect(hud_data)
	
	
func hud_data() -> void:
	BKMREngine.Energy.get_energy_drink()
	display_hud()
	
	
func energy_hud() -> void:
	%Energy.text = str(PLAYER.current_energy) + " " + "/" + " " + str(PLAYER.max_energy)
	if PLAYER.time_until_next_recharge != 0:
		start_recharge_countdown(PLAYER.time_until_next_recharge)
	
	
func start_recharge_countdown(time_until_next: int) -> void:
	time_until_next_recharge = time_until_next
	recharge_progress = 0.0
	
	
func _process(delta: float) -> void:
	if PLAYER.current_energy >= PLAYER.max_energy:
		# Max energy reached, hide recharge label
		%EnergyRecharge.visible = false
		return

	# Recharge countdown is active
	time_until_next_recharge -= int(delta * 1000)
	if time_until_next_recharge > 0:
		recharge_progress = 100.0 - (float(time_until_next_recharge) / float(recharge_interval)) * 100.0
		%EnergyRecharge.text = str(int(recharge_progress)) + "%"
		%EnergyRecharge.visible = true
	else:
		# Recharge complete: add energy and reset countdown
		PLAYER.current_energy += 1
		%Energy.text = str(PLAYER.current_energy) + " / " + str(PLAYER.max_energy)

		if PLAYER.current_energy < PLAYER.max_energy:
			time_until_next_recharge = recharge_interval
			%EnergyRecharge.text = "1%"
		else:
			# Energy is maxed out, hide recharge progress
			%EnergyRecharge.visible = false
	
	
func display_hud() -> void:
	%BeatsBalance.text = PLAYER.beats_balance
	%GMR.text = PLAYER.gmr_balance
	
	
#func _on_get_classic_highscore_single(score: Array) -> void:
	#if !score.is_empty():
		#var single_score: Dictionary = score[0]
		#display_score(single_score) 
	#else:
		#BKMREngine.Score.get_classic_high_score_single(peer_id)
	
	
func display_score(rewards: Dictionary) -> void:
	var single_score: Dictionary = MULTIPLAYER.classic_score_stats
	score_label.text = format_scores(str(single_score["score"]))
	combo_label.text = format_scores(str(single_score["combo"]))
	max_combo_label.text = format_scores(str(single_score["maxCombo"]))
	
	var rounded_accuracy: float = snapped(single_score["accuracy"], 0.01)
	accuracy_label.text = (str(rounded_accuracy * 100) + "%")
	
	if not single_score.finished:
		finished_label.text = "TRY AGAIN!"
		
	#NOTES STATS
	k_perfect_label.text = format_scores(str(single_score["perfect"]))
	very_good_label.text = format_scores(str(single_score["veryGood"]))
	good_label.text = format_scores(str(single_score["good"]))
	bad_label.text = format_scores(str(single_score["bad"]))
	miss_label.text = format_scores(str(single_score["miss"]))
	
	%ExperienceValue.text = str(rewards["experienceGained"])
	%BeatsGainedValue.text = str(rewards["beatsReward"])
	
	BKMREngine.beats_server_peer_close()
	%LoadingPanel.tween_kill()
	BKMREngine.Auth.validate_player_session()
	
	
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
	
	
func _on_close_button_pressed() -> void:
	LOADER.previous_texture = background_texture.texture
	LOADER.next_texture = preload("res://UITextures/BGTextures/main_city.png")
	var _change_scene: bool = await LOADER.load_scene(self, "res://UIScenes/main_screen.tscn")
