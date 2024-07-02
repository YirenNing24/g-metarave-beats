extends Control

signal fan_moment_comment_complete

@onready var comment_text_edit: TextEdit = %CommentTextEdit
@onready var character_count: Label = %CharacterCount

var moment_id: String
var moment_type: String

func _ready() -> void:
	connect_signal()

func connect_signal() -> void:
	BKMREngine.Social.comment_fan_moment_complete.connect(_on_comment_fan_moment_complete)

func _on_comment_text_edit_text_changed() -> void:
	if comment_text_edit.text.length() > 160:
		comment_text_edit.text = comment_text_edit.text.substr(0, 160)
		character_count.add_theme_color_override("font_color", "d2390c")
	else:
		character_count.add_theme_color_override("font_color", "dfdfdf")
	character_count.text = str(comment_text_edit.text.length()) + "  / 160"

func _on_submit_button_pressed() -> void:
	if comment_text_edit.text.length() > 260:
		return
	
	var comment_data: Dictionary = { 
		"id": moment_id,
		"comment": comment_text_edit.text
	}
	BKMREngine.Social.comment_fan_moment(comment_data)
	%SubmitButton.disabled = true
	
func _on_comment_fan_moment_complete(_message: Dictionary) -> void:
	visible = false
	%SubmitButton.disabled = false
	fan_moment_comment_complete.emit(moment_id, moment_type)
	
func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if visible:
			visible = false
		else:
			comment_text_edit.text = ""
			
