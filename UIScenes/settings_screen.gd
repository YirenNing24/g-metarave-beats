extends Node

const BKMRLocalFileStorage: Script = preload("res://BeatsKMREngine/utils/BKMRLocalFileStorage.gd")

var selected_fps_checkbox: CheckBox = null
var selected_reso_checkbox: CheckBox = null
var selected_gfx_checkbox: CheckBox = null

# FPS Mapping
var fps_values: Dictionary = {
	"Standard": 60,
	"High": 90,
	"Max": 120
}
var selected_fps: int = 60  # Default FPS

# Resolution Mapping
var resolution_values: Dictionary = {
	"Low": Vector2(800, 360),
	"Standard": Vector2(1200, 540),
	"High": Vector2(1600, 720),
	"Ultra": Vector2(2400, 1080)
}
var selected_resolution: Vector2 = Vector2(800, 360)  # Default Resolution

# GFX Mapping
var gfx_settings: Dictionary = {
	"1": 1, "2": 2, "3": 3, "4": 4, "5": 5
}
var selected_gfx_level: int = 3  # Default GFX Quality

const SETTINGS_PATH: String = "user://settings.json"

func _ready() -> void:
	load_settings()
	connect_signals()


func save_settings() -> void:
	var settings: Dictionary = {
		"fps": selected_fps,
		"resolution": { "x": selected_resolution.x, "y": selected_resolution.y },
		"gfx_level": selected_gfx_level
	}
	BKMRLocalFileStorage.save_data(SETTINGS_PATH, settings, "Saving settings")
	
	
func load_settings() -> void:
	if BKMRLocalFileStorage.does_file_exist(SETTINGS_PATH):
		var settings: Dictionary = BKMRLocalFileStorage.get_data(SETTINGS_PATH)
		if settings:
			selected_fps = settings.get("fps", 60)
			var res: Dictionary = settings.get("resolution", { "x": 800, "y": 360 })
			var x: float = res.x
			var y: float = res.y
			selected_resolution = Vector2(x, y)
			selected_gfx_level = settings.get("gfx_level", 1)
			print("Loaded settings:", settings)
	else:
		print("No settings file found, using defaults.")
	
	
func connect_signals() -> void:
	for fps_checkbox: CheckBox in get_tree().get_nodes_in_group("FPSConfig"):
		var _i: int = fps_checkbox.pressed.connect(func() -> void: _on_fps_checkbox_pressed(fps_checkbox))
		if fps_checkbox.name in fps_values and fps_values[fps_checkbox.name] == selected_fps:
			fps_checkbox.button_pressed = true
			selected_fps_checkbox = fps_checkbox
	
	for reso_checkbox: CheckBox in get_tree().get_nodes_in_group("Resolution"):
		var _i: int = reso_checkbox.pressed.connect(func() -> void: _on_resolution_checkbox_pressed(reso_checkbox))
		if reso_checkbox.name in resolution_values and resolution_values[reso_checkbox.name] == selected_resolution:
			reso_checkbox.button_pressed = true
			selected_reso_checkbox = reso_checkbox
	
	for gfx_checkbox: CheckBox in get_tree().get_nodes_in_group("GFXQuality"):
		var _i: int = gfx_checkbox.pressed.connect(func() -> void: _on_gfx_quality_checkbox_pressed(gfx_checkbox))
		if gfx_checkbox.name == str(selected_gfx_level):
			gfx_checkbox.button_pressed = true
			selected_gfx_checkbox = gfx_checkbox
	 
func _on_fps_checkbox_pressed(pressed_checkbox: CheckBox) -> void:
	if selected_fps_checkbox == pressed_checkbox:
		pressed_checkbox.button_pressed = true
		return
	
	if selected_fps_checkbox:
		selected_fps_checkbox.button_pressed = false
	
	selected_fps_checkbox = pressed_checkbox
	selected_fps = fps_values.get(pressed_checkbox.name, 60)
	save_settings()
	print("Selected FPS:", selected_fps)
	
	
func _on_resolution_checkbox_pressed(pressed_checkbox: CheckBox) -> void:
	if selected_reso_checkbox == pressed_checkbox:
		pressed_checkbox.button_pressed = true
		return
	
	if selected_reso_checkbox:
		selected_reso_checkbox.button_pressed = false
	
	selected_reso_checkbox = pressed_checkbox
	selected_resolution = resolution_values.get(pressed_checkbox.name, Vector2(1200, 540))
	save_settings()
	print("Selected Resolution:", selected_resolution)

func _on_gfx_quality_checkbox_pressed(pressed_checkbox: CheckBox) -> void:
	if selected_gfx_checkbox == pressed_checkbox:
		pressed_checkbox.button_pressed = true
		return
	
	if selected_gfx_checkbox:
		selected_gfx_checkbox.button_pressed = false
	
	selected_gfx_checkbox = pressed_checkbox
	selected_gfx_level = int(str(pressed_checkbox.name))
	save_settings()
	print("Selected GFX Quality:", selected_gfx_level)


func _on_close_button_pressed() -> void:
	# Attempt automatic login and wait for the session check to complete.
	BKMREngine.Auth.auto_login_player()
	#BKMREngine.Inventory.update_inventory()

	# Set the previous and next textures for scene transition.
	LOADER.previous_texture = %BackgroundTexture.texture
	LOADER.next_texture = preload("res://UITextures/BGTextures/main_city.png")
	
	# Initiate the scene transition.
	var _change_scene: bool = await LOADER.load_scene(self, "res://UIScenes/main_screen.tscn")
