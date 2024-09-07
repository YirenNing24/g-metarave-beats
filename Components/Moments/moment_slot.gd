extends Control

signal liked_by_pressed(likes: Array)
signal add_comment_pressed(moment_id: String)

const comment_preview_scene: PackedScene = preload("res://Components/Moments/comment_preview.tscn")

@onready var player_name: Label = %PlayerName
@onready var time_posted: Label = %TimePosted
@onready var caption_label: Label = %CaptionLabel
@onready var like_count: Label = %LikeCount
@onready var share_count: Label = %ShareCount
@onready var comment_count: Label = %CommentCount

@onready var profile_picture: TextureRect = %ProfilePic
@onready var moment_picture: TextureRect = %MomentPicture

@onready var follow_unfollow_button: TextureButton = %FollowUnfollowButton
@onready var like_button: TextureButton = %LikeButton
@onready var liked_by_button: TextureButton = %LikedBy

var user_profile_picture: Texture 
var moment_id: String
var like_unlike_moment_id: String
var moment_type: String

func _ready() -> void:
	signal_connect()
	BKMREngine.Social.get_mutual()


func signal_connect() -> void:
	BKMREngine.Social.get_mutual_complete.connect(set_follow_button)
	BKMREngine.Social.follow_complete.connect(_on_follow_complete)
	BKMREngine.Social.unfollow_complete.connect(_on_unfollow_complete)
	BKMREngine.Social.like_fan_moments_complete.connect(_on_like_fan_moments_complete)
	BKMREngine.Social.unlike_fan_moments_complete.connect(_on_unlike_fan_moments_complete)


func slot_data(moment_data: Dictionary) -> void:
	player_name.text = moment_data.userName
	moment_id = moment_data.id
	var likes: Array = moment_data.likes
	var shares: Array = moment_data.shares
	var comments: Array = moment_data.comments
	var profile_pic: String
	
	if moment_data.has("caption"):
		caption_label.text = moment_data.caption
	if moment_data.has("image"):
		var picture_image: String = moment_data.image
		set_moment_picture(picture_image)
	if moment_data.has("profilePic"):
		if moment_data.profilePic != null:
			profile_pic = moment_data.profilePic
		else:
			profile_pic = ""
		
	var time: String = moment_data.formattedTime
	set_slot_ui(likes, shares, comments, profile_pic, time)
	
	
func set_slot_ui(likes: Array, shares: Array, comments: Array, profile_pic: String, time: String) -> void:
	set_likes(likes)
	set_shares(shares)
	set_comment(comments)
	set_profile_picture(profile_pic)
	set_post_time(time)
	set_follow_button()


func set_post_time(time: String) -> void:
	%TimePosted.text = time


func set_follow_button(mutuals_list: Array = []) -> void:
	if PLAYER.username == player_name.text:
		follow_unfollow_button.visible = false
	for mutuals: Dictionary in mutuals_list:
		if PLAYER.username == mutuals.username:
			follow_unfollow_button.visible = false
			
		if player_name.text == mutuals.username:
			follow_unfollow_button.button_pressed = true
			%FollowLabel.text = "UNFOLLOW"
			follow_unfollow_button.modulate = "#89898994"
		else:
			%FollowLabel.text = "FOLLOW"
			follow_unfollow_button.modulate = "#ffffff"
			follow_unfollow_button.button_pressed = false
			
			
func set_moment_picture(image_buffer_string: String) -> void:
	var image: Image = Image.new()
	var display_image: Array = JSON.parse_string(image_buffer_string)
	if display_image.is_empty():
		%MomentPicturePanel.visible = false
		return
	else:
		var error: Error = image.load_png_from_buffer(display_image)
		if error != OK:
			print("Error loading image", error)
		else:
			var display_pic: Texture = ImageTexture.create_from_image(image)
			moment_picture.texture = display_pic


func set_profile_picture(image_buffer_string: String) -> void:
	if image_buffer_string == "":
		return
	var image: Image = Image.new()
	var display_image: Array = JSON.parse_string(image_buffer_string)
	if display_image.is_empty():
		%ProfilePic.visible = false
		return
	else:
		var error: Error = image.load_png_from_buffer(display_image)
		if error != OK:
			print("Error loading image", error)
		else:
			var display_pic: Texture = ImageTexture.create_from_image(image)
			%ProfilePic.texture = display_pic


