extends Control

var template_card_slot: PackedScene = preload("res://Components/Store/cards.tscn")

@onready var beats_balance: Label = %BeatsBalance
@onready var native_balance: Label = %Native
@onready var kmr_balance: Label = %KMR
@onready var thump_balance: Label = %ThumpBalance
@onready var background_texture: TextureRect = %BackgroundTexture
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var hero_character: TextureRect = %HeroCharacter
@onready var card_slots: Node
@onready var item_grid: GridContainer = %ItemGrid
@onready var cursor_spark: GPUParticles2D = %CursorSpark


func _ready() -> void:
	pass # Replace with function body.


