extends ScrollContainer

# Variables to control the behavior
var image_scale: float = 1.0
var image_current_scale: float = 1.3
var scroll_duration: float = .15

var image_current_index: int = 0
var image_x_positions: Array = []

# Reference to theme constants and UI elements
@onready var margin_right: int = %MarginContainer.get("theme_override_constants/margin_right")
@onready var image_space: int = %HBoxContainer.get("theme_override_constants/separation")
@onready var image_nodes: Array
@onready var image_scroll_container: ScrollContainer = %SongScrollContainer
@onready var artist: String

# Tween for animations
var tween: Tween

func _ready() -> void:
	# Wait for the next frame to ensure all nodes are properly initialized
	await get_tree().process_frame

	# Get child song nodes and calculate their initial positions
	image_nodes = %HBoxContainer.get_children()
	for image: Control in image_nodes:
		var image_pos_x: float = (margin_right + image.position.x) - ((size.x - image.size.x) / 2)
		image.pivot_offset = (image.size / 2)
		image_x_positions.append(image_pos_x)
		
	# Set initial scroll position and perform the initial scroll
	scroll_horizontal = image_x_positions[image_current_index]
	
	scroll()

# Process function for updating UI elements during runtime
func _process(_delta: float) -> void:
	for _index: int in range(image_x_positions.size()):
		var _card_pos_x: float = image_x_positions[_index]

		# Calculate scaling and opacity based on the current scroll position
		var _swipe_length: float = (image_nodes[_index].size.x / 2.0) + (image_space / 2.0)
		var _swipe_current_length: int = abs(_card_pos_x - scroll_horizontal)
		var _card_scale: float  = remap(_swipe_current_length, _swipe_length, 0, image_scale, image_current_scale)
		var _card_opacity: float = remap(_swipe_current_length, _swipe_length, 0, 0.3, 1)
		
		# Ensure scaling and opacity stay within defined limits
		_card_scale = clamp(_card_scale, image_scale, image_current_scale)
		_card_opacity = clamp(_card_opacity, 0.3, 1)
		
		# Apply scaling and opacity to image nodes
		image_nodes[_index].scale = Vector2(_card_scale, _card_scale)
		image_nodes[_index].modulate.a = _card_opacity
		
		# Update the current image index if within swipe range
		if _swipe_current_length < _swipe_length:
			image_current_index = _index

# Function to initiate the scrolling animation
func scroll() -> void:
	# Create a tween for smooth scrolling
	tween = get_tree().create_tween()
	var _tween_scroll: PropertyTweener = tween.tween_property(
		image_scroll_container,
		"scroll_horizontal",
		image_x_positions[image_current_index],
		scroll_duration 
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Apply scaling animation to all image nodes
	for index: int in range(image_nodes.size()):
		var _image_scale: float
		if index == image_current_index:
			_image_scale =image_current_scale
		else:
			_image_scale = image_scale
			
		var image_nodes_index: Object = image_nodes[index]
		var _tween_scale: PropertyTweener = tween.tween_property(
			image_nodes_index,
			"scale",
			Vector2(_image_scale, _image_scale),
			scroll_duration 
		)

# Input handling for user interaction
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			# Kill the current tween when the mouse button is pressed
			kill_tween()
		else:
			# Resume scrolling when the mouse button is released
			scroll()

func song_unfocused_selected(index: int) -> void:
	if index != image_current_index:
		image_current_index = index
		scroll()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	kill_tween()
	
func kill_tween() -> void:
	if tween:
		tween.kill()
