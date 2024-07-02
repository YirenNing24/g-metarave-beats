extends Control

@onready var post_pic: TextureRect = %PostPic
@onready var comment_text_edit: TextEdit = %CommentTextEdit

@onready var character_count: Label = %CharacterCount
@onready var filter_panel: Panel = %FilterPanel

#Get image plugin
var get_image: Object
const plugin_name: String = "GodotGetImage"

var buffer_image: PackedByteArray

func _ready() -> void:
	load_plugin()
	connect_signal()
	
func connect_signal() -> void:
	BKMREngine.Social.post_fan_moments_complete.connect(_on_post_fan_moments_complete)

#region Get Image from Server
func load_plugin() -> void:
	if Engine.has_singleton(plugin_name):
		get_image = Engine.get_singleton(plugin_name)
		
	else:
		print("Could not load plugin: ", plugin_name)
		
	if get_image:
		var options: Dictionary = {
		"image_height" : 200,
		"image_width" : 100,
		"keep_aspect" : true,
		"image_format" : "png"
	}
		get_image.setOptions(options)
		plugin_signal_connect()

func plugin_signal_connect() -> void:
	get_image.image_request_completed.connect(_on_image_request_completed)
	get_image.error.connect(_on_get_image_error)
	get_image.permission_not_granted_by_user.connect(_on_permission_not_granted_by_user)

func _on_upload_post_pic_button_pressed() -> void:
	#Select single images from gallery
	if post_pic.texture == null:
		if get_image:
			get_image.getGalleryImage()
		else:
			print(plugin_name, " plugin not loaded!")
	else:
		post_pic.texture = null
		
#region Get Image call backs
func _on_image_request_completed(object_image: Dictionary) -> void:
	#Object image is a dictionary of image packed byte array[]
	if len(object_image.values()) != 1:
			return
	for image_buffer: PackedByteArray in object_image.values():
		var image: Image = Image.new()
		var error: Error = image.load_png_from_buffer(image_buffer)
		if error != OK:
			print("Error loading image", error)
		else:
			print("We are now loading texture... ")
			var uploaded_pic: Texture =  ImageTexture.create_from_image(image)
			post_pic.texture = uploaded_pic
	
func _on_get_image_error(_error: String) -> void:
	pass
	
func _on_permission_not_granted_by_user() -> void:
	# Set the plugin to ask user for permission again
	get_image.resendPermission()
#endregion

func _on_post_fan_moments_complete(_message: Dictionary) -> void:
	filter_panel.tween_kill()
	visible = false
	character_count.text = "0 / 260"
	
func _on_comment_text_edit_text_changed() -> void:
	if comment_text_edit.text.length() > 260:
		comment_text_edit.text = comment_text_edit.text.substr(0, 260)
		character_count.add_theme_color_override("font_color", "d2390c")
	else:
		character_count.add_theme_color_override("font_color", "dfdfdf")
		
	character_count.text = str(comment_text_edit.text.length()) + "  / 260"

func _on_submit_button_pressed() -> void:
	if comment_text_edit.text.length() > 260:
		return
	
	var post_image: PackedByteArray
	if buffer_image != null:
		post_image = buffer_image
	
	if buffer_image == null and comment_text_edit.text == "":
		return
	
	var post: Dictionary = {
		"caption": comment_text_edit.text,
		"image": post_image
	}
	BKMREngine.Social.post_fan_moments(post)
	filter_panel.fake_loader()
	
func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if visible:
			visible = false
