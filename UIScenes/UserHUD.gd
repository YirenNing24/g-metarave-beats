extends Control

@export var max_health: int = 100

@onready var score_value = $"%ScoreValue"
@onready var hit_label = $"%HitInfo"
@onready var anim = $"%AnimationPlayer"

#var skill = preload("res://ui_scenes/Skill1.tscn")
#var icon_ui = preload("res://ui_scenes/IconUI.tscn")
#@onready var  ui_icon = []
#@onready var featured_icon = $"%FeaturedIcon"

var score_date
var score_time
var score
var score_acc = 0
var combo
var max_combo = 0
var acc
var perfect_note
var verygood_note
var good_note
var bad_note
var miss_note
var map
var health = 100
var final_stats
var note_stats
var song_length
var artist
var doubleup = 1
var string

var scoreboost = 0
var position_score = 0



func _ready():
	
	PlayerData.open_skill()
	artist = GAME_C.artist
	song_length = PlayerData.song_length
	display_card_set()
	reset()
	add_skills()
	card_boost()
	
	
func card_boost():
	
	var visual_score = 0
	var main_vocalist_score = 0
	var lead_vocalist_score = 0
	var main_dancer_score = 0
	var lead_dancer_score = 0
	var rapper_score = 0
	var lead_rapper_score = 0
	var faceofthegroup_score = 0
	var maknae_score = 0
	for slots in PlayerData.player_data[artist].keys():
		if PlayerData.player_data[artist][slots] != null:
			var score_boost = PlayerData.player_data.ItemData[PlayerData.player_data[artist][slots]]["ScoreBoost"]
			scoreboost += int(score_boost)
			if PlayerData.player_data.ItemData[PlayerData.player_data[artist][slots]]["Position"] == "Visual":
				visual_score = 1 * PlayerData.player_data.StatPointsSaved["Visual"]
			if PlayerData.player_data.ItemData[PlayerData.player_data[artist][slots]]["Position"] == "Main Vocalist":
				main_vocalist_score = 1 * PlayerData.player_data.StatPointsSaved["MainVocalist"]
			if PlayerData.player_data.ItemData[PlayerData.player_data[artist][slots]]["Position"] == "Lead Vocalist":
				lead_vocalist_score = 1 * PlayerData.player_data.StatPointsSaved["LeadVocalist"]
			if PlayerData.player_data.ItemData[PlayerData.player_data[artist][slots]]["Position"] == "Main Dancer":
				main_dancer_score = 1 * PlayerData.player_data.StatPointsSaved["MainDancer"]
			if PlayerData.player_data.ItemData[PlayerData.player_data[artist][slots]]["Position"] == "Lead Dancer":
				lead_dancer_score = 1 * PlayerData.player_data.StatPointsSaved["LeadDancer"]
			if PlayerData.player_data.ItemData[PlayerData.player_data[artist][slots]]["Position"] == "Rapper":
				rapper_score = 1 * PlayerData.player_data.StatPointsSaved["Rapper"]
			if PlayerData.player_data.ItemData[PlayerData.player_data[artist][slots]]["Position"] == "Lead Rapper":
				lead_rapper_score = 1 * PlayerData.player_data.StatPointsSaved["LeadRapper"]
			if PlayerData.player_data.ItemData[PlayerData.player_data[artist][slots]]["Position"] == "Face of The Group":
				faceofthegroup_score = 1 * PlayerData.player_data.StatPointsSaved["FaceOfTheGroup"]
			if PlayerData.player_data.ItemData[PlayerData.player_data[artist][slots]]["Position"] == "Maknae":
				maknae_score = 1 * PlayerData.player_data.StatPointsSaved["Maknae"]
				
			if PlayerData.player_data.ItemData[PlayerData.player_data[artist][slots]]["Position2"] == "Visual":
				visual_score += 0.5 * PlayerData.player_data.StatPointsSaved["Visual"]
			if PlayerData.player_data.ItemData[PlayerData.player_data[artist][slots]]["Position2"] == "Main Vocalist":
				main_vocalist_score += 0.5 * PlayerData.player_data.StatPointsSaved["MainVocalist"]
			if PlayerData.player_data.ItemData[PlayerData.player_data[artist][slots]]["Position2"] == "Lead Vocalist":
				lead_vocalist_score += 0.5 * PlayerData.player_data.StatPointsSaved["LeadVocalist"]
			if PlayerData.player_data.ItemData[PlayerData.player_data[artist][slots]]["Position2"] == "Main Dancer":
				main_dancer_score += 0.5 * PlayerData.player_data.StatPointsSaved["MainDancer"]
			if PlayerData.player_data.ItemData[PlayerData.player_data[artist][slots]]["Position2"] == "Lead Dancer":
				lead_dancer_score += 0.5 * PlayerData.player_data.StatPointsSaved["LeadDancer"]
			if PlayerData.player_data.ItemData[PlayerData.player_data[artist][slots]]["Position2"] == "Rapper":
				rapper_score += 0.5 * PlayerData.player_data.StatPointsSaved["Rapper"]
			if PlayerData.player_data.ItemData[PlayerData.player_data[artist][slots]]["Position2"] == "Lead Rapper":
				lead_rapper_score += 0.5 * PlayerData.player_data.StatPointsSaved["LeadRapper"]
			if PlayerData.player_data.ItemData[PlayerData.player_data[artist][slots]]["Position2"] == "Face of The Group":
				faceofthegroup_score += 0.5 * PlayerData.player_data.StatPointsSaved["FaceOfTheGroup"]
			if PlayerData.player_data.ItemData[PlayerData.player_data[artist][slots]]["Position2"] == "Maknae":
				maknae_score += 0.5 * PlayerData.player_data.StatPointsSaved["Maknae"]
	position_score = round(visual_score + main_vocalist_score + lead_vocalist_score + main_dancer_score + lead_dancer_score + rapper_score + lead_rapper_score + faceofthegroup_score + maknae_score)
	print(position_score, "posscore")
	print(scoreboost, "Scoreboost")
	
