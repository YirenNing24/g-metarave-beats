extends Control

signal chat_button_pressed(username: String)


func signal_connect() -> void:
	BKMREngine.Profile.get_player_profile_pic_complete.connect(_on_get_player_profile_pic_complete)


func _on_chat_button_pressed() -> void:
	chat_button_pressed.emit(%UsernameLabel.text)


func mutual_slot_data(mutual_data: Dictionary) -> void:
	signal_connect()
	%UsernameLabel.text = mutual_data.username
	%LevelLabel.text = "Level: " + str(mutual_data.playerStats.level)
	%RankLabel.text = mutual_data.playerStats.rank
	BKMREngine.Profile.get_player_profile_pic(mutual_data.username)


func _on_get_player_profile_pic_complete(profile_pics: Variant) -> void:
		if typeof(profile_pics) != TYPE_ARRAY:
			return
		for pic: Dictionary in profile_pics:
				var image: Image = Image.new()
				var first_image: String = profile_pics[0].profilePicture
				var display_image: PackedByteArray = JSON.parse_string(first_image)
				var error: Error = image.load_png_from_buffer(display_image)
				if error != OK:
					print("Error loading image", error)
				else:
					var display_pic: Texture =  ImageTexture.create_from_image(image)
					%DPIcon.texture = display_pic
