extends Panel




@onready var loading_wheel: TextureProgressBar = %LoadingWheel

var tween: Tween


func fake_loader() -> void:
	visible = true
	loading_wheel.value = 0
	tween = get_tree().create_tween()
	
	var _wheel_loader: PropertyTweener = tween.tween_property(loading_wheel, "value", 100, 3.0).set_trans(Tween.TRANS_LINEAR)
	var _loader_fake: CallbackTweener = tween.tween_callback(fake_loader)
	
func tween_kill() -> void:
	tween.kill()
