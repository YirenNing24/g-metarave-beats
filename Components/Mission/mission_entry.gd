extends Control

signal mission_entry_button_pressed(mission_data: Dictionary)

var pressed: bool = false


func _ready() -> void:
	connect_signals()


func connect_signals() -> void:
	BKMREngine.Reward.claim_mission_reward_completed.connect(_on_claim_mission_reward_completed)


func _on_claim_mission_reward_completed(_message: Dictionary) -> void:
	if pressed:
		modulate = 'ffffff6d'
		%Button.disabled = true


func mission_slot_data(mission_data: Dictionary) -> void:
	if mission_data.type == "song":
		song_mission(mission_data)
	%Button.pressed.connect(_on_button_pressed.bind(mission_data))


func song_mission(mission_data: Dictionary) -> void:
	if mission_data.songName == "":
		visible = false
		
	%MissionName.text = mission_data.rewardName
	%RewardAmount.text = mission_data.reward + " " + "GBEATS"
	if mission_data.claimed:
		modulate = 'ffffff6d'
		%Button.disabled = true
		
		
func _on_button_pressed(mission_data: Dictionary) -> void:
	pressed = true
	mission_entry_button_pressed.emit(mission_data)
	
