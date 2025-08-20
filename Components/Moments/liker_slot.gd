extends Control

signal on_liker_button_pressed(username: String)

func slot_data(profile_pic_data: Dictionary, origin: String = "") -> void:
	if profile_pic_data.username == null:
		return

	if profile_pic_data.has("profilePicture") and typeof(profile_pic_data.profilePicture) == TYPE_STRING and profile_pic_data.profilePicture != "":
		var pic: String = profile_pic_data.profilePicture
		%ProfilePic.texture = set_profile_picture(pic)
	
	
	match origin:
		"Profile":
			%FollowUnfollowButton.visible = false
			%PlayerName.text = str(profile_pic_data.username)
			@warning_ignore("unsafe_call_argument")
			%Level.text = str(int(profile_pic_data.playerStats.level))
			%PlayerRank.text = str(profile_pic_data.playerStats.rank)
			@warning_ignore("unsafe_call_argument")
			liker_username_button(profile_pic_data.username)
		"FanMoments":
			%PlayerName.text = str(profile_pic_data.get("userName", profile_pic_data.username))
			# Uncomment if you want to show level/rank here
			# %Level.text = str(profile_pic_data.playerStats.level)
			# %PlayerRank.text = str(profile_pic_data.playerStats.rank)


func liker_username_button(username: String) -> void:
	if PLAYER.username == username:
		return
	%TextureButton.pressed.connect(_on_button_pressed.bind(username))

func _on_button_pressed(liker_username: String) -> void:
	on_liker_button_pressed.emit(liker_username)

	
func set_profile_picture(image_buffer_string: String) -> Texture:
	if image_buffer_string == "":
		return
	var image: Image = Image.new()
	var display_image: Array = JSON.parse_string(image_buffer_string)
	if display_image.is_empty():
		return
	else:
		var error: Error = image.load_png_from_buffer(display_image)
		if error != OK:
			print("Error loading image", error)
		else:
			var display_pic: Texture = ImageTexture.create_from_image(image)
			return display_pic
			
	return null
