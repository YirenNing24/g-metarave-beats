extends Node

var previous_texture: Texture2D
var next_texture: Texture2D

func load_scene(current_scene: Control, next_scene: String) -> bool:
	var game_loader: Control = preload("res://UIScenes/GameLoader.tscn").instantiate()
	
	
	print(next_scene, 'fuck youuuu')
	var loader: Resource = ResourceLoader.load(next_scene)
	var scene: PackedScene = loader
	if loader == null:
		print("error occured while loading the scene")
		return false
	else:
		set_process(false)
		current_scene.queue_free()
		get_tree().get_root().call_deferred("add_child", game_loader)
		game_loader.get_child(0).set_texture(previous_texture)
		game_loader.get_child(1).set_texture(next_texture)
		var loading_animation: AnimationPlayer = game_loader.get_node("AnimationPlayer")
		await loading_animation.animation_finished
		var _change_scene: Error = get_tree().change_scene_to_packed(scene)
		game_loader.queue_free()
		return true
