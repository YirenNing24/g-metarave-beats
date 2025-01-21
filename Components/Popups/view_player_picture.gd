extends Control

@onready var display_picture_texture: TextureRect = %DisplayPictureTexture
@onready var left_button: TextureButton = %LeftButton
@onready var right_button: TextureButton = %RightButton
@onready var like_button: TextureButton = %LikeButton

signal view_picture_close

var profile_pics_data: Array = []
var profile_pictures: Array = []
var current_picture_index: int = 0

var player_username: String = ""
var current_picture_id: String

func _ready() -> void:
	connect_signal()

func connect_signal() -> void:
	pass
	#BKMREngine.Profile.like_profile_pic_complete.connect(_on_like_profile_pic_complete)
	#BKMREngine.Profile.unlike_profile_pic_complete.connect(_on_unlike_profile_pic_complete)

# Get pictures from the stored Array in Profile BKMREngine Script
func get_pictures() -> void:
	for pictures: Dictionary in profile_pics_data:
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
	if profile_pictures != []:
		display_picture_texture.texture = profile_pictures[current_picture_index]
	display_likes()

func display_likes() -> void:
	if profile_pics_data.size() == 0 or current_picture_index >= profile_pics_data.size():
		%LikersLabel.text = "No likes yet!"
		%LikeCountLabel.text = "0"
		toggle_like_button([], "")  # Call with empty array and empty picture ID
		return

	var likes: Array = profile_pics_data[current_picture_index].likes
	var picture_id: String = profile_pics_data[current_picture_index].id
	var likes_count: int = likes.size()
	
	var likers_label: String = ""
	
	var usernames: Array = []
	if likes_count > 0:
		for i: int in range(min(likes_count, 3)):
			usernames.append(likes[i].userName)

		if likes_count == 1:
			var first_liker: String = usernames[0]
			for username: String in usernames:
				if PLAYER.username == username:
					first_liker = "you"

			likers_label = "Liked by " + first_liker
		elif likes_count == 2:
			likers_label = "Liked by " + usernames[0] + " and " + usernames[1]
		elif likes_count == 3:
			likers_label = "Liked by " + usernames[0] + ", " + usernames[1] + " and " + usernames[2]
		else:
			likers_label = "Liked by " + usernames[0] + ", " + usernames[1] + ", " + usernames[2] + " and " + str(likes_count - 3) + " others"
		toggle_like_button(usernames, picture_id)  # Always call this method
		%LikersLabel.text = likers_label
		%LikeCountLabel.text = str(likes_count)
	else:
		%LikersLabel.text = "No likes yet!"
		%LikeCountLabel.text = "0"
		toggle_like_button(usernames, picture_id)

func toggle_like_button(usernames: Array, picture_id: String) -> void:
	like_button.button_pressed = PLAYER.username in usernames
	current_picture_id = picture_id

func _on_like_button_pressed() -> void:
	if like_button.button_pressed:
		BKMREngine.Profile.like_profile_picture(current_picture_id)
	else:
		BKMREngine.Profile.unlike_profile_picture(current_picture_id)

func _on_like_profile_pic_complete(message: Dictionary) -> void:
	if message.has("success"):
		@warning_ignore("unsafe_call_argument")
		var new_count_like: String = str(int(%LikeCountLabel.text) + 1)
		%LikeCountLabel.text = new_count_like
		like_button.disabled = false
		BKMREngine.Profile.get_player_profile_pic(%PlayerName.text)
	else:
		like_button.button_pressed = false

func _on_unlike_profile_pic_complete(message: Dictionary) -> void:
	if message.has("error"):
		like_button.button_pressed = true
	else:
		@warning_ignore("unsafe_call_argument")
		var new_count_like: String = str(int(%LikeCountLabel.text) - 1)
		%LikeCountLabel.text = new_count_like
		like_button.disabled = false
	BKMREngine.Profile.get_player_profile_pic(%PlayerName.text)

func _on_left_button_pressed() -> void:
	if profile_pictures.size() > 0:
		current_picture_index = (current_picture_index - 1 + profile_pictures.size()) % profile_pictures.size()
		display_picture_texture.texture = profile_pictures[current_picture_index]
		display_likes()
	
func _on_right_button_pressed() -> void:
	if profile_pictures.size() > 0:
		current_picture_index = (current_picture_index + 1) % profile_pictures.size()
		display_picture_texture.texture = profile_pictures[current_picture_index]
		display_likes()

func _on_visibility_changed() -> void:
	if visible:
		get_pictures()
	else:
		current_picture_index = 0

func _on_close_button_pressed() -> void:
	visible = false
	current_picture_index = 0
	profile_pictures.clear()
	view_picture_close.emit()
