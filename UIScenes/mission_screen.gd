extends Control

const mission_entry_scene: PackedScene = preload("res://Components/Mission/mission_entry.tscn")


func _ready() -> void:
	connect_signals()
	BKMREngine.Reward.get_mission_reward_list()

func connect_signals() -> void:
	BKMREngine.Reward.get_mission_reward_list_completed.connect(_on_get_mission_reward_list_completed)
	BKMREngine.Reward.claim_mission_reward_completed.connect(_on_claim_mission_reward_completed)
	
	
func _on_get_mission_reward_list_completed(mission_data: Variant) -> void:
	if mission_data is Array:
		var data_mission: Array = mission_data
		var mission_entry: Control
		for mission: Dictionary in data_mission:
			mission_entry = mission_entry_scene.instantiate()
			mission_entry.mission_slot_data(mission)
			mission_entry.mission_entry_button_pressed.connect(_on_mission_entry_button_pressed)
			%MissionsContainer.add_child(mission_entry)
			
	
func _on_mission_entry_button_pressed(mission_data: Dictionary) -> void:
	BKMREngine.Reward.claim_mission_reward(mission_data)
	%ClaimValue.text = "+" + mission_data.reward.to_upper() + " " + "GBEATS CLAIMED!"
	%LoadingPanel.fake_loader()
	
	
func _on_claim_mission_reward_completed(_message: Dictionary) -> void:
	%LoadingPanel.tween_kill()
	%AnimationPlayer.play("ClaimModal")
	
	
func _on_close_button_pressed() -> void:
	# Attempt automatic login and wait for the session check to complete.
	BKMREngine.Auth.auto_login_player()

	# Set the previous and next textures for scene transition.
	LOADER.previous_texture = %BackgroundTexture.texture
	LOADER.next_texture = preload("res://UITextures/BGTextures/main_city.png")
	
	# Initiate the scene transition.
	var _change_scene: bool = await LOADER.load_scene(self, "res://UIScenes/main_screen.tscn")