func set_likes(like_data: Array) -> void:
	like_count.text = str(like_data.size())
	for username: String in like_data:
		if PLAYER.username == username:
			like_button.button_pressed = true
			
	if not liked_by_button.pressed.is_connected(_on_liked_by_button_pressed):
		var _connect: int = liked_by_button.pressed.connect(_on_liked_by_button_pressed.bind(like_data))
	
	
func _on_liked_by_button_pressed(like_data: Array) -> void:
	liked_by_pressed.emit(like_data)
	
	
func set_shares(share_data: Array) -> void:
	share_count.text = str(share_data.size())
	
	
func set_comment(comment_data: Array) -> void:
	if %CommentPreviewContainer.get_children().size() > 0:
		for comment: Control in %CommentPreviewContainer.get_children():
			comment.queue_free()
	
	comment_count.text = str(comment_data.size())
	var comment_preview: Control


	# Instantiate the last two comment previews
	for i: int in range(max(0, comment_data.size() - 2), comment_data.size()):
		var comment: Dictionary = comment_data[i]
		comment_preview = comment_preview_scene.instantiate()
		comment_preview.get_node("HBoxContainer/CommentUsername").text = comment["userName"] + " :"
		comment_preview.get_node("HBoxContainer/Comment").text = comment["comment"]
		%CommentPreviewContainer.add_child(comment_preview)

	if comment_data.size() < 2:
		print("Less than two comments available")


func _on_like_button_pressed() -> void:
	like_button.disabled = true
	like_unlike_moment_id = moment_id
	if like_button.button_pressed:
		BKMREngine.Social.like_fan_moment(moment_id)
	else:
		BKMREngine.Social.unlike_fan_moment(moment_id)
	
func _on_like_fan_moments_complete(message: Dictionary) -> void:
	if like_unlike_moment_id == moment_id:
		if message.has("error"):
			like_button.button_pressed = false
			
		else:
			set_new_like_count(1)
		like_button.disabled = false
	
	
func _on_unlike_fan_moments_complete(message: Dictionary) -> void:
	if like_unlike_moment_id == moment_id:
		if message.has("error"):
			like_button.button_pressed = true
		else:
			set_new_like_count(-1)
		like_button.disabled = false


func set_new_like_count(count: int) -> void:
	var current_count: int = int(like_count.text)
	var new_count: String = str(current_count + count)
	like_count.text = new_count


func _on_follow_unfollow_button_pressed() -> void:
	if %FollowLabel.text == "UNFOLLOW":
		BKMREngine.Social.unfollow(player_name.text)
	else:
		BKMREngine.Social.follow(player_name.text)
	follow_unfollow_button.disabled = true
	
func _on_follow_complete(message: Dictionary) -> void:
	if message.has("error"):
		follow_unfollow_button.button_pressed = false
	else:
		%FollowLabel.text = "UNFOLLOW"
		follow_unfollow_button.modulate = "#89898994"
	follow_unfollow_button.disabled = false
	
	
func _on_unfollow_complete(message: Dictionary) -> void:
	if message.has("error"):
		follow_unfollow_button.button_pressed = true
	else:
		%FollowLabel.text = "FOLLOW"
		follow_unfollow_button.modulate = "#ffffff"
	follow_unfollow_button.disabled = false


func _on_comment_button_pressed() -> void:
	add_comment_pressed.emit(moment_id, moment_type)


func add_new_comment(new_comment: String) -> void:
	var delete_comment: Control = %CommentPreviewContainer.get_child(0)
	if delete_comment != null:
		delete_comment.queue_free()
	var comment_preview: Control
	comment_preview = comment_preview_scene.instantiate()
	comment_preview.get_node("HBoxContainer/CommentUsername").text = PLAYER.username + " :"
	comment_preview.get_node("HBoxContainer/Comment").text = new_comment
	%CommentPreviewContainer.add_child(comment_preview)
