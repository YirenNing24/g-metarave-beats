extends Control

signal on_pack_inventory_button_pressed

var is_pressed: bool = false


func _ready() -> void:
	connect_signals()


func connect_signals() -> void:
	BKMREngine.Gacha.open_card_pack_complete.connect(_on_open_card_pack_complete)


func pack_inventory_slot_data(pack_data: Dictionary) -> void:
	%Button.pressed.connect(_on_button_pressed.bind(pack_data))
	populate_quantity(pack_data)


func _on_button_pressed(pack_data: Dictionary) -> void:
	on_pack_inventory_button_pressed.emit(pack_data)
	is_pressed = true


func populate_quantity(pack_data: Dictionary) -> void:
	var data_pack: Dictionary = pack_data.values()[0]
	%Quantity.text = str(data_pack.quantity)


func _on_open_card_pack_complete(message: Variant) -> void:
	if message is Array and is_pressed:
		var new_quantity: int = %Quantity.text.to_int() - 1
		if new_quantity == 0:
			queue_free()
			return
			
		%Quantity.text = str(new_quantity)
		is_pressed = false
