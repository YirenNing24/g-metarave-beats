extends Control

signal claim_personal_mission_started
signal claim_personal_mission_reward_complete(reward_name: String, reward_amount: int)


var reward_name: String
var reward_amount: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connect_signal()
	
	
func connect_signal() -> void:
	BKMREngine.Reward.claim_personal_mission_reward_completed.connect(claim_personal_mission_reward_completed)
	
func mission_slot_data(mission_data: Dictionary) -> void:
	reward_name = mission_data.requirement.criteria.reward.name
	reward_amount = mission_data.requirement.criteria.reward.amount
	var elligble: bool = mission_data.elligible
	
	%MissionName.text = mission_data.name
	%RewardLabel.text = str(reward_amount) + " " + reward_name.to_upper()
	
	%ClaimButton.pressed.connect(_on_claim_button_pressed.bind(mission_data.name))
	%DescriptionLabel.text = mission_data.requirement.criteria.description
	
	modulate_button_color(elligble)
	
func modulate_button_color(elligible: bool) -> void:
	if elligible:
		%ClaimButton.modulate = "ffffff00"
		%ClaimButton.disabled = false
	else:
		%ClaimButton.disabled = true
		
func _on_claim_button_pressed(mission_name: String) -> void:
	BKMREngine.Reward.claim_personal_mission_reward(mission_name)
	claim_personal_mission_started.emit()
	
	
func claim_personal_mission_reward_completed(message: Dictionary) -> void:
	
	if message.has("error"):
		claim_personal_mission_reward_complete.emit(reward_name, 0)
	elif message.has("success"):
		modulate_button_color(true)
		%ClaimButton.modulate = "ffffffff"
		%ClaimButton.disabled = true
		claim_personal_mission_reward_complete.emit(reward_name, reward_amount)
