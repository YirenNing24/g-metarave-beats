extends Control

signal loading_finished



var tween: Tween

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	
	
func _on_visibility_changed() -> void:
	if visible:
		fake_loader()
	else:
		pass
	
	
func fake_loader() -> void:
	%LoadingWheel.value = 0
	tween = get_tree().create_tween()
	
	# Animate the loading wheel value property.
	var _wheel_loader: PropertyTweener = tween.tween_property(%LoadingWheel, "value", 100, 5.0).set_trans(Tween.TRANS_LINEAR)
	var _1: int = tween.finished.connect(_on_loading_finished) 


func _on_loading_finished() -> void:
	loading_finished.emit()
