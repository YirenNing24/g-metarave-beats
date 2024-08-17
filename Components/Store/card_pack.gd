extends Control

signal buy_button_pressed(data: Dictionary, type: String)

var item_data: Dictionary

func _ready() -> void:
	%BuyButton.pressed.connect(_on_buy_button_pressed)


func card_pack_data(data: Dictionary) -> void:
	item_data = data


func _on_buy_button_pressed() -> void:
	buy_button_pressed.emit(item_data, "CardPack")
