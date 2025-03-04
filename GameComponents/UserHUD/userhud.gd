extends Control


@onready var health_bar: TextureProgressBar = %HealthBar
@onready var username_label: Label = %UsernameLabel

@export var health: int = 100
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

@export var boost_current: String
@export var current_boost: int = 0
@export var boost_multiplier: int = 1

var map: String
var song_length: float

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
	health = clamp(health, 0, 100) 
	set_multiplayer_authority(1) 
	connect_signals()
	username_label.text = PLAYER.username
	#%EffectsOnLeft.material.set_shader_parameter("color1", "ffffff01")
	 
	
func on_boost_current_changed(value: String) -> void:
	print("Boost changed to: ", value)
	
	
func set_artist(artist: String, title: String) -> void:
	BKMREngine.Inventory.group_card_equipped(artist)
	%Artist.text = artist
	%SongName.text = title
	

func connect_signals() -> void:
	var _1: int = MULTIPLAYER.classic_game_over_completed.connect(_on_classic_game_over_completed)
	BKMREngine.Inventory.group_card_equip_complete.connect(equipped_cards_texture)
	
	
func _on_get_group_card_equipped_complete(card_data: Array) -> void:
	if not card_data.is_empty():
		equipped_cards_texture(card_data)
	else:
		for textures: TextureRect in get_tree().get_nodes_in_group("CardTexture"):
			textures.visible = false
		
	
	
@rpc("authority")
func set_client_score(score: int) -> void:
	%ScoreLabel.text = str(score)
	
	
@rpc('authority')
func show_equipped_cards(_card_data: Array) -> void:
	pass
	
	
@rpc("authority")
func set_client_current_boost(boost: int, _momentum: int) -> void:
	set_boost_visibility(boost)
		
	
@rpc("authority")
func set_client_health(health_value: int) -> void:
	health_bar.value = health_value
	if health_value == 0:
		_on_classic_game_over_completed()
	
	
func equipped_cards_texture(card_data: Array) -> void:
	# Extract dictionary from array (assuming only one dictionary exists)
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
	_on_classic_game_over_completed()
	
	
func _on_music_song_finished() -> void:
	_on_classic_game_over_completed()
	
	
func _on_classic_game_over_completed(_message: Variant = "") -> void:
	LOADER.next_texture = preload("res://UITextures/BGTextures/game_over_bg.png")
	var _load_scene: bool = await LOADER.load_scene(self, "res://UIScenes/game_over.tscn")
	
	
	
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
	
	
