extends Control

signal player_profile_button_pressed(username: String)

# Called when the node enters the scene tree for the first time.
func set_picture(profile_picture: String) -> void:
	var image: Image = Image.new()
	var display_image: PackedByteArray = JSON.parse_string(profile_picture)
	var error: Error = image.load_png_from_buffer(display_image)
	if error != OK:
		print("Error loading image", error)
		return
	else:
		%ProfilePic.texture = ImageTexture.create_from_image(image)


func _on_player_profile_button_pressed() -> void:
	player_profile_button_pressed.emit(%PlayerName.text, %ProfilePic.texture)
