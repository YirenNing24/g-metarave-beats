extends Control

var trivia_label_scene: PackedScene = preload("res://Components/MyProfile/trivia_label.tscn")

@onready var trivia_container: VBoxContainer = %TriviaContainer

@onready var card_name: Label = %CardName
@onready var birth_name: Label = %BirthName
@onready var member_position: Label = %Position
@onready var birthday: Label = %Birthday
@onready var height: Label = %Height
@onready var zodiac: Label = %Zodiac
@onready var blood_type: Label = %BloodType
@onready var nationality: Label = %Nationality


func card_data(data: Dictionary) -> void:
	display_artist_data(data)

func _on_close_button_pressed() -> void:
	visible = false
	for trivia: Label in trivia_container.get_children():
		trivia.queue_free()

func display_artist_data(data: Dictionary) -> void:
	visible = true
	var card_artist_data: Dictionary = data.card
	var card_artist_trivia: Dictionary = data.card.trivia
	display_artist_trivia(card_artist_trivia)
	
	card_name.text =  card_artist_data.artist + " - " +  card_artist_data.group
	birth_name.text = card_artist_data.birthName
	birthday.text = card_artist_data.birthday
	height.text = card_artist_data.height
	zodiac.text = card_artist_data.zodiac
	blood_type.text = card_artist_data.bloodType
	nationality.text = card_artist_data.nationality
	
func display_artist_trivia(trivias: Dictionary) -> void:
	var trivia_label: Label 
	for trivia: String in trivias.keys():
		trivia_label = trivia_label_scene.instantiate()
		trivia_label.text = "- " + trivias[trivia]
	
		trivia_container.add_child(trivia_label)
