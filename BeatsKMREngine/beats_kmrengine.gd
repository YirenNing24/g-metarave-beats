@tool
extends EditorPlugin

# Called when the plugin is added to the scene tree.
func _enter_tree() -> void:
	# Add the BeatsKMREngine as an autoload singleton.
	add_autoload_singleton("BeatsKMREngine", "res://BeatsKMREngine.gd")

# Called when the plugin is removed from the scene tree.
func _exit_tree() -> void:
	# Remove the BeatsKMREngine autoload singleton.
	remove_autoload_singleton("BeatsKMREngine")
