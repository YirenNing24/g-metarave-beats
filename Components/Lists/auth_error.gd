extends HBoxContainer

@onready var animation_player:AnimationPlayer = %AnimationPlayer
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func _on_mouse_entered():
	animation_player.play("mouse_entered")
