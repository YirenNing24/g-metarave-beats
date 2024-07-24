extends Control

signal hit_display_data(note_accuracy: int, line: int, combo_value: int)

@onready var health_bar: TextureProgressBar = %HealthBar

@onready var boost_progress_bar: TextureProgressBar = %BoostProgressBar
@onready var score_label: Label = %ScoreLabel
@onready var username_label: Label = %UsernameLabel


@export var health: int = 100
@export var score: int = 0
@export var score_accuracy: float = 0

@export var total_combo: int = 0
@export var combo: int = 0
@export var max_combo: int = 0

@export var accuracy_rate: float = 0
@export var accuracy_label: String

@export var perfect: int = 0
@export var very_good: int = 0
@export var good: int = 0
@export var bad: int = 0
@export var miss: int = 0

@export var current_momentum: int = 0
@export var current_boost: int = 0
@export var boost_multiplier: int = 1

var map: String
var song_length: float
var artist: String

@export var final_stats: Dictionary
@export var note_stats: Dictionary

var tween: Tween
var boost_tween: Tween

func _ready() -> void:
	artist = SONG.artist
	health = clamp(health, 0, 100)  
	%MultiplayerSynchronizer.set_multiplayer_authority(1)
	
	
func connect_notes() -> void:
	for notes: Node3D in get_tree().get_nodes_in_group('ShortNote'):
		if !notes.hit_feedback.is_connected(hit_feedback):
			notes.hit_feedback.connect(hit_feedback)
		if !notes.hit_feedback.is_connected(add_score):
			notes.hit_feedback.connect(add_score)
		
	for notes: Node3D in get_tree().get_nodes_in_group('LongNote'):
		if !notes.hit_feedback.is_connected(hit_continued_feedback):
			notes.hit_continued_feedback.connect(hit_continued_feedback)
		if !notes.hit_feedback.is_connected(hit_feedback):
			notes.hit_feedback.connect(hit_feedback)
			
		if !notes.hit_feedback.is_connected(add_score):
			notes.hit_feedback.connect(add_score)
		
	for notes: Node3D in get_tree().get_nodes_in_group('ShortNote'):
		if !notes.hit_feedback.is_connected(hit_feedback):
			notes.hit_feedback.connect(hit_feedback)
		if !notes.hit_feedback.is_connected(add_score):
			notes.hit_feedback.connect(add_score)
		
	for notes: Node3D in get_tree().get_nodes_in_group('SwipeNote'):
		if !notes.hit_feedback.is_connected(hit_feedback):
			notes.hit_feedback.connect(hit_feedback)
		if !notes.hit_feedback.is_connected(add_score):
			notes.hit_feedback.connect(add_score)
		if !notes.hit_feedback.is_connected(boost_feedback):
			notes.boost_feedback.connect(boost_feedback)
			
			
func _process(_delta: float) -> void:
	if combo > max_combo:
		max_combo = combo
	calculate_accuracy_score()
	update_score_label()
	
	
#A function to update the score label
func update_score_label() -> void:
	score_label.text = format_number(score)


func reset() -> void:
	score = 0
	combo = 0
	accuracy_rate = 0
	perfect = 0
	very_good = 0
	good = 0
	bad = 0
	miss = 0
	final_stats = {
		"score" = score, 
		"combo" = max_combo,
		"accuracy" = accuracy_rate
		}


func calculate_accuracy_score() -> void:
	var total_notes: int = perfect + very_good + good + bad + miss
	if total_notes > 0:
		accuracy_rate = (float(200 * bad) + (400 * good) + (800 * very_good) + (1200 * perfect)) / float(1200 * (total_notes))
		accuracy_label = "%.2f" %(accuracy_rate * 100)


func add_score(_accuracy: int, _line: int) -> void:
	score = round(score + (score_accuracy +(score_accuracy * combo / 25)))


func hit_continued_feedback(note_accuracy: int, line: int ) -> void:
	if note_accuracy == 5:
		combo = 0
	elif note_accuracy != 4:
		set_boost_multiplier()
		var long_note_accuracy: int = 5 - note_accuracy
		combo = combo + 1
		total_combo = total_combo + 1
		score = round(score + (long_note_accuracy * combo * 5 * boost_multiplier))
	hit_display_data.emit(note_accuracy, line, combo)
	
	
