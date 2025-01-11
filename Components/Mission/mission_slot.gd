extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	
	
func mission_slot_data(mission_data: Dictionary) -> void:
	var reward_name: String = mission_data.requirement.criteria.reward.name
	var reward_amount: int = mission_data.requirement.criteria.reward.amount
	var elligble: bool = mission_data.elligible
	
	%MissionName.text = mission_data.name
	%RewardLabel.text = str(reward_amount) + " " + reward_name.to_upper()
	
	%ClaimButton.pressed.connect(_on_claim_button_pressed.bind(mission_data.name))
	modulate_button_color(elligble)
	
func modulate_button_color(elligible: bool) -> void:
	if elligible:
		%ClaimButton.modulate = "ffffff00"
		
		
func _on_claim_button_pressed(mission_name: String) -> void:
	BKMREngine.Reward.claim_personal_mission_reward(mission_name)
