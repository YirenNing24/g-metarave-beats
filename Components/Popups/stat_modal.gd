extends Control

@onready var animation_player:AnimationPlayer = %AnimationPlayer
@onready var stat_points_display:Label = %AvailablePoints
@onready var main_stats:VBoxContainer = %MainStats
@onready var path_main_stats:String = "main_screen/FilterPanel/stat_modal/Panel/VBoxContainer/HBoxContainer/MainStats/"

var stat_points:int = 0
var visual_add:int = 0
var mainvocalist_add:int = 0
var leadvocalist_add:int = 0
var maindancer_add:int = 0
var leaddancer_add:int = 0
var rapper_add:int = 0
var leadrapper_add:int = 0


func _ready():
	stat_points = PLAYER.stat_points
	stat_points_display.text = str(PLAYER.stat_points)
	load_stats()
	if stat_points == 0:
		for button in get_tree().get_nodes_in_group("PlusButtons"):
			button.set_disabled(true)
			button.modulate = "7d7d7d"
	else:
		for button in get_tree().get_nodes_in_group("PlusButtons"):
			button.set_disabled(false)
	for button in get_tree().get_nodes_in_group("PlusButtons"):
		button.pressed.connect(increase_stat.bind(button.get_node("../").get_name()))
		
	for button in get_tree().get_nodes_in_group("MinusButtons"):
		button.pressed.connect(decrease_stat.bind(button.get_node("../").get_name()))
		button.set_disabled(true)
		button.modulate = "7d7d7d"
		

func load_stats():
	for stats in PLAYER.stat_points_saved.keys():
		for stat in main_stats.get_children():
			var stat_name:String = stat.name
			var name_stat:String= stat.name.to_lower()
			if stats.to_lower() == name_stat.to_lower():
				get_tree().get_root().get_node(path_main_stats + stat_name + "/Stats/Value").set_text(str(PLAYER.stat_points_saved[stats]))
		

func increase_stat(stat):
	set(stat.to_lower() + "_add", get(stat.to_lower() + "_add") + 1)
	get_tree().get_root().get_node(path_main_stats + stat + "/Stats/Change").set_text(
									"+" + str(get(stat.to_lower() + "_add")) + " ")
	get_tree().get_root().get_node(path_main_stats + stat + "/Min").set_disabled(false)
	get_tree().get_root().get_node(path_main_stats + stat + "/Min").modulate  = "ffffff"
	get_tree().get_root().get_node(path_main_stats + stat + "/HBoxContainer/TextureProgressBar").value += 1
	stat_points -= 1
	stat_points_display.text = str(stat_points)
	if stat_points == 0:
		for button in get_tree().get_nodes_in_group("PlusButtons"):
			button.set_disabled(true)
			button.modulate = "7d7d7d"
	
	
func decrease_stat(stat):
	set(stat.to_lower() + "_add", get(stat.to_lower() + "_add") - 1)
	get_tree().get_root().get_node(path_main_stats + stat + "/HBoxContainer/TextureProgressBar").value -= 1
	if get(stat.to_lower() + "_add") == 0:
		get_tree().get_root().get_node(path_main_stats + stat + "/Min").set_disabled(true)
		get_tree().get_root().get_node(path_main_stats + stat + "/Min").modulate  = "7d7d7d"
		get_tree().get_root().get_node(path_main_stats + stat + "/Stats/Change").set_text("")
	else:
		get_tree().get_root().get_node(path_main_stats + stat + "/Stats/Change").set_text(
										"+" + str(get(stat.to_lower() + "_add")) + " ")
	stat_points += 1
	stat_points_display.text = str(stat_points)
	for button in get_tree().get_nodes_in_group("PlusButtons"):
		button.set_disabled(false)
		button.modulate = "ffffff"
	
	
func _on_visibility_changed():
	if visible:
		animation_player.play("fade-in")
