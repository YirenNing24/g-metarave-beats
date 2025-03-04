extends Panel


func fake_loader() -> void:
	visible = true
	$AnimatedSprite2D.play("default")
	var _timer: int = get_tree().create_timer(30).timeout.connect(tween_kill)
	
	
func tween_kill() -> void:
	visible = false
	$AnimatedSprite2D.stop()
	
