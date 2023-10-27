extends ScrollContainer


var song_scale: float = 1.0
var song_current_scale: float = 1.3
var scroll_duration: float = .15

var song_current_index: int = 0
var song_x_positions: Array = []

@onready var margin_right: int = %MarginContainer.get("theme_override_constants/margin_right")
@onready var song_space:int = %HBoxContainer.get("theme_override_constants/separation")
@onready var song_nodes: Array
@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var artist: String

var tween: Tween

func _ready() -> void:
	await get_tree().process_frame
	song_nodes = %HBoxContainer.get_children()
	for song: Node in song_nodes:
		var song_pos_x: float = (margin_right + song.position.x) - ((size.x - song.size.x) / 2)
		song.pivot_offset = (song.size / 2)
		song_x_positions.append(song_pos_x)
		scroll_horizontal = song_x_positions[song_current_index]
	scroll()
		
func _process(_delta: float) -> void:
	for _index: int in range(song_x_positions.size()):
		var _card_pos_x: float = song_x_positions[_index]

		var _swipe_length: float = (song_nodes[_index].size.x / 2.0) + (song_space / 2.0)
		var _swipe_current_length: int = abs(_card_pos_x - scroll_horizontal)
		var _card_scale: float  = remap(_swipe_current_length, _swipe_length, 0, song_scale, song_current_scale)
		var _card_opacity: float = remap(_swipe_current_length, _swipe_length, 0, 0.3, 1)
		
		_card_scale = clamp(_card_scale, song_scale, song_current_scale)
		_card_opacity = clamp(_card_opacity, 0.3, 1)
		
		song_nodes[_index].scale = Vector2(_card_scale, _card_scale)
		song_nodes[_index].modulate.a = _card_opacity
		
		if _swipe_current_length < _swipe_length:
			song_current_index = _index
			
			
func scroll() -> void:
	tween = get_tree().create_tween()
	var _tween_scroll: PropertyTweener = tween.tween_property(
		scroll_container,
		"scroll_horizontal",
		song_x_positions[song_current_index],
		scroll_duration 
		).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	for index: int in range(song_nodes.size()):
		var _song_scale: float = song_current_scale if index == song_current_index else song_scale
		var song_nodes_index: Object = song_nodes[index]
		var _tween_scale: PropertyTweener = tween.tween_property(
			song_nodes_index,
			"scale",
			Vector2(_song_scale, _song_scale),
			scroll_duration 
		)
		
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			tween.kill()
		else:
			scroll()
