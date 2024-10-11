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


@export var final_stats: Dictionary
@export var note_stats: Dictionary

var tween: Tween
var boost_tween: Tween

var card_texture_tween: Tween
var card_textures_array: Array[Texture] = []
var current_card_texture_index: int = 0
@onready var card_texture2_original_position: Vector2 = %CardTexture2.position


@export var momentum_to_string: String = ""


func _ready() -> void:
	health = clamp(health, 0, 100) 
	set_multiplayer_authority(1) 
	%MultiplayerSynchronizer.set_multiplayer_authority(1)
	connect_signals()
	
	
func connect_signals() -> void:
	var _1: int = MULTIPLAYER.classic_game_over_completed.connect(_on_classic_game_over_completed)
		
	
func _on_get_group_card_equipped_complete(card_data: Array) -> void:
	if not card_data.is_empty():
		equipped_cards_texture(card_data)
		
		
@rpc
func show_equipped_cards(card_data: Array) -> void:
	equipped_cards_texture(card_data)
		
		
func equipped_cards_texture(card_data: Array) -> void:
	for card: Dictionary in card_data:
		var card_name: String = card["name"].replace(" ", "_").to_lower()
		var card_texture: Texture = load("res://UITextures/Cards/" + card_name + ".png")
			
		if card_texture:
			card_textures_array.append(card_texture)
	animate_card()
	
	
func animate_card() -> void:
	if not card_textures_array.is_empty():
		if card_textures_array.size() == 1:
			%CardTexture1.texture = card_textures_array[0]
		elif card_textures_array.size() > 1:
			%CardTexture1.texture = card_textures_array[0]
			%CardTexture2.texture = card_textures_array[1]
			cycle_card_textures()
	
	
# Define the cycle_textures function outside
# Function to update textures for CardTexture1 and CardTexture2
func update_textures() -> void:
	# Store the current texture of CardTexture2
	var next_texture: Texture = %CardTexture2.texture
	
	# Set CardTexture1 to show the texture of CardTexture2
	%CardTexture1.texture = next_texture
	
	# Update the index for CardTexture2
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

	# Callback to cycle textures again after the tween completes
	var _tween_callback: CallbackTweener = card_texture_tween.tween_callback(cycle_card_textures)

# Main function to cycle through textures
func cycle_card_textures() -> void:
	update_textures()  # Update the textures for CardTexture1 and CardTexture2
	start_tween()      # Start the tweening process
	
	
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
	const texture_path: String = "res://UITextures/Progress/momentum"
	boost_progress_bar.texture_progress = load(texture_path + momentum_to_string + ".png")
	
	
func animate_momentum() -> void:
	boost_tween = get_tree().create_tween()
	var _momentum_tween: PropertyTweener = boost_tween.tween_property(
		boost_progress_bar, 
		"value", 
		current_momentum, 0.1).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR )
	
	
func _on_road_song_finished() -> void:
	_on_classic_game_over_completed()
	
	
func _on_music_song_finished() -> void:
	_on_classic_game_over_completed()
	
	
func _on_classic_game_over_completed() -> void:
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
	
	
func _on_boost_progress_bar_value_changed(_value: float) -> void:
	if momentum_to_string != "":
		boost_progress_texture_change()
	else:
		momentum_to_string = "0"
		boost_progress_texture_change()
