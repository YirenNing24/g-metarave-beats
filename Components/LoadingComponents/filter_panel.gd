extends Panel

signal on_play_button_pressed

var active_timer: SceneTreeTimer = null  # Store the active timer reference

func fake_loader(transaction_name: String = "") -> void:
	var loading_time: float
	match transaction_name:
		"":
			loading_time = 30.0
		"buyCard":
			loading_time = 90.0
		
	visible = true
	$AnimatedSprite2D.play("default")

	# Ensure any existing timer is disconnected before creating a new one
	if active_timer:
		active_timer.timeout.disconnect(tween_kill)
	
	active_timer = get_tree().create_timer(loading_time)
	var  _yes: int = active_timer.timeout.connect(tween_kill)
	
	
func tween_kill() -> void:
	# Prevent multiple calls by checking if there's an active timer
	if active_timer:
		visible = false
		$AnimatedSprite2D.stop()

		# Disconnect and nullify the timer to avoid redundant calls
		active_timer.timeout.disconnect(tween_kill)
		active_timer = null
	
	
func set_message(message: String) -> void:
	%Message.text = message
	if message == "YOU ARE ON PAUSE":
		%PlayButton.visible = true
		$RetryContainer.visible = true
	
	
func _on_play_button_pressed() -> void:
	Engine.time_scale = 1
	on_play_button_pressed.emit()
	
	visible = false
	%PlayButton.visible = false
	%Message.text = "Please wait..."
	
	
func _on_retry_button_pressed() -> void:
	if PLAYER.current_energy > 0:
		Engine.time_scale = 1
		BKMREngine.Energy.game_id = ""
		BKMREngine.Energy.use_player_energy()
		# Allow retry logic here
		var _game_scene: int = await LOADER.load_scene(self, "res://UIScenes/game_scene.tscn")
	else:
		%RetryButton.modulate = "ffffff4b"
		%RetryButton.disabled = true
		print("Not enough energy to retry!")
	
	
func _on_retry_button_2_pressed() -> void:
	Engine.time_scale = 1
	var _game_scene: int = await LOADER.load_scene(self, "res://UIScenes/song_menu.tscn")