func add_skills():
	
	var group_skill = PlayerData.get(artist.replace(" ", "").to_lower() + "_skill")
	for names in group_skill[artist]:
		if group_skill[artist][names]["Equipped"] == true:
			var skill_button = skill.instance()
			var skill_name = group_skill[artist][names]["Skill"]
			if skill_name == "None" or null:
				return
			var skill_texture = load("res://ui_textures/" + skill_name + ".png")
			skill_button.texture_under = skill_texture
			skill_button.name = skill_name
			$"%SkillContainer".add_child(skill_button, true)
			
			
func display_card_set():
	
	for slots in PlayerData.player_data[artist].keys():
		if PlayerData.player_data[artist][slots] != null:
			ui_icon = icon_ui.instance()
			var item_name = PlayerData.player_data.ItemData[PlayerData.player_data[artist][slots]]["Name"]
			var item_era = PlayerData.player_data.ItemData[PlayerData.player_data[artist][slots]]["Era"]
			var item_tier = PlayerData.player_data.ItemData[PlayerData.player_data[artist][slots]]["Tier"]
			var icon_texture = load("res://ItemTextures/" + item_name + " " + (item_era + item_tier) + ".png")
			ui_icon.set_texture(icon_texture)
			ui_icon.name = slots
			$"%CardContainer".add_child(ui_icon)
			animate_card_set()
		
		
func animate_card_set():
	
	var cards = $"%CardContainer".get_children()
	if cards.size() < 2:
		return
	var cards_count = cards.size()
	var first_card = cards[0]
	var second_card = cards[1]
	var last_card = cards_count - 1
	var first_card_pos = first_card.rect_position
	var second_card_pos = second_card.rect_position
	
	first_card.hide()
	$"%Tween".interpolate_property(
		second_card,
		"rect_position",
		second_card_pos,
		first_card_pos,
		1,
		Tween.TRANS_ELASTIC,
		Tween.EASE_IN)
	$"%Tween".start()
	$"%FeaturedIcon".texture = first_card.texture
	
	yield($"%Tween", "tween_completed")
	$"%CardContainer".move_child(first_card, last_card)
	for icons in get_tree().get_nodes_in_group("IconUI"):
		if icons.texture == featured_icon.texture:
			icons.hide()
		else:
			icons.show()
		
		
func _on_Tween_tween_completed(_object, _key):
	
	yield(get_tree().create_timer(3.0), "timeout")
	animate_card_set()
	
func _process(_delta):
	
	if combo > max_combo:
		max_combo = combo
	calc_acc()
	score_value.set_text(str(score))
	
	
func reset():
	
	score = 0
	combo = 0
	acc = 0
	perfect_note = 0
	verygood_note = 0
	good_note = 0
	bad_note = 0
	miss_note = 0
	final_stats = {
		score = score, 
		combo = max_combo,
		accuracy = acc,}
		
		
