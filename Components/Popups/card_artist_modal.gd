extends Control


var trivia_label_scene: PackedScene = preload("res://Components/MyProfile/trivia_label.tscn")

@onready var trivia_container: VBoxContainer = %TriviaContainer
@onready var card_name: Label = %CardName
@onready var birth_name: Label = %BirthName
@onready var member_position: Label = %Position
@onready var birthday: Label = %Birthday
@onready var height: Label = %Height
@onready var zodiac: Label = %Zodiac
@onready var blood_type: Label = %BloodType
@onready var nationality: Label = %Nationality

@onready var rewards_panel: Panel = %RewardsPanel
@onready var rewards_container: GridContainer = %RewardsContainer

@onready var idol_hero_image: TextureRect = %IdolHeroImage

var original_card_name: String
var zodiac_card: String

func _ready() -> void:
	connect_signal()
	
func card_data(data: Dictionary) -> void:
	display_artist_data(data)
	set_claimable_rewards()
	set_horoscope_reward() 
	set_animal_reward()
	
func connect_signal() -> void:
	BKMREngine.Reward.claim_card_ownership_reward_completed.connect(_on_claim_card_ownership_reward_completed)
	BKMREngine.Reward.claim_horoscope_match_reward_completed.connect(_on_claim_horoscope_match_reward_completed)
	BKMREngine.Reward.claim_animal_match_reward_completed.connect(_claim_animal_match_reward_completed)
	
func _on_close_button_pressed() -> void:
	visible = false
	for trivia: Label in trivia_container.get_children():
		trivia.queue_free()

func display_artist_data(data: Dictionary) -> void:
	visible = true
	var card_artist_data: Dictionary = data.card
	var card_artist_trivia: Dictionary = data.card.trivia
	display_artist_trivia(card_artist_trivia)
	
	original_card_name = data.name
	
	card_name.text =  card_artist_data.artist + " - " +  card_artist_data.group
	birth_name.text = card_artist_data.birthName
	birthday.text = card_artist_data.birthday
	height.text = card_artist_data.height
	zodiac.text = card_artist_data.zodiac
	blood_type.text = card_artist_data.bloodType
	nationality.text = card_artist_data.nationality
	
	var artist_texture_name: String = card_artist_data.artist.to_lower() + "_card_artist_hero.png"
	var artist_texture: Texture = load("res://UITextures/CardArtistTextures/" + artist_texture_name)
	idol_hero_image.texture = artist_texture
	
	for icons: TextureRect in get_tree().get_nodes_in_group("RewardIcon"):
		var icon_texture_name: String = card_artist_data.artist.to_lower() +"_ownership.png"
		var icon_texture: Texture = load("res://UITextures/RewardTextures/" + icon_texture_name)
		icons.texture = icon_texture
		
	%RewardDescription.text = original_card_name
	%RewardDescription2.text = "Born under " + card_artist_data.zodiac.capitalize()
	%RewardDescription3.text = card_artist_data.animal.capitalize() + " lover"
	
func display_artist_trivia(trivias: Dictionary) -> void:
	var trivia_label: Label 
	for trivia: String in trivias.keys():
		trivia_label = trivia_label_scene.instantiate()
		trivia_label.text = "- " + trivias[trivia]
		trivia_container.add_child(trivia_label)

func _on_close_rewards_panel_button_pressed() -> void:
	if rewards_panel.visible:
		rewards_panel.visible = false

func _on_claim_rewards_button_pressed() -> void:
	if !rewards_panel.visible:
		rewards_panel.visible = true

func set_claimable_rewards() -> void:
	var ownership_card_reward_list: Array = PLAYER.card_reward.cards
	var claimed_ownership: Array = PLAYER.card_reward.soul.ownership
	var is_claimable: bool = false
	
	# Check if the card is in the ownership reward list
	for card_names: Dictionary in ownership_card_reward_list:
		if card_names.name == original_card_name:
			is_claimable = true
			%OwnershipReward.modulate = "ffffff"
			break
	
	# Check if the card is already claimed
	if is_claimable:
		for names: String in claimed_ownership:
			if names == original_card_name:
				is_claimable = false
				%OwnershipReward.modulate = "ffffff42"
				break
	else:
		%OwnershipReward.modulate = "ffffff42"
		
	# Set the button state based on the checks
	%OwnershipButton.disabled = not is_claimable

	# Connect the button press signal if it's enabled
	if is_claimable:
		if !%OwnershipButton.pressed.is_connected(_on_ownership_button_pressed):
			%OwnershipButton.pressed.connect(_on_ownership_button_pressed)
	else:
		%OwnershipButton.disabled = true

