extends Control


@onready var note_line_edit: LineEdit = %NoteLineEdit
@onready var submit_button: TextureButton = %SubmitButton
@onready var loading_panel: Panel = %FilterPanel


func _ready() -> void:
	BKMREngine.Profile.update_my_note_complete.connect(_on_update_my_note_complete)

func _on_notes_line_edit_text_submitted(my_note: String) -> void:
	if my_note.length() > 60 or my_note.length() == 0:
		return
		
	BKMREngine.Profile.update_my_note(my_note)
	loading_panel.fake_loader()
		
func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if visible:
			visible = false

func _on_submit_button_pressed() -> void:
	if note_line_edit.text.length() > 60 or note_line_edit.text.length() == 0:
		return
		
	BKMREngine.Profile.update_my_note(note_line_edit.text)
	loading_panel.fake_loader()

func _on_update_my_note_complete(_message: Dictionary) -> void:
	loading_panel.tween_kill()
	BKMREngine.Profile.get_my_note()