func calc_acc():
	
	var total_notes = perfect_note + verygood_note + good_note + bad_note + miss_note
	if total_notes > 0:
		acc = (float(200 * bad_note) + (400 * good_note) + (800 * verygood_note) + (1200 * perfect_note)) / float(1200 * (total_notes))
		acc = "%.2f" %(acc * 100)
		
		
func add_score():
	
	score = round(score + (score_acc +(score_acc * combo / 25)))
	
	
# warning-ignore:shadowed_variable
func hit_continued_feedback(acc, line):
	
		acc = 5 - acc
		score = round(score + (acc * combo * 5))
		combo = combo + 1
		GameData.combo_count = combo
		hit_label.set_label(string,line,combo)
		
		
func hit_feedback(accuracy, line):
	
	if accuracy == 1:
		score_acc = (1200 + scoreboost + position_score) * doubleup 
		print(scoreboost, "sb")
		print(position_score, "ps")
		combo = combo + 1
		perfect_note += 1
		health = health + 3
		string = "K-PERFECT"
		hit_label.set_label(string, line,combo)
		animate_health()
	elif accuracy == 2:
		score_acc = (800 + scoreboost + position_score) * doubleup
		print(scoreboost, "sb")
		print(position_score, "ps")
		combo = combo + 1
		verygood_note += 1
		health = health + 2
		string = "VERY GOOD"
		hit_label.set_label(string, line,combo)
		animate_health()
	elif accuracy == 3:
		score_acc = (400 + scoreboost + position_score) * doubleup
		print(scoreboost, "sb")
		print(position_score, "ps")
		combo = combo + 1
		good_note += 1
		health = health
		string = "GOOD"
		hit_label.set_label(string, line,combo)
		animate_health()
	elif accuracy == 4:
		score_acc = 200
		print(scoreboost, "sb")
		print(position_score, "ps")
		bad_note += 1
		health = health
		string = "BAD"
		hit_label.set_label(string, line,combo)
		animate_health()
	elif accuracy == 5:
		score_acc = 0
		combo = 0
		miss_note += 1
		health = health - 10
		string = "MISS"
		hit_label.set_label(string, line,combo)
		animate_health()
		
		
func animate_health():
	
	health = clamp(health, 0, 100)
	$"%HealthPoints".set_text(str(health))
	GameData.combo_count = combo
	$"%HealthBarTween".interpolate_property(
		$"%HealthBar",
		"value",
		$"%HealthBar".value,
		health,
		0.1,
		Tween.TRANS_LINEAR,
		Tween.EASE_IN_OUT)
	$"%HealthBarTween".start()
	if health <= 0:
		game_over()
		
		
func song_finished():
	
	var result = "CLEARED!"
	final_stats = {
	score_time = score_time,
	score_date = score_date,
	score = score, 
	combo = max_combo,
	accuracy = acc,
	result = result,
	map = GAME_C.map_selected.song_folder}
	note_stats = {
		score_time = score_time,
		score_date = score_date,
		perfect_note = perfect_note,
		verygood_note = verygood_note,
		good_note = good_note,
		bad_note = bad_note,
		miss_note = miss_note}
	GAME_C.map_done_score = final_stats
	GAME_C.note_stats_score = note_stats
	
	
func game_over():
	
	var result = "GAME OVER!"
	final_stats = {
	score_time = score_time,
	score_date = score_date,
	score = score, 
	combo = max_combo,
	accuracy = acc,
	result = result,
	map = GAME_C.map_selected.song_folder}
	note_stats = {
		score_time = score_time,
		score_date = score_date,
		perfect_note = perfect_note,
		verygood_note = verygood_note,
		good_note = good_note,
		bad_note = bad_note,
		miss_note = miss_note}
	GAME_C.map_done_score = final_stats
	GAME_C.note_stats_score = note_stats
	# warning-ignore:return_value_discarded
	GameLoading.game_over = true
	get_tree().change_scene("res://ui_scenes/GameOver2.tscn")
	
	
func format_number(number: int) -> String:
	# Handle negative numbers by adding the "minus" sign in advance, as we discard it
	# when looping over the number.
	var formatted_number := "-" if sign(number) == -1 else ""
	var index := 0
	var number_string := str(abs(number))
	
	for digit in number_string:
		formatted_number += digit
	
		var counter := number_string.length() - index
		
		# Don't add a comma at the end of the number, but add a comma every 3 digits
		# (taking into account the number's length).
		if counter >= 2 and counter % 3 == 1:
			formatted_number += ","
			
		index += 1
	return formatted_number
