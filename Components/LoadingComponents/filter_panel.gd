extends Panel


func fake_loader() -> void:
	visible = true
	$AnimatedSprite2D.play("default")
	
func tween_kill() -> void:
	visible = false
	$AnimatedSprite2D.stop()
	
