extends Control

const moment_slot_scene: PackedScene = preload("res://Components/Moments/moment_slot.tscn")
const liker_slot_scene: PackedScene = preload("res://Components/Moments/liker_slot.tscn")

@onready var make_post: Control = $MakePost
@onready var liked_by: Control = %LikedBy
@onready var add_comment: Control = %AddComment

@onready var user_profile_picture: Texture 

@onready var moments_container: VBoxContainer = %HotMomentsContainer
@onready var my_moments_container: VBoxContainer = %MyMomentsContainer


var hot_moments_offset: int = 0
var no_hot_moments_data: bool = false

var my_moments_offset: int = 0
var no_my_moments_data: bool = false

var latest_moments_offset: int = 0
var no_latest_moments_data: bool = false

var following_moments_offset: int = 0
var no_following_moments_data: bool = false

func _ready() -> void:
	signal_connect()
	
func _on_visibility_changed() -> void:
	if visible == true:
		BKMREngine.Social.get_hot_fan_moments(5, 0)
	else:
		for moments: Control in %HotMomentsContainer.get_children():
			moments.queue_free()
		%MomentTab.current_tab = 0

func signal_connect() -> void:
	BKMREngine.Social.get_hot_fan_moments_complete.connect(_on_get_hot_fan_moments_complete)
	BKMREngine.Social.get_my_fan_moments_complete.connect(_on_get_my_fan_moments_complete)
	BKMREngine.Social.get_latest_fan_moments_complete.connect(_on_get_latest_fan_moments_complete)
	BKMREngine.Social.get_following_fan_moments_complete.connect(_on_get_following_fan_moments_complete)
	var _connect: int = add_comment.fan_moment_comment_complete.connect(_fan_moment_comment_complete)


func find_child_by_id(container: Control, id: String) -> Control:
	for child: Control in container.get_children():
		if child.has_meta("id") and child.get_meta("id") == id:
			return child
	return null


func _on_get_hot_fan_moments_complete(moments_data: Array) -> void:
	if moments_data.is_empty():
		no_hot_moments_data = true
		return

	for moment_data: Dictionary in moments_data:
		var moment_id: String = moment_data["id"]
		var existing_moment: Control = find_child_by_id(moments_container, moment_id)

		if existing_moment:
			# Update the existing moment
			existing_moment.slot_data(moment_data)
		else:
			# Create a new moment slot
			var moment_slot: Control = moment_slot_scene.instantiate()
			
			if PLAYER.username == moment_data["userName"]:
				moment_slot.get_node('VBoxContainer/HBoxContainer/Panel/ProfilePic').texture = user_profile_picture

			# Connect signals if not already connected
			if not moment_slot.liked_by_pressed.is_connected(_on_liked_by_button_pressed):
				moment_slot.liked_by_pressed.connect(_on_liked_by_button_pressed)
			
			if not moment_slot.add_comment_pressed.is_connected(_on_add_comment_pressed):
				moment_slot.add_comment_pressed.connect(_on_add_comment_pressed)
			
			# Add the moment slot at the top of the container
			if moments_container.get_child_count() > 0:
				moments_container.add_child(moment_slot)
				moments_container.move_child(moment_slot, 0)
			else:
				moments_container.add_child(moment_slot)
			
			moment_slot.set_meta("id", moment_data["id"])
			moment_slot.slot_data(moment_data)
			moment_slot.moment_type = "hot"
			
			
func _on_get_my_fan_moments_complete(moments_data: Array) -> void:
	if moments_data.is_empty():
		no_my_moments_data = true
		return
	for moment_data: Dictionary in moments_data:
		var moment_id: String = moment_data["id"]
		var existing_moment: Control = find_child_by_id(my_moments_container, moment_id)

		if existing_moment:
			# Update the existing moment
			existing_moment.slot_data(moment_data)
		else:
			# Create a new moment slot
			var moment_slot: Control = moment_slot_scene.instantiate()
			
			if PLAYER.username == moment_data["userName"]:
				moment_slot.get_node('VBoxContainer/HBoxContainer/Panel/ProfilePic').texture = user_profile_picture

			# Connect signals if not already connected
			if not moment_slot.liked_by_pressed.is_connected(_on_liked_by_button_pressed):
				moment_slot.liked_by_pressed.connect(_on_liked_by_button_pressed)
			
			if not moment_slot.add_comment_pressed.is_connected(_on_add_comment_pressed):
				moment_slot.add_comment_pressed.connect(_on_add_comment_pressed)
				
			if %MyMomentsContainer.get_child_count() > 0:
				%MyMomentsContainer.add_child(moment_slot)
				%MyMomentsContainer.move_child(moment_slot, 0)
			else:
				%MyMomentsContainer.add_child(moment_slot)
			moment_slot.set_meta("id", moment_data["id"])
			moment_slot.slot_data(moment_data)
			moment_slot.moment_type = "my"
	
	