func set_boost_multiplier() -> void:
	if current_boost != 1:
		boost_multiplier = current_boost
	else:
		boost_multiplier = 1
	if current_boost == 3 and current_momentum == 50:
		boost_multiplier = 4
	
	
func hit_feedback(note_accuracy: int, line: int) -> void:
	health = clamp(health, 0, 100)
	match note_accuracy:
		1:
			score_accuracy = 1200 * boost_multiplier
			combo += 1
			total_combo += 1
			perfect += 1
			health += 3
			animate_health()
			boost_feedback(false)
			hit_display_data.emit(note_accuracy, line, combo)
		2:
			score_accuracy = 800  * boost_multiplier
			combo += 1
			total_combo += 1
			very_good += 1
			health += 2
			animate_health()
		3:
			score_accuracy = 400
			combo += 1
			total_combo += 1
			good += 1
			health += 1
			animate_health()
			hit_display_data.emit(note_accuracy, line, combo)
		4:
			score_accuracy = 200
			bad += 1
			animate_health()
			hit_display_data.emit(note_accuracy, line, combo)
		5:
			score_accuracy = 0
			combo = 0
			miss += 1
			health_damage()
			animate_health()
			set_boost(true)
			hit_display_data.emit(note_accuracy, line, combo)


func health_damage() -> void:
	health -= 10


func animate_health() -> void:
	tween = get_tree().create_tween()
	var _health_tween: PropertyTweener = tween.tween_property(
		health_bar, 
		"value", 
		health, 0.1).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR )
	if health <= 0:
		game_over(false)


func boost_feedback(is_swipe_note: bool = false) -> void:
	current_momentum = clamp(current_momentum, 0, 50)
	# Increase momentum based on whether it's a swipe note
	if is_swipe_note:
		current_momentum += 15
	else:
		current_momentum += 20
	# Clamp again after the increase to ensure it stays within bounds
	current_momentum = clamp(current_momentum, 0, 50)
	
	# Set boost if current momentum reaches or exceeds 50
	if current_momentum == 50 and current_boost < 3:
		if current_boost == 2:
			set_boost()
		else:
			current_momentum = 0
			set_boost()

	elif current_momentum == 50 and current_boost == 3:
		set_boost()
	
	animate_momentum()


func set_boost(is_reset: bool = false) -> void:
	if is_reset:
		current_boost = 0
		current_momentum = 0
		animate_momentum()
	else:
		if current_boost < 3:
			current_boost += 1
			print("cur: ", current_boost)
	set_boost_multiplier()
	if current_boost < 3:
		boost_progress_texture_change() 
		
		
func boost_progress_texture_change() -> void:
	var momentum_to_string: String = str(current_boost)
	var texture_path: String = "res://UITextures/Progress/momentum"
	boost_progress_bar.texture_progress = load(texture_path + momentum_to_string + ".png")


func animate_momentum() -> void:
	boost_tween = get_tree().create_tween()
	var _momentum_tween: PropertyTweener = boost_tween.tween_property(
		boost_progress_bar, 
		"value", 
		current_momentum, 0.1).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR )


func _on_road_song_finished() -> void:
	game_over(true)
 

func _on_music_song_finished() -> void:
	game_over(true)


func game_over(is_finished: bool) -> void:
	final_stats = {
		score = score, 
		combo = total_combo ,
		max_combo = max_combo,
		accuracy = accuracy_rate,
		map =  SONG.map_selected.song_folder,
		finished = is_finished,
		songName = SONG.song_name
 
	}
	note_stats = {
		perfect =  perfect,
		very_good = very_good,
		good = good,
		bad = bad,
		miss = miss,
	}
	SONG.map_done_score = final_stats
	SONG.note_stats_score = note_stats
	
	var _load_scene: bool = await LOADER.load_scene(self, "res://UIScenes/game_over.tscn")
	LOADER.next_texture = preload("res://UITextures/BGTextures/game_over_bg.png")


func format_number(number: int) -> String:
	# Handle negative numbers by adding the "minus" sign in advance, as we discard it
	# when looping over the number.
	var formatted_number: String = "-" if sign(number) == -1 else ""
	var index: int = 0
	var number_string: String = str(abs(number))
	for digit: String in number_string:
		formatted_number += digit
		var counter: int = number_string.length() - index
		# Don't add a comma at the end of the number, but add a comma every 3 digits
		# (taking into account the number's length).
		if counter >= 2 and counter % 3 == 1:
			formatted_number += ","
		index += 1
	return formatted_number as String
