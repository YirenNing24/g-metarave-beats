extends Control

var group_collection_scene: PackedScene = preload("res://Components/MyProfile/group_collection.tscn")

@onready var cursor_spark: GPUParticles2D = %CursorSpark
@onready var background_texture: TextureRect = %BackgroundTexture
@onready var group_grid: GridContainer = %GridContainer

@onready var card_collection_modal: Control = %CardCollectionModal

var card_collection: Array

func _ready() -> void:
	connect_signal() 
	BKMREngine.Profile.get_card_count()
	BKMREngine.Profile.get_card_collection()
	
func connect_signal() -> void:
	BKMREngine.Profile.card_count_get_complete.connect(_on_get_card_count_complete)
	BKMREngine.Profile.card_collection_get_complete.connect(_on_get_card_collection_complete)
	
func _on_close_button_pressed() -> void:
	BKMREngine.Auth.auto_login_player()
	LOADER.previous_texture = background_texture.texture
	LOADER.next_texture = preload("res://UITextures/BGTextures/main.png")
	var _change_scene: bool = await LOADER.load_scene(self, "res://UIScenes/main_screen.tscn")

func _on_get_card_count_complete(card_count_data: Dictionary) -> void:
	for card_count: String in card_count_data.keys():
		var group_collection: Control = group_collection_scene.instantiate()
		var card_count_value: int = card_count_data[card_count]
		group_collection.get_node("Panel/OwnedCardCount").text = str(card_count_value) + " / " + str(card_count_value)
		
		var logo_filename: String = card_count.to_lower().replace(":", "_").replace(" ", "_") + "_logo.png"
		var logo_path: String = "res://UITextures/GroupLogo/" + logo_filename
		
		var texture: Texture = load(logo_path)
		group_collection.get_node("Panel/TextureRect").texture = texture
		
		group_collection.on_open_collection_button_pressed.connect(_on_open_collection_button_pressed)
		group_collection.group = card_count
		group_grid.add_child(group_collection)
		
func _on_open_collection_button_pressed(group: String) -> void:
	card_collection_modal.load_cards(group, card_collection)
		
func _input(event: InputEvent) -> void:
	# Handle screen touch events.
	if event is InputEventScreenTouch:
		if event.pressed:
			# Check if the touch event is within the bounds of the notepicker node.
			var position_event: Vector2 = event.position
			cursor_spark.position = position_event
			cursor_spark.emitting = true
			play_pointer_sfx()
	elif event is InputEventScreenDrag:
		var position_event: Vector2 = event.position
		cursor_spark.position = position_event
		cursor_spark.emitting = true

func play_pointer_sfx() -> void:
	$AudioStreamPlayer.play()
	await $AudioStreamPlayer.finished

func _on_get_card_collection_complete(card_collection_data: Array) -> void:
	card_collection = card_collection_data
