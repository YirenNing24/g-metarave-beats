extends Control

var mission_slot: PackedScene = preload('res://Components/Mission/mission_slot.tscn')


func _ready() -> void:
	connect_signals()
	BKMREngine.Reward.get_personal_mission_list()

func connect_signals() -> void:
	BKMREngine.Reward.get_personal_mission_list_completed.connect(_get_personal_mission_lost_completed)
	
	
func _get_personal_mission_lost_completed(personal_missions: Array) -> void:
	for mission: Dictionary in personal_missions:
		var mission_personal: Control = mission_slot.instantiate()
		mission_personal.mission_slot_data(mission)
		%PersonalMissionVBox.add_child(mission_personal)
		
		mission_personal.get_node("ClaimButton").pressed(_on_claim_personal_rewards_button_pressed)
		mission_personal.claim_personal_mission_reward_completed.connect(_on_claim_personal_mission_reward_completed)
		
		
#func _on_claim_mission_reward_completed(_message: Dictionary) -> void:
	#%LoadingPanel.tween_kill()
	#%AnimationPlayer.play("ClaimModal")


	#clear_grid()
	#for upgrade_item: Dictionary in upgrades:
		#var template_card_upgrade_slot: Control = template_card_upgrade_slot_scene.instantiate()
		#if upgrade_item.tier == "tier1":
			#var item_texture: Texture = load("res://UITextures/CardUpgrades/general_tier1.png")
			#template_card_upgrade_slot.get_node("Panel/CardupgradeIcon").texture = item_texture
		#
		#var price_per_token: int = upgrade_item.pricePerToken 
		#var quantity: int = upgrade_item.quantity
		#var price: int = int(price_per_token * quantity)
		#template_card_upgrade_slot.get_node("BuyButton/HBoxContainer/Price").text = format_balance(str(price))
		#template_card_upgrade_slot.get_node("Panel/Quantity").text = format_balance(str(quantity))
		#template_card_upgrade_slot.card_upgrade_data(upgrade_item)
		#
		#template_card_upgrade_slot.buy_button_pressed.connect(_on_get_valid_cards_buy_button_pressed)
		#item_grid.add_child(template_card_upgrade_slot)
	
	
	
func _on_claim_personal_rewards_button_pressed() -> void:
	%LoadingPanel.fake_loader()
	

func _on_claim_personal_mission_reward_completed(_reward_name: int, _reward_amount: String) -> void:
	%LoadingPanel.tween_kill()
	
	
func _on_close_button_pressed() -> void:
	# Attempt automatic login and wait for the session check to complete.
	BKMREngine.Auth.auto_login_player()

	# Set the previous and next textures for scene transition.
	LOADER.previous_texture = %BackgroundTexture.texture
	LOADER.next_texture = preload("res://UITextures/BGTextures/main_city.png")
	
	# Initiate the scene transition.
	var _change_scene: bool = await LOADER.load_scene(self, "res://UIScenes/main_screen.tscn")
