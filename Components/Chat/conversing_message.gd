extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	signal_connect()
	BKMREngine.Profile.get_player_profile_pic(%UsernameLabel.text)


func signal_connect() -> void:
	BKMREngine.Profile.get_player_profile_pic_complete.connect(_on_get_player_profile_pic_complete)


#func _on_chat_button_pressed() -> void:
	#chat_button_pressed.emit(%UsernameLabel.text)


func _on_get_player_profile_pic_complete(profile_pics: Variant) -> void:
		if typeof(profile_pics) != TYPE_ARRAY:
			return
		for pic: Dictionary in profile_pics:
			if %UsernameLabel.text == pic.userName:
				var image: Image = Image.new()
				var first_image: String = profile_pics[0].profilePicture
				var display_image: PackedByteArray = JSON.parse_string(first_image)
				var error: Error = image.load_png_from_buffer(display_image)
				if error != OK:
					print("Error loading image", error)
				else:
					var display_pic: Texture =  ImageTexture.create_from_image(image)
					%DPIcon.texture = display_pic
