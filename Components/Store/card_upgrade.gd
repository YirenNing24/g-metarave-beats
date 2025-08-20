extends Control

signal buy_button_pressed(data: Dictionary, type: String)

var item_data: Dictionary

func _ready() -> void:
	%BuyButton.pressed.connect(_on_buy_button_pressed)
	%BuyButton2.pressed.connect(_on_buy_button_pressed)
	
	
func card_upgrade_data(data: Dictionary) -> void:
	print(data)
	item_data = data

func _on_buy_button_pressed() -> void:
	print(item_data)
	buy_button_pressed.emit(item_data, "CardUpgrade")
