extends Node3D

@onready var combo_label: Label3D = %ComboLabel
@onready var combo_value_label: Label3D = %ComboValueLabel

var old_combo_value: String = "0"
var tween: Tween

func _ready() -> void:
	randomize()

func _on_user_hud_hit_display_data(note_accuracy: int, line: int, _combo_value: int) -> void:
	# Update combo value label
	combo_value_label.text = str(_combo_value)

	# Animate hit effect
	animate_client_hit(note_accuracy, line)

func _process(_delta: float) -> void:
	if old_combo_value != combo_value_label.text:
		old_combo_value = combo_value_label.text
		combo_value(combo_value_label.text)


func animate_client_hit(accuracy: int, line: int) -> void:
	var y_transform: float = randf_range(0.4, 0.6)
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
	if accuracy == 4 or 5:
		pass
		#feedback_haptic(accuracy)


func feedback_haptic(accuracy: int) -> void:
	if accuracy == 4:
		Input.vibrate_handheld(150)
	elif accuracy == 5:
		Input.vibrate_handheld(350)

func combo_value(value: String) -> void:
	for picker: Node3D in get_tree().get_nodes_in_group("Picker"):
		picker.combo_value(value.to_int())
