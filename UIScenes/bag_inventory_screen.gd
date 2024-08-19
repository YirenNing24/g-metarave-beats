extends Control

const pack_inventory_slot_scene: PackedScene = preload("res://Components/Inventory/pack_inventory_slot.tscn")


@onready var loading_panel: Panel = %LoadingPanel
@onready var background_texture: TextureRect = %BackgroundTexture

var pack_data: Dictionary


func _ready() -> void:
	connect_signals()
	BKMREngine.Inventory.open_card_pack_inventory()


func connect_signals() -> void:
	BKMREngine.Inventory.get_card_pack_inventory_complete.connect(_on_get_card_pack_inventory_complete)
	BKMREngine.Gacha.open_card_pack_complete.connect(_on_open_card_pack_complete)
	
	
func _on_get_card_pack_inventory_complete(card_pack_data: Array) -> void:
	if !card_pack_data.is_empty():
		var pack_inventory_slot: Control
		for card_pack: Dictionary in card_pack_data:
			pack_inventory_slot = pack_inventory_slot_scene.instantiate()
			
			pack_inventory_slot.pack_inventory_slot_data(card_pack)
			pack_inventory_slot.on_pack_inventory_button_pressed.connect(_on_pack_inventory_slot_pressed)
			
			%ItemContainer.add_child(pack_inventory_slot)


func _on_pack_inventory_slot_pressed(card_pack_data: Dictionary) -> void:
	pack_data = card_pack_data
	%FilterPanel.visible = true


func _on_yes_button_pressed() -> void:
	BKMREngine.Gacha.open_card_pack(pack_data)
	loading_panel.fake_loader()


func _on_no_button_pressed() -> void:
	%FilterPanel.visible = false
	

func _on_open_card_pack_complete(_message: Variant) -> void:
	%FilterPanel.visible = false
	loading_panel.tween_kill()
	


func _on_close_button_pressed() -> void:
	BKMREngine.Auth.auto_login_player()
	# Update scene transition textures and load the main screen scene.
	LOADER.previous_texture = background_texture.texture
	LOADER.next_texture = preload("res://UITextures/BGTextures/main_city.png")
	var _change_scene: bool = await LOADER.load_scene(self, "res://UIScenes/main_screen.tscn")
