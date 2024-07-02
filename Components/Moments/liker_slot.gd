extends Control


func slot_data(profile_pic_data: Dictionary) -> void:
	var picture: String = profile_pic_data.profilePicture
	%ProfilePic.texture = set_profile_picture(picture)
	%PlayerName.text = profile_pic_data.userName
	
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
