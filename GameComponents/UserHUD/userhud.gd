extends Control

signal hit_display_data(note_accuracy: int, line: int, combo_value: int)

signal pause_button_pressed
signal play_button_pressed

@onready var health_bar: TextureProgressBar = %HealthBar
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
@export var current_boost: int = 1
@export var boost_multiplier: int = 1
var score_boost: int = 0

@export var boost_current: String

var game_over_called: bool = false
var map: String

var song_length: float
var elapsed_time: float
var song_name: String
var difficulty: String

@export var final_stats: Dictionary
@export var note_stats: Dictionary

var tween: Tween
var left_boost_tween: Tween

var card_texture_tween: Tween
var card_textures_array: Array[Texture] = []
var current_card_texture_index: int = 0

@onready var card_texture2_original_position: Vector2 = %CardTexture2.position
@export var momentum_to_string: String = ""


func _ready() -> void:
	connect_signals()
	health = clamp(health, 0, 100) 
	username_label.text = PLAYER.username
	#%EffectsOnLeft.material.set_shader_parameter("color1", "ffffff01")func add_score(_accuracy: int, _line: int) -> void:
	 
	
func connect_signals() -> void:
	BKMREngine.Score.save_classic_highscore_complete.connect(_on_save_classic_highscore_complete)
	BKMREngine.Inventory.group_card_equip_complete.connect(equipped_cards_texture)
	
	
func _physics_process(_delta: float) -> void:
	calculate_accuracy_score()

	if combo > max_combo:
		max_combo = combo
	if game_over_called == false:
		if health <= 0:
			game_over(false)  # Call game over when health reaches zero
	
func calculate_accuracy_score() -> void:
	var total_notes: int = perfect + very_good + good + bad + miss
	accuracy_rate = (float(0 * miss) + (200 * bad) + (400 * good) + (800 * very_good) + (1200 * perfect)) / float(1200 * total_notes)
	
	
func add_score(_accuracy: int, _line: int) -> void:
	var base_score: float = score_accuracy * boost_multiplier
	var combo_bonus: float = max(1.0, 1.0 + (combo / 20.0))  # Ensures at least x1 multiplier
	score = round(score + (base_score * combo_bonus))
	%ScoreLabel.text = str(score)
	
	
func on_boost_current_changed(value: String) -> void:
	print("Boost changed to: ", value)
	
	
func set_artist(artist: String, title: String) -> void:
	BKMREngine.Inventory.group_card_equipped(artist)
	%Artist.text = artist
	%SongName.text = title
	
	
func _on_get_group_card_equipped_complete(card_data: Array) -> void:
	if not card_data.is_empty():
		equipped_cards_texture(card_data)
	else:
		for textures: TextureRect in get_tree().get_nodes_in_group("CardTexture"):
			textures.visible = false
	
	
func hit_continued_feedback(note_accuracy: int, line: int ) -> void:
	if note_accuracy == 5:
		combo = 0
	elif note_accuracy != 4:
		set_boost_multiplier()
		var long_note_accuracy: int = 5 - note_accuracy
		combo = combo + 1
		total_combo = total_combo + 1
		score += long_note_accuracy * 5 * boost_multiplier

	hit_display_data.emit(note_accuracy, line, combo)
	
	
func set_boost_multiplier() -> void:
	if current_boost != 1:
		boost_multiplier = current_boost
	else:
		boost_multiplier = 1
	if current_boost == 3 and current_momentum == 50:
		boost_multiplier = 4
	
	
