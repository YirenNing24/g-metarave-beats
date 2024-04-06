# Class extending Node to handle scene loading transitions.
extends Node

# Texture for the previous scene.
var previous_texture: Texture2D
# Texture for the next scene.
var next_texture: Texture2D

# Function to load the specified scene, transitioning from the current scene.
#
# Parameters:
# - current_scene: The Control node representing the current scene.
# - next_scene: The file path of the next scene to be loaded.
#
# Returns:
# - bool: True if the scene transition is successful, False otherwise.
func load_scene(current_scene: Variant, next_scene: String) -> bool:
	# Instantiate the GameLoader scene.
	var game_loader: Control = preload("res://UIScenes/GameLoader.tscn").instantiate()
	
	# Load the next scene as a PackedScene.
	var loader: Resource = ResourceLoader.load(next_scene)
	var scene: PackedScene = loader
	
	# Check if there is an error while loading the scene.
	if loader == null:
		print("Error occurred while loading the scene")
		return false
	else:
		# Disable further processing to avoid conflicts during scene transition.
		set_process(false)
		# Free the resources of the current scene.
		current_scene.queue_free()
		# Add the GameLoader to the scene tree, setting textures for transition.
		get_tree().get_root().call_deferred("add_child", game_loader)
		game_loader.get_child(0).set_texture(previous_texture)
		game_loader.get_child(1).set_texture(next_texture)
		# Get the AnimationPlayer from GameLoader for loading animation.
		var loading_animation: AnimationPlayer = game_loader.get_node("AnimationPlayer")
		# Wait for the loading animation to finish.
		await loading_animation.animation_finished
		# Change the scene to the next scene.
		var _change_scene: Error = get_tree().change_scene_to_packed(scene)
		# Free the GameLoader resources.
		game_loader.queue_free()
		# Enable processing for future operations.
		set_process(true)
		# Return True indicating a successful scene transition.
		return true
