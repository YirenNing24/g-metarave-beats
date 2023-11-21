extends ScrollContainer

# Duration of the scroll animation.
var scroll_duration: float = 0.15
# Current index of the displayed card.
var card_current_index: int = 0
# Array storing the x positions of cards.
var card_x_positions: Array = []

# Reference to the right margin.
@onready var margin_right: int = %MarginContainer.get("theme_override_constants/margin_right")
# Array storing card nodes.
@onready var card_nodes: Array = %HBoxContainer.get_children()
# Space between cards.
@onready var card_space: float = %HBoxContainer.get("theme_override_constants/separation")

# Tween instance for smooth scrolling.
var tween: Tween

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await get_tree().process_frame
	card_nodes = %HBoxContainer.get_children()

	# Calculate and store the x positions of cards.
	for card: Control in card_nodes:
		var card_pos_x: float = (margin_right + card.position.x) - ((size.x - card.size.x) / 2)
		card.pivot_offset = (card.size / 2)
		card_x_positions.append(card_pos_x)
		scroll_horizontal = card_x_positions[card_current_index]

# Process method called on every frame.
func _process(_delta: float) -> void:
	# Check the position of each card and update the current index.
	for _index: float in range(card_x_positions.size()):
		var _card_pos_x: float = card_x_positions[_index]

		var _swipe_length: float = (card_nodes[_index].size.x / 2) + (card_space / 2)
		var _swipe_current_length: float = abs(_card_pos_x - scroll_horizontal)

		if _swipe_current_length < _swipe_length:
			card_current_index = _index

# Function to initiate the scrolling animation.
func scroll() -> void:
	# Create a Tween instance and animate the scroll_horizontal property.
	tween = get_tree().create_tween()
	var _scroll: PropertyTweener = tween.tween_property(
		%InventoryScroll,
		"scroll_horizontal",
		card_x_positions[card_current_index],
		scroll_duration).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)

# GUI input callback function.
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			# Kill the existing tween on mouse button press.
			tween = get_tree().create_tween()
			# warning-ignore:return_value_discarded
			tween.kill()
		else:
			# Initiate the scrolling animation on mouse button release.
			scroll()
