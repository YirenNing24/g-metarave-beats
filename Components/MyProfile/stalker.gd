extends Control

signal on_stalker_button_pressed(username: String)

var origin: String 
var user_name: String

func set_picture(image_string: String, username: String) -> void:
	user_name = username
	if not image_string.is_empty():
		var image: Image = Image.new()
		var display_image: PackedByteArray = JSON.parse_string(image_string)
		var error: Error = image.load_png_from_buffer(display_image)
		if error != OK:
			print("Error loading image", error)
		else:
			var display_pic: Texture =  ImageTexture.create_from_image(image)
			%ProfilePic.texture = display_pic
			bind_stalker_username_button(username, display_pic)
	else:
		@warning_ignore("unsafe_call_argument")
		bind_stalker_username_button(username, %ProfilePic.texture)
		

func set_origin(origin_modal: String) -> void:
		origin = origin_modal
	
	
func bind_stalker_username_button(username: String, pic: Texture) -> void:
	%Button.pressed.connect(_on_button_pressed.bind(username, pic))
	
	
func _on_button_pressed(stalker_username: String, texture: Texture) -> void:
	on_stalker_button_pressed.emit(stalker_username, texture)
