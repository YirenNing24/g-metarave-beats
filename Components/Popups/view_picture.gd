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
	BKMREngine.Profile.like_profile_pic_complete.connect(_on_like_profile_pic_complete)
	BKMREngine.Profile.unlike_profile_pic_complete.connect(_on_unlike_profile_pic_complete)
	
	
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
	print("ids: ", profile_pics_data[current_picture_index]._id)
	display_picture()
	
	
# Display the first picture and handles the switching to other pictures available 
func display_picture() -> void:
	if not profile_pictures.is_empty():
		display_picture_texture.texture = profile_pictures[current_picture_index]
	display_likes()
	if current_picture_index == 0:
		%ChangeProfilePicButton.visible = false
	display_change_profile_pic_button()
	
	
func display_likes() -> void:
	if profile_pics_data.is_empty() or current_picture_index >= profile_pics_data.size():
		_update_likes_ui("No likes yet!", 0, [], "")
		return

	var picture: Dictionary = profile_pics_data[current_picture_index]
	var likes: Array = picture.likes
	var picture_id: String = picture._id
	var likes_count: int = likes.size()

	if likes_count == 0:
		_update_likes_ui("No likes yet!", 0, [], picture_id)
		return

	@warning_ignore("unsafe_call_argument")
	var usernames: Array = likes.slice(0, min(likes_count, 3)).map(func(like: Dictionary) -> String: return like.userName)
	if PLAYER.username in usernames:
		usernames[usernames.find(PLAYER.username)] = "you"

	var likers_label: String
	match likes_count:
		1: likers_label = "Liked by " + usernames[0]
		2: likers_label = "Liked by " + " and ".join(usernames)
		3: likers_label = "Liked by " + ", ".join(usernames) 
		_: likers_label = "Liked by " + ", ".join(usernames) + " and " + str(likes_count - 3) + " others"

	_update_likes_ui(likers_label, likes_count, usernames, picture_id)

func _update_likes_ui(label: String, count: int, usernames: Array, picture_id: String) -> void:
	%LikersLabel.text = label
	%LikeCountLabel.text = str(count)
	toggle_like_button(usernames, picture_id)
	
	
func toggle_like_button(usernames: Array, picture_id: String) -> void:
	like_button.button_pressed = "you" in usernames
	current_picture_id = picture_id
	
	
func _on_like_button_pressed() -> void:
	like_button.disabled = true
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
		
		# ✅ Add this locally
		var picture: Dictionary = profile_pics_data[current_picture_index]
		var likes: Array = picture.likes
		likes.append({"userName": PLAYER.username})
		picture.likes = likes
		profile_pics_data[current_picture_index] = picture

		display_likes()
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
		
		# ✅ Remove like locally
		var picture: Dictionary = profile_pics_data[current_picture_index]
		var likes: Array = picture.likes
		for i: int in range(likes.size()):
			if likes[i].userName == PLAYER.username:
				likes.remove_at(i)
				break
		picture.likes = likes
		profile_pics_data[current_picture_index] = picture

		display_likes()
	
func _on_left_button_pressed() -> void:
	if profile_pictures.size() > 0:
		current_picture_index = (current_picture_index - 1 + profile_pictures.size()) % profile_pictures.size()
		display_picture_texture.texture = profile_pictures[current_picture_index]
		display_likes()
	display_change_profile_pic_button()	
		
	
func _on_right_button_pressed() -> void:
	if profile_pictures.size() > 0:
		current_picture_index = (current_picture_index + 1) % profile_pictures.size()
		display_picture_texture.texture = profile_pictures[current_picture_index]
		display_likes()
	display_change_profile_pic_button()
	
	
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
	
	
func _on_change_profile_pic_button_pressed() -> void:
	var new_profile_pic: Dictionary = profile_pics_data[current_picture_index]
	var id: String = new_profile_pic._id
	BKMREngine.Profile.change_profile_picture(id)
	
	
func display_change_profile_pic_button() -> void:
	if current_picture_index == 0:
		%ChangeProfilePicButton.visible = false
	else:
		%ChangeProfilePicButton.visible = true
