extends Control

signal on_pack_inventory_button_pressed


# Called when the node enters the scene tree for the first time.
#func _ready() -> void:


func pack_inventory_slot_data(pack_data: Dictionary) -> void:
	%Button.pressed.connect(_on_button_pressed.bind(pack_data))


func _on_button_pressed(pack_data: Dictionary) -> void:
	on_pack_inventory_button_pressed.emit(pack_data)
