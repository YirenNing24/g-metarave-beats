extends Control

var mission_slot: PackedScene = preload('res://Components/Mission/mission_slot.tscn')

@onready var beats_balance: Label = %BeatsBalance
@onready var gmr_balance: Label = %GMR

var recharge_progress: float = 0.0
var time_until_next_recharge : int
var recharge_interval : int = 60 * 60 * 1000 # 1 hour in milliseconds


func _ready() -> void:
	%LoadingPanel.fake_loader()
	hud_data() 
	connect_signals()
	BKMREngine.Reward.get_personal_mission_list()
	
	
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
	
	
func hud_data() -> void:
	display_hud()
	
	
func display_hud() -> void:
	BKMREngine.Energy.get_energy_drink()
	energy_hud()
	beats_balance.text = PLAYER.beats_balance
	gmr_balance.text = PLAYER.gmr_balance

	
func energy_hud() -> void:
	%Energy.text = str(PLAYER.current_energy) + " " + "/" + " " + str(PLAYER.max_energy)
	if PLAYER.time_until_next_recharge != 0:
		start_recharge_countdown(PLAYER.time_until_next_recharge)
	

func start_recharge_countdown(time_until_next: int) -> void:
	time_until_next_recharge = time_until_next
	recharge_progress = 0.0
	
	
func connect_signals() -> void:
	BKMREngine.Reward.get_personal_mission_list_completed.connect(_get_personal_mission_list_completed)
	
	
func _get_personal_mission_list_completed(personal_missions: Array) -> void:
	for mission: Dictionary in personal_missions:
		var mission_personal: Control = mission_slot.instantiate()
		mission_personal.mission_slot_data(mission)
		%PersonalMissionVBox.add_child(mission_personal)
		
		mission_personal.claim_personal_mission_started.connect(_on_claim_personal_mission_reward_started)
		mission_personal.claim_personal_mission_reward_complete.connect(_on_claim_personal_mission_reward_completed)
		
	%LoadingPanel.tween_kill()
		
		
func _on_claim_personal_mission_reward_started() -> void:
	%LoadingPanel.fake_loader()
		
		
func _on_claim_mission_reward_completed(_message: Dictionary) -> void:
	%LoadingPanel.tween_kill()
	%AnimationPlayer.play("ClaimModal")
	
	
func _on_claim_personal_rewards_button_pressed() -> void:
	%LoadingPanel.fake_loader()
	
	
func _on_claim_personal_mission_reward_completed(reward_name: String, reward_amount: int) -> void:
	if reward_amount != 0:
		if reward_name == "BEATS":
			%Message.text = "BEATS reward succesfully claimed"
			%AnimationPlayer.play("Message")
			
		var current_beats_balance: int = beats_balance.text.to_int()
		if current_beats_balance != 0:
			beats_balance.text = format_balance(str(current_beats_balance + reward_amount))
			
	%LoadingPanel.tween_kill()
	
	
func _on_close_button_pressed() -> void:
	# Attempt automatic login and wait for the session check to complete.
	BKMREngine.Auth.auto_login_player()

	# Set the previous and next textures for scene transition.
	LOADER.previous_texture = %BackgroundTexture.texture
	LOADER.next_texture = preload("res://UITextures/BGTextures/main_city.png")
	
	# Initiate the scene transition.
	var _change_scene: bool = await LOADER.load_scene(self, "res://UIScenes/main_screen.tscn")
	
	
func format_balance(value: String) -> String:
	var parts: Array = value.split(".")
	var whole_part: String = parts[0]
	
	# Add commas for every three digits in the whole part.
	var formatted_whole_part: String = ""
	var digit_count: int = 0
	for i: int in range(whole_part.length() - 1, -1, -1):
		formatted_whole_part = whole_part[i] + formatted_whole_part
		digit_count += 1
		if digit_count == 3 and i != 0:
			formatted_whole_part = "," + formatted_whole_part
			digit_count = 0
	return formatted_whole_part
	
	
func _on_tab_container_tab_changed(tab: int) -> void:
	match tab:
		0:
			if %PersonalMissionVBox.get_children().is_empty():
				BKMREngine.Reward.get_personal_mission_list()
		1:
			pass
		2:
			pass
		3:
			if %DailyMissionVBox.get_children().is_empty():
				BKMREngine.Reward.get_daily_mission_list()