func equipped_cards_texture(card_data: Array) -> void:
	# Extract dictionary from array (assuming only one dictionary exists)
	if not card_data.is_empty():
		var card_dict: Dictionary = card_data[0]

		# Check if all "name" values are empty
		var all_names_empty: bool = true
		for key: String in card_dict.keys():
			var card_info: Dictionary = card_dict[key]
			if "name" in card_info and card_info["name"] != "":
				all_names_empty = false
				break  # Exit early if at least one name exists

		# Toggle CardTexture3 visibility based on names
		%CardTexture3.visible = not all_names_empty

		# If all names are empty, stop execution
		if all_names_empty:
			return

		# Ensure card_textures_array is defined (assuming it's a class variable)
		if not "card_textures_array" in self:
			var _card_textures_array: Array = []

		# Iterate over dictionary keys
		for key: String in card_dict.keys():
			var card_info: Dictionary = card_dict[key]
			
			# Ensure "name" exists and is not empty
			if "name" in card_info and card_info["name"] != "":
				var card_name: String = card_info["name"].replace(" ", "_").to_lower()
				var texture_path: String = "res://UITextures/Cards/" + card_name + ".png"

				# Check if texture exists before loading
				if ResourceLoader.exists(texture_path):
					var card_texture: Texture = load(texture_path)
					card_textures_array.append(card_texture)

		# Call animation function (assuming it exists)
		animate_card()
	
	
func _on_save_classic_highscore_complete(_rewards: Dictionary) -> void:
	%LoadingPanel.tween_kill()
	_on_classic_game_over_completed()
	
	
func hit_feedback(note_accuracy: int, line: int) -> void:
	health = clamp(health, 0, 100)
	match note_accuracy:
		1:
			# perfect
			combo += 1
			hit_display_data.emit(note_accuracy, line, combo)
			score_accuracy = (1200 + score_boost) * boost_multiplier
			total_combo += 1
			perfect += 1
			adjust_health(2)  # Increase health
			boost_feedback(false)
		2:
			# very good
			combo += 1
			hit_display_data.emit(note_accuracy, line, combo)
			score_accuracy = 800 * boost_multiplier
			total_combo += 1
			very_good += 1
			adjust_health(1)  # Increase health
			boost_feedback(false)
		3:
			# good
			combo += 1
			hit_display_data.emit(note_accuracy, line, combo)
			score_accuracy = 400
			total_combo += 1
			good += 1
		4:
			# bad
			hit_display_data.emit(note_accuracy, line, combo)
			score_accuracy = 200
			bad += 1
		5:
			# miss
			combo = 0
			hit_display_data.emit(note_accuracy, line, combo)
			score_accuracy = 0
			miss += 1
			adjust_health(-10)  # Decrease health
			set_boost(true)
	
	
func boost_feedback(is_swipe_note: bool = false) -> void:
	current_momentum = clamp(current_momentum, 0, 50)
	
	# Increase momentum based on whether it's a swipe note
	current_momentum += 15 if is_swipe_note else 20
	
	# Clamp again to keep it within bounds
	current_momentum = clamp(current_momentum, 0, 50)
	# If momentum is maxed out, increase boost level (up to 3)
	if current_momentum == 50:
		if current_boost < 3:
			set_boost()
		else:
			# If already at max boost, reset momentum
			current_momentum = 0
	
	
func adjust_health(amount: int) -> void:
	health += amount
	health = clamp(health, 0, 100)  # Ensure health stays within range
	health_bar.value = health
	if health <= 0:
		game_over(false)  # Call game over when health reaches zero
	
	
func set_boost(is_reset: bool = false) -> void:
	if is_reset:
		current_boost = 1
		current_momentum = 0
	else:
		# Increase boost level if it's not maxed out
		if current_boost < 3:
			current_momentum = 0
			current_boost += 1
	set_boost_multiplier()
	
	
func animate_card() -> void:
	if not card_textures_array.is_empty():
		if card_textures_array.size() == 1:
			%CardTexture1.texture = card_textures_array[0]
		elif card_textures_array.size() > 1:
			%CardTexture1.texture = card_textures_array[0]
			%CardTexture2.texture = card_textures_array[1]
			cycle_card_textures()
	
	
# Function to update textures for CardTexture1 and CardTexture2
func update_textures() -> void:
	# Store the current texture of CardTexture2
	var next_texture: Texture = %CardTexture2.texture
	
	# Set CardTexture1 to show the texture of CardTexture2
	%CardTexture1.texture = next_texture
	
	# Update the index for CardTexture2%LoadingPanel.fake_loader()
	if current_card_texture_index + 1 < card_textures_array.size():
		current_card_texture_index += 1
	else:
		current_card_texture_index = 0
	
	# Set CardTexture2 to the next texture in the array
	%CardTexture2.texture = card_textures_array[current_card_texture_index]
	
	
