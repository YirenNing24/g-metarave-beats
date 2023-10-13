@tool
extends EditorPlugin

func _enter_tree():
	add_autoload_singleton("BeatsKMREngine", "res://BeatsKMREngine.gd")

func _exit_tree():
	remove_autoload_singleton("BeatsKMREngine")
