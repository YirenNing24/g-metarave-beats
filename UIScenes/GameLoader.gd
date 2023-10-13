extends Node

var previous_texture: Texture = null
var next_texture: Texture = null


func load_scene(current_scene, next_scene):
	var game_loader: Node = preload("res://UIScenes/GameLoader.tscn").instantiate()
	var loader: Resource = ResourceLoader.load(next_scene)
	if loader == null:
		print("error occured while loading the scene")
		return
		
	else:
		set_process(false)
		current_scene.queue_free()
		get_tree().get_root().call_deferred("add_child", game_loader)
		game_loader.get_child(0).set_texture(previous_texture)
		game_loader.get_child(1).set_texture(next_texture)
		var loading_animation:AnimationPlayer = game_loader.get_node("AnimationPlayer")
		await(loading_animation.animation_finished)
		get_tree().change_scene_to_packed(loader)
		
		game_loader.queue_free()
		