func set_horoscope_reward() -> void:
	var card_artist_zodiac: String = zodiac.text
	var player_zodiac: String = PLAYER.card_reward.soul.horoscope
	var claimed_horoscope_matches: Array = PLAYER.card_reward.soul.horoscopeMatch
	
	if card_artist_zodiac == player_zodiac:
		%ZodiacButton.disabled = false
		%ZodiacReward.modulate = "ffffff"
	else: 
		%ZodiacButton.disabled = true
		%ZodiacReward.modulate = "ffffff42"
		
	for names: String in claimed_horoscope_matches:
		if names == original_card_name:
			%ZodiacButton.disabled = true
			%ZodiacReward.modulate = "ffffff42"
			
	if %ZodiacButton.disabled == false:
		%ZodiacButton.pressed.connect(_on_zodiac_button_pressed)

func set_animal_reward() -> void:
	var is_claimable: bool = false
	var player_animals: Array = []
	
	var claimed_animal_reward_list: Array = PLAYER.card_reward.soul.animalMatch
	# Collect the player's animals from the card reward
	for key: String in ["animal1", "animal2", "animal3"]:
		if key in PLAYER.card_reward.soul:
			player_animals.append(PLAYER.card_reward.soul[key].to_lower().replace(" ", ""))
			
	var card_animal: String = %RewardDescription3.text.replace("lover", "").to_lower().replace(" ", "")
	# Check if any of the player's animals match the card animal
	for animal: String in player_animals:
		if animal == card_animal:
			is_claimable = true
			break

	# Check if the card is in the claimed animal reward list
	for card_names: String in claimed_animal_reward_list:
		if card_names == original_card_name:
			is_claimable = false
			%AnimalButton.modulate = "ffffff42"
			break
			
	# Set the reward button and modulate the common animal reward
	if is_claimable:
		%AnimalButton.disabled = false
		%CommonAnimalReward.modulate = Color(1, 1, 1, 1)  # Fully opaque white
		
		if !%AnimalButton.pressed.is_connected(_on_animal_button_pressed):
			%AnimalButton.pressed.connect(_on_animal_button_pressed)
	else:
		%CommonAnimalReward.modulate = Color(1, 1, 1, 0.26)  # Semi-transparent white
	
	# Set the ownership button state based on the claimable status
	%AnimalButton.disabled = not is_claimable
	set_reward_notification_active()

func set_reward_notification_active() -> void:
	for button: TextureButton in get_tree().get_nodes_in_group("ClaimRewardButton"):
		if button.disabled == false:
			%ActiveRewards.visible  = true
			break
		else:
			%ActiveRewards.visible = false

func _on_ownership_button_pressed() -> void:
	BKMREngine.Reward.claim_card_ownership_reward(original_card_name)
	$FilterPanel.fake_loader()
	
func _on_zodiac_button_pressed() -> void:
	BKMREngine.Reward.claim_horoscope_match_reward(original_card_name)
	$FilterPanel.fake_loader()
	
func _on_animal_button_pressed() -> void:
	BKMREngine.Reward.claim_animal_match_reward(original_card_name)
	$FilterPanel.fake_loader()
	
func _on_claim_card_ownership_reward_completed(message: Dictionary) -> void:
	if message.success:
		%OwnershipReward.modulate = "ffffff42"
		%OwnershipButton.disabled = true
	$FilterPanel.tween_kill()
	set_reward_notification_active()
	%AnimationPlayer.play("RewardClaimed")
	
func _on_claim_horoscope_match_reward_completed(message: Dictionary) -> void:
	if message.success:
		%ZodiacReward.modulate = "ffffff42"
		%ZodiacButton.disabled = true
	$FilterPanel.tween_kill()
	set_reward_notification_active()
	%AnimationPlayer.play("RewardClaimed")
	
func _claim_animal_match_reward_completed(message: Dictionary) -> void:
	if message.success:
		%CommonAnimalReward.modulate = "ffffff42"
		%AnimalButton.disabled = true
	$FilterPanel.tween_kill()
	set_reward_notification_active()
	%AnimationPlayer.play("RewardClaimed")
