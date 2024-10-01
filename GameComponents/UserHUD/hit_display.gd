extends Node3D

@onready var combo_label: Label3D = %ComboLabel
@onready var combo_value_label: Label3D = %ComboValueLabel

@onready var combo_label_value: String = combo_label.text:
	set(value):
		combo_label_value = value
		combo_value(value)  # Call your combo_value function if needed
		combo_label.text = value  # Update the label's text

var tween: Tween

func _ready() -> void:
	randomize()
	$MultiplayerSynchronizer.set_multiplayer_authority(1)
	
	
func _on_user_hud_hit_display_data(note_accuracy: int, line: int, combo_values: int) -> void:
	if combo_values >= 1 and combo_label.visible == false:
		combo_label.visible = true
		combo_value_label.visible = true
	elif combo_values < 1:
		combo_label.visible = false
		combo_value_label.visible = false
		
	combo_value_label.text = str(combo_value)
	animate_hit(note_accuracy, line)
#
#
func animate_hit(accuracy: int, line: int) -> void:
	var y_transform: float = randf_range(0.2, 0.5)
	var hit_node: AnimatedSprite3D = get_node("Hit" + str(line))
	hit_node.frame = accuracy
	
	tween = get_tree().create_tween().set_parallel()
	var _tween_property: PropertyTweener = tween.tween_property(
		hit_node, 
		"position:y", 
		y_transform, 
		0.2).set_trans(Tween.TRANS_LINEAR)
	await tween.finished
	
	hit_node.frame = 0


func combo_value(new_value: String) -> void:
	for picker: Node3D in get_tree().get_nodes_in_group("Picker"):
		picker.combo_value(new_value)