# Function to start tweening for CardTexture2
func start_tween() -> void:
	card_texture_tween = get_tree().create_tween()
	
	# Tween the transition for CardTexture2
	var _texture2: PropertyTweener = card_texture_tween.tween_property(
		%CardTexture2, 
		"texture", 
		card_textures_array[current_card_texture_index], 
		4
	).set_trans(Tween.TRANS_LINEAR)
	var _tween_callback: CallbackTweener = card_texture_tween.tween_callback(cycle_card_textures)
	
	
# Main function to cycle through textures
func cycle_card_textures() -> void:
	update_textures()  # Update the textures for CardTexture1 and CardTexture2
	start_tween()      # Start the tweening process
	
	
func set_boost_visibility(boost: int) -> void:
	# Show or hide effects based on boost level
	if boost == 0:
		%EffectsOnLeft.visible = false
		%EffectsOnRight.visible = false
	else:
		%EffectsOnLeft.visible = true
		%EffectsOnRight.visible = true
	
	var _new_color: Color = get_boost_color(boost)
	#tween_boost_color(new_color)
	
	
func get_boost_color(boost: int) -> Color:
	match boost:
		1: return Color("#7b950033") # Softened opacity (20%)
		2: return Color("#66E10055") # More transparency (33%)
		3: return Color("#A400A477") # Subtle but noticeable (47%)
	return Color("#00000000") # Default transparent (for safety)
	
	
#func tween_boost_color(new_color: Color) -> void:
	#left_boost_tween = get_tree().create_tween()
#
	## Get the current color of the shader parameter
	##var start_color: Color = %EffectsOnLeft.material.get_shader_parameter("color1")
#
	## Tween the shader parameter correctly
	#var _hey: MethodTweener = left_boost_tween.tween_method(
		#func(value: Color) -> void:
			#%EffectsOnLeft.material.set_shader_parameter("color1", value),
		#start_color, # Start value
		#new_color,   # Target value
		#0.3          # Duration
	#).set_trans(Tween.TRANS_LINEAR)
	
	
func _on_road_song_finished() -> void:
	game_over(true)
	
	
func _on_music_song_finished() -> void:
	game_over(true)
	
	
func _on_classic_game_over_completed(_message: Variant = "") -> void:
	LOADER.next_texture = preload("res://UITextures/BGTextures/game_over_bg.png")
	var _load_scene: bool = await LOADER.load_scene(self, "res://UIScenes/game_over.tscn")
	
	
func game_over(is_finished: bool) -> void:
	if game_over_called:
		return  # Exit if already called

	game_over_called = true  # Mark as called
	%LoadingPanel.fake_loader()
	%PauseButton.visible = false
	var classic_score_stats: Dictionary[String, Variant] = {
		"difficulty": difficulty,
		"score": score,
		"combo": total_combo,
		"maxCombo": max_combo,
		"accuracy": accuracy_rate,
		"finished": is_finished,
		"songName": song_name,
		"artist": %Artist.text,
		"perfect": perfect,
		"veryGood": very_good,
		"good": good,
		"bad": bad,
		"miss": miss,
		"username": PLAYER.username,
		"gameId": BKMREngine.Energy.game_id
	}
	#score_stats_classic = classic_score_stats
	BKMREngine.Score.save_classic_high_score(classic_score_stats)
	
	
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
	
	
func _on_button_pressed() -> void:
	%LoadingPanel.set_message("YOU ARE ON PAUSE")
	%LoadingPanel.fake_loader()
	Engine.time_scale = 0
	pause_button_pressed.emit()
	
	
func _on_loading_panel_on_play_button_pressed() -> void:
	play_button_pressed.emit()
	
	
func _on_music_song_length(time: float) -> void:
	%SongProgressBar.max_value = time
	song_length = time
	
	
func _on_music_song_playback_time(time: float) -> void:
	%SongProgressBar.value = time
	elapsed_time = time
