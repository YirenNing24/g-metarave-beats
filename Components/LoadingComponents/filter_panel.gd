extends Panel

signal on_play_button_pressed


func fake_loader() -> void:
	visible = true
	$AnimatedSprite2D.play("default")
	var _timer: int = get_tree().create_timer(30).timeout.connect(tween_kill)
	
	
func tween_kill() -> void:
	visible = false
	$AnimatedSprite2D.stop()
	

func set_message(message: String) -> void:
	%Message.text = message
	if message == "YOU ARE ON PAUSE":
		%PlayButton.visible = true


func _on_play_button_pressed() -> void:
	on_play_button_pressed.emit()
	Engine.time_scale = 1
	visible = false
	%PlayButton.visible = false
	%Message.text = "Please wait..."
	
