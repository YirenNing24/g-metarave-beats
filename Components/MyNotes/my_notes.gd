extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	#BKMREngine.Profile.get_my_note_complete.connect(_on_get_my_note_complete)
	#BKMREngine.Profile.get_my_note()

func _on_get_my_note_complete(my_note: Dictionary) -> void:
	if my_note.is_empty():
		return
	if my_note.has("note"):
		%MyNotes.text = my_note.note
