extends Control

@onready var display_picture_texture: TextureRect = %DisplayPictureTexture
@onready var left_button: TextureButton = %LeftButton
@onready var right_button: TextureButton = %RightButton

signal view_picture_close

var profile_pictures: Array = []
var current_picture_index: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	
	
# Get pictures from the stored Array in Profile BKMREngine Script
func get_pictures() -> void:
	for pictures: Dictionary in BKMREngine.Profile.profile_pics:
		var image: Image = Image.new()
		var pictures_profile: String = pictures.profilePicture
		var display_image: PackedByteArray = JSON.parse_string(pictures_profile)
		var error: Error = image.load_png_from_buffer(display_image)
		if error != OK:
			print("Error loading image", error)
			return
		else:
			var pics: Texture = ImageTexture.create_from_image(image)
			profile_pictures.append(pics)
	display_picture()

# Display the first picture and handles the switching to other pictures available 
func display_picture() -> void:
	print(profile_pictures.size())
	if profile_pictures != []:
		display_picture_texture.texture = profile_pictures[current_picture_index]
		
func _on_left_button_pressed() -> void:
	if current_picture_index != 0:
		current_picture_index -= 1
		display_picture_texture.texture = profile_pictures[current_picture_index]

func _on_right_button_pressed() -> void:
	if current_picture_index <= 4:
		current_picture_index += 1
		display_picture_texture.texture = profile_pictures[current_picture_index]

func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		visible = false
		current_picture_index = 0
		profile_pictures.clear()
		view_picture_close.emit()

func _on_display_picture_texture_visibility_changed() -> void:
	if visible:
		get_pictures()
		