func _on_get_latest_fan_moments_complete(moments_data: Array) -> void:
	if moments_data.is_empty():
		no_latest_moments_data = true
		return
	for moment_data: Dictionary in moments_data:
		var moment_id: String = moment_data["id"]
		var latest_moment_container: Control = %LatestMomentsContainer
		var existing_moment: Control = find_child_by_id(latest_moment_container, moment_id)

		if existing_moment:
			# Update the existing moment
			existing_moment.slot_data(moment_data)
		else:
			# Create a new moment slot
			var moment_slot: Control = moment_slot_scene.instantiate()
			
			if PLAYER.username == moment_data["userName"]:
				moment_slot.get_node('VBoxContainer/HBoxContainer/Panel/ProfilePic').texture = user_profile_picture

			# Connect signals if not already connected
			if not moment_slot.liked_by_pressed.is_connected(_on_liked_by_button_pressed):
				moment_slot.liked_by_pressed.connect(_on_liked_by_button_pressed)
			
			if not moment_slot.add_comment_pressed.is_connected(_on_add_comment_pressed):
				moment_slot.add_comment_pressed.connect(_on_add_comment_pressed)
				
			if %LatestMomentsContainer.get_child_count() > 0:
				%LatestMomentsContainer.add_child(moment_slot)
				%LatestMomentsContainer.move_child(moment_slot, 0)
			else:
				%LatestMomentsContainer.add_child(moment_slot)
			moment_slot.set_meta("id", moment_data["id"])
			moment_slot.slot_data(moment_data)
			moment_slot.moment_type = "latest"
	
	
func _on_get_following_fan_moments_complete(moments_data: Array) -> void:
	if moments_data.is_empty():
		no_latest_moments_data = true
		return
	for moment_data: Dictionary in moments_data:
		var moment_id: String = moment_data["id"]
		var following_moments_container: Control = %FollowingMomentsContainer
		var existing_moment: Control = find_child_by_id(following_moments_container, moment_id)

		if existing_moment:
			# Update the existing moment
			existing_moment.slot_data(moment_data)
		else:
			# Create a new moment slot
			var moment_slot: Control = moment_slot_scene.instantiate()
			
			if PLAYER.username == moment_data["userName"]:
				moment_slot.get_node('VBoxContainer/HBoxContainer/Panel/ProfilePic').texture = user_profile_picture

			# Connect signals if not already connected
			if not moment_slot.liked_by_pressed.is_connected(_on_liked_by_button_pressed):
				moment_slot.liked_by_pressed.connect(_on_liked_by_button_pressed)
			
			if not moment_slot.add_comment_pressed.is_connected(_on_add_comment_pressed):
				moment_slot.add_comment_pressed.connect(_on_add_comment_pressed)
				
			if %FollowingMomentsContainer.get_child_count() > 0:
				%FollowingMomentsContainer.add_child(moment_slot)
				%FollowingMomentsContainer.move_child(moment_slot, 0)
			else:
				%FollowingMomentsContainer.add_child(moment_slot)
			moment_slot.set_meta("id", moment_data["id"])
			moment_slot.moment_type = "following"
			moment_slot.slot_data(moment_data)
			
			
func _on_make_post_button_pressed() -> void:
	make_post.visible = true


func _on_liked_by_button_pressed(like_data: Array) -> void:
	if BKMREngine.Profile.get_profile_pics_complete.is_connected(_on_get_profile_pics_complete):
		BKMREngine.Profile.get_profile_pics_complete.disconnect(_on_get_profile_pics_complete)
	BKMREngine.Profile.get_profile_pics_complete.connect(_on_get_profile_pics_complete)
	BKMREngine.Profile.get_profile_pics(like_data)
	
	
func _on_get_profile_pics_complete(profile_pics: Array) -> void:
	liked_by.populate_likers(profile_pics)
	
	
func _on_add_comment_pressed(moment_id: String, moment_type: String) -> void:
	add_comment.visible = true
	add_comment.moment_id = moment_id
	add_comment.moment_type = moment_type
	
	
func _on_close_button_pressed() -> void:
	visible = false


func _fan_moment_comment_complete(moment_id: String, moment_type: String) -> void:
	if moment_type == "":
		return
		
	var container_path: String = "Panel/BackgroundTexture/HBoxContainer/Panel/MomentTab/" + moment_type.capitalize() + "/SmoothScrollContainer/" + moment_type.capitalize() + "MomentsContainer"
	
	var filled_moments_container: VBoxContainer = get_node(container_path)
	if filled_moments_container.get_children() != null:
		for moment: Control in filled_moments_container.get_children():
			if moment.moment_id == moment_id:
				var new_comment: String = add_comment.get_node("Panel/VBoxContainer/Panel/VBoxContainer/Panel/VBoxContainer/CommentTextEdit").text
				moment.add_new_comment(new_comment)


func _on_moment_tab_tab_changed(tab: int) -> void:
	if tab == 3:
		BKMREngine.Social.get_my_fan_moments(5, 0)
	elif tab == 2:
		BKMREngine.Social.get_following_fan_moments(5, 0)
	elif tab == 1:
		BKMREngine.Social.get_latest_fan_moments(5, 0)
	elif tab == 0:
		BKMREngine.Social.get_hot_fan_moments(5, 0)
	
func _on_smooth_scroll_container_hot_moments_v_scroll_top_drag() -> void:
	if no_hot_moments_data:
		return
	BKMREngine.Social.get_hot_fan_moments(5, hot_moments_offset)
	hot_moments_offset += 5
	
func _on_smooth_scroll_container_my_moments_v_scroll_top_drag() -> void:
	if no_my_moments_data:
		return
	BKMREngine.Social.get_my_fan_moments(5, hot_moments_offset)
	my_moments_offset += 5

func _on_smooth_scroll_container_latest_moment_v_scroll_top_drag() -> void:
	if no_latest_moments_data:
		return
	BKMREngine.Social.get_latest_fan_moments(5, hot_moments_offset)
	latest_moments_offset += 5

func _on_smooth_scroll_container_following_moment_v_scroll_top_drag() -> void:
	if no_following_moments_data:
		return
	BKMREngine.Social.get_following_fan_moments(5, following_moments_offset)
	following_moments_offset += 5
