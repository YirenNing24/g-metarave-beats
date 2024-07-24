extends Node3D

@onready var combo_label: Label3D = %ComboLabel
@onready var combo_value_label: Label3D = %ComboValueLabel

var tween: Tween

func _ready() -> void:
	randomize()


func _on_user_hud_hit_display_data(note_accuracy: int, line: int, combo_value: int) -> void:
	if combo_value >= 1 and combo_label.visible == false:
		combo_label.visible = true
		combo_value_label.visible = true
	elif combo_value < 1:
		combo_label.visible = false
		combo_value_label.visible = false
		
	combo_value_label.text = str(combo_value)
	animate_hit(note_accuracy, line)


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
