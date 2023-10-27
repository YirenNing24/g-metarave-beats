extends Control

@onready var player_name: Label =  %PlayerName
@onready var level: Label = %Level
@onready var player_rank: Label = %PlayerRank
@onready var wallet_address: Label = %WalletAddress
@onready var animation_player: AnimationPlayer = %AnimationPlayer

func _ready() -> void:
	stat_display()
	
func stat_display() -> void:
	player_name.text = BKMREngine.Auth.logged_in_player
	level.text = str(PLAYER.level)
	player_rank.text = PLAYER.player_rank
	wallet_address.text = PLAYER.wallet_address
	BKMREngine.Auth.bkmr_logout_complete.connect(_on_Logout_Complete)
	
func _on_visibility_changed() -> void:
	if visible:
		animation_player.play("fade-in")
	
func _on_logout_button_pressed() -> void:
	BKMREngine.Auth.logout_player()
	get_tree().quit()
	await BKMREngine.Auth.bkmr_logout_complete
	
func _on_Logout_Complete() -> void:
	LOADER.previous_texture = load("res://UITextures/BGTextures/main.png")
	LOADER.next_texture = load("res://UITextures/BGTextures/auth.png")
	var _auth_screen: int = await LOADER.load_scene(self, "res://UIScenes/auth_screen.tscn")
