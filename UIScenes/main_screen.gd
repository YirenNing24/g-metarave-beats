extends Control

signal session_check_done
signal chat_opened

var profile_modal: Control = preload("res://Components/Popups/profile_modal.tscn").instantiate()
var player_modal: Control = preload("res://Components/Popups/player_modal.tscn").instantiate()
var stat_modal: Control = preload("res://Components/Popups/stat_modal.tscn").instantiate()

@onready var chat_box: Control = %chat_box
@onready var hero: TextureRect = %Hero
@onready var player_name: Label = %PlayerName
@onready var player_rank: Label = %PlayerRank
@onready var filter_panel: Panel = %FilterPanel
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var beats_balance: Label = %BeatsBalance
@onready var native_balance: Label = %Native
@onready var kmr_balance: Label = %KMR
@onready var thump_balance: Label = %ThumpBalance
@onready var stats_wheel: TextureProgressBar = %StatsWheel
@onready var level: Label = %Level
@onready var menu_buttons_cont: VBoxContainer = %VBoxContainer
@onready var background_texture: TextureRect = %BackgroundTexture
@onready var store_button: TextureButton = %StoreButton

var stat_tween: Tween
var chat_connected: bool = false
var is_opened: bool = false
var url_all: String = "ws://192.168.4.117:8081/api/chats/all"
var url_player: String


func _ready() -> void:
	filter_panel.add_child(profile_modal)
	filter_panel.add_child(player_modal)
	filter_panel.add_child(stat_modal)
	hud_data()
	await animation_player.animation_finished
	chat_box.show()
	BKMREngine.Chat.connected.connect(_on_chat_connected)
	BKMREngine.Chat.closed.connect(_on_chat_closed)
	
func session_check() -> void:
	BKMREngine.Auth.auto_login_player()
	await BKMREngine.Auth.bkmr_session_check_complete
	
func hud_data() -> void:
	player_name.text = BKMREngine.Auth.logged_in_player
	url_player = "ws://192.168.4.117:8081/api/chats" + BKMREngine.Auth.logged_in_player
	player_rank.text = PLAYER.player_rank	
	beats_balance.text = PLAYER.beats_balance
	native_balance.text = PLAYER.native_balance
	kmr_balance.text = PLAYER.kmr_balance
	thump_balance.text = PLAYER.thump_balance
	level.text = str(PLAYER.level)
	if PLAYER.stat_points > 0:
		stats_wheel.value = 0
		stat_tween = get_tree().create_tween()
		var _tween_property: PropertyTweener = stat_tween.tween_property(
			stats_wheel, 
			"value", 
			100, 
			1.5).set_trans(Tween.TRANS_LINEAR)
		var _tween_callback: CallbackTweener = stat_tween.tween_callback(hud_data)
	
func _on_profile_button_pressed() -> void:
	profile_modal.visible = true
	filter_panel.visible = true
	
func _on_filter_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if profile_modal.visible:
			filter_panel.visible = false
			profile_modal.visible = false
			player_modal.visible = false
		elif stat_modal.visible:
			filter_panel.visible = false
			stat_modal.visible = false
			player_modal.visible = false
		elif player_modal.visible:
			filter_panel.visible = false
			profile_modal.visible = false
			stat_modal.visible = false
	
func _on_store_button_pressed() -> void:
	if stat_tween: 
		stat_tween.kill()
	LOADER.previous_texture = background_texture.texture
	LOADER.next_texture = preload("res://UITextures/BGTextures/store_bg.png")
	var _change_scene: bool = await LOADER.load_scene(self, "res://UIScenes/store_screen.tscn")
	for buttons: Button in get_tree().get_nodes_in_group('MainButtons'):
		buttons.disabled = true
	
func _on_inventory_button_pressed() -> void:
	if stat_tween: 
		stat_tween.kill()
	BKMREngine.Chat.socket.close(1000, "changed_scene")
	LOADER.previous_texture = background_texture.texture
	LOADER.next_texture = preload("res://UITextures/BGTextures/main_inventory_bg.png")
	var _change_scene: bool = await LOADER.load_scene(self, "res://UIScenes/main_inventory.tscn")
	for buttons: Button in get_tree().get_nodes_in_group('MainButtons'):
		buttons.disabled = true
	
func _on_chat_box_slide_pressed(_isOpen: bool) -> void:
	if !is_opened:
		animation_player.play("chat_slide")
		await animation_player.animation_finished
		chat_opened.emit(true)
		is_opened = true
		if chat_connected:
			return
		BKMREngine.Chat.connect_socket(url_all)
	else:
		animation_player.play_backwards("chat_slide")
		await animation_player.animation_finished
		is_opened = false
		chat_opened.emit(false)
	
func _on_chat_connected(_url: String) -> void:
	chat_connected = true
	
func _on_chat_closed(_code: int, _reason: String) -> void:
	chat_connected = false
	if is_opened:
		BKMREngine.Chat.connect_socket(url_all)
		
func _on_game_mode_button_pressed() -> void:
	for buttons: TextureButton in get_tree().get_nodes_in_group('MainButtons'):
		buttons.disabled = true
	for buttons2: Button in get_tree().get_nodes_in_group('MainButtons2'):
		buttons2.disabled = true
		
	LOADER.previous_texture = background_texture.texture
	LOADER.next_texture = preload("res://UITextures/BGTextures/song_menu_bg.png")
	var _change_scene: bool = await LOADER.load_scene(self, "res://UIScenes/song_menu.tscn")
	
func _on_chat_box_message_sent(data: Dictionary) -> void:
	BKMREngine.Chat.connect_socket(url_all)
	
	var message: String = JSON.stringify(data)
	BKMREngine.Chat.socket.send_text(message)
	
func _on_stat_button_pressed() -> void:
	filter_panel.show()
	stat_modal.show()

func _on_chat_box_view_profile_pressed(_player_profile: Dictionary) -> void:
	player_modal.visible = true
	filter_panel.visible = true
