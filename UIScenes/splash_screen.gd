extends Control

const BKMRLocalFileStorage: Script = preload("res://BeatsKMREngine/utils/BKMRLocalFileStorage.gd")

# UI References
@onready var loading_wheel: TextureProgressBar = %LoadingWheel
@onready var loading_label: Label = %LoadingLabel
@onready var transition_texture: TextureRect = %TextureRect
@onready var loading_label_2: Label = %LoadingLabel2

# Tween for animations
var tween: Tween
var google_sign_in_retries: int = 5

# Default settings (Lowest Graphics)
var selected_fps: int = 60
var selected_resolution: Vector2 = Vector2(1200, 540)
var selected_gfx_level: int = 1
var selected_aa_level: int = 0  # Default: No AA

var player_session: Dictionary
# FPS Mapping
var fps_values: Dictionary = {
	"Standard": 60,
	"High": 90,
	"Max": 120
}

# Resolution Mapping
var resolution_values: Dictionary = {
	"Low": Vector2(800, 360),
	"Standard": Vector2(1200, 540),
	"High": Vector2(1600, 720),
	"Ultra": Vector2(2400, 1080)
}

# GFX Mapping
var gfx_settings: Dictionary = {
	"1": 1, "2": 2, "3": 3, "4": 4, "5": 5
}

# Anti-Aliasing Mapping
var aa_settings: Dictionary = {
	"Off": 0,   # No AA
	"FXAA": 1,  # Fast Approximate Anti-Aliasing
	"MSAA2X": 2, # Multi-Sample Anti-Aliasing 2X
	"MSAA4X": 4, # Multi-Sample Anti-Aliasing 4X
	"MSAA8X": 8  # Multi-Sample Anti-Aliasing 8X
}

func _ready() -> void:
	# Load settings before starting animations
	
	load_graphics_settings()
	apply_graphics_settings()
	# Start loading animation
	fake_loader()

	# Connect session check signal
	BKMREngine.Auth.bkmr_session_check_complete.connect(_on_session_check)
	BKMREngine.Server.server_checking_complete.connect(on_server_check_complete)
	loading_label_2.text = BKMREngine.Auth.last_login_type

	# Timer for auto-login
	var _timer: int = get_tree().create_timer(10.0).timeout.connect(_on_timer_timeout)
	
	
func on_server_check_complete() -> void:
	print("dead man walking")
	
# Load settings from file or use defaults
func load_graphics_settings() -> void:
	const settings_path: String = "user://settings.json"
	if BKMRLocalFileStorage.does_file_exist(settings_path):
		var settings: Dictionary = BKMRLocalFileStorage.get_data(settings_path)
		selected_fps = settings.get("fps", 60)
		var res: Variant = settings.get("resolution", { "x": 800, "y": 360 })
		var x: float = res.x
		var y: float = res.y
		selected_resolution = Vector2(x, y)
		selected_gfx_level = settings.get("gfx_level", 1)
		selected_aa_level = settings.get("aa_level", 0)  # Load AA setting
		print("Loaded graphics settings:", settings)
		print_debug("Loaded FPS:", selected_fps)
		print_debug("Loaded Resolution:", selected_resolution)
		print_debug("Loaded GFX Level:", selected_gfx_level)
		print_debug("Loaded AA Level:", selected_aa_level)
	else:
		print("No settings file found. Using lowest settings.")
	
	
# Apply graphics settings
func apply_graphics_settings() -> void:
	DisplayServer.window_set_size(selected_resolution)
	Engine.max_fps = selected_fps

	# Apply Anti-Aliasing
	var viewport: Viewport = get_viewport()
	viewport.msaa_2d = selected_aa_level as Viewport.MSAA
	RenderingServer.viewport_set_msaa_3d(viewport.get_viewport_rid(), selected_aa_level)  # Apply MSAA in 3D if needed

	# Apply FXAA (Screen Space AA)
	if selected_aa_level == 1:  # If "FXAA" is selected
		viewport.screen_space_aa = Viewport.ScreenSpaceAA.SCREEN_SPACE_AA_FXAA
		print("FXAA enabled")
	else:
		viewport.screen_space_aa = Viewport.ScreenSpaceAA.SCREEN_SPACE_AA_DISABLED
		print("FXAA disabled")
		
	viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	var base_resolution: Vector2 = Vector2(1200, 540)
	
	viewport.scaling_3d_scale = min(selected_resolution.x / base_resolution.x, selected_resolution.y / base_resolution.y)
	# Apply FSR (FidelityFX Super Resolution for upscaling)

	# Debugging
	print("Applied Settings: FPS =", selected_fps, "Resolution =", selected_resolution, 
		"GFX Level =", selected_gfx_level, "AA Level =", selected_aa_level)
		
		
# Auto-login timer callback
func _on_timer_timeout() -> void:
	BKMREngine.Auth.auto_login_player()
	
	
# Handle session check response
func _on_session_check(session: Dictionary) -> void:
	player_session = session
	if session.is_empty():
		BKMREngine.session = false
		loading_label.text = "No logged-in account found!"
		change_to_auth_scene()
	else:
		if session.has("success"):
			BKMREngine.session = true
			change_to_auth_scene()
		elif session.has("error"):
			BKMREngine.session = false
			if session.error == "jwt expired":
				loading_label.text = "Session expired!"
			else:
				loading_label.text = str(session.error)
			change_to_auth_scene()

	loading_wheel.visible = false
	tween.kill()


# Change to authentication scene
func change_to_auth_scene() -> void:
	tween.kill()
	var _load_scene: bool = await LOADER.load_scene(self, "res://UIScenes/auth_screen.tscn")
	LOADER.previous_texture = transition_texture.texture
	LOADER.next_texture = preload("res://UITextures/BGTextures/blue_gradient.png")


# Loading animation
func fake_loader() -> void:
	loading_wheel.value = 0
	tween = get_tree().create_tween()
	var _i: PropertyTweener = tween.tween_property(loading_wheel, "value", 100, 3.0).set_trans(Tween.TRANS_LINEAR)
	var _a: CallbackTweener = tween.tween_callback(fake_loader)
