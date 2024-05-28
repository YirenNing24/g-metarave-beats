extends Control

var genres: Dictionary = {}
var horoscope: Dictionary = {}
var animals: Dictionary = {}


func _ready() -> void:
	BKMREngine.Profile.get_soul()
	connect_signal()
	
func connect_signal() -> void:
	BKMREngine.Profile.preference_get_complete.connect(_on_preference_get_complete)
	for genre: CheckBox in get_tree().get_nodes_in_group("Animals"):
		var _genre: int = genre.toggled.connect(animals_selection)
	for genre: CheckBox in get_tree().get_nodes_in_group("Horoscope"):
		var _genre: int = genre.toggled.connect(horoscope_selection)
	for genre: CheckBox in get_tree().get_nodes_in_group("Genres"):
		var _genre: int = genre.toggled.connect(genres_selection)
		
func genres_selection(_toggled: bool = false) -> void:
	var button_pressed_count: int = 0
	for genre: CheckBox in get_tree().get_nodes_in_group("Genres"):
		if button_pressed_count == 3:
			genre.disabled = true
		if genre.button_pressed:
			button_pressed_count += 1
			genres["genre" + str(button_pressed_count)] = genre.text
	if button_pressed_count < 2:
		for genre: CheckBox in get_tree().get_nodes_in_group("Genres"):
			genre.disabled = false
			
func animals_selection(_toggled: bool = false) -> void:
	var button_pressed_count: int = 0
	for animal: CheckBox in get_tree().get_nodes_in_group("Animals"):
		if animal.button_pressed:
			button_pressed_count += 1
			animals["animal" + str(button_pressed_count)] = animal.text
		if button_pressed_count == 3:
			animal.disabled = true
	if button_pressed_count < 2:
		for animal: CheckBox in get_tree().get_nodes_in_group("Animals"):
			animal.disabled = false
			
func horoscope_selection(_toggled: bool = false) -> void:
	var button_pressed_count: int = 0
	for genre: CheckBox in get_tree().get_nodes_in_group("Horoscope"):
		if genre.button_pressed:
			button_pressed_count += 1
			horoscope["horoscope"] = genre.text
	
	for genre: CheckBox in get_tree().get_nodes_in_group("Horoscope"):
		genre.disabled = button_pressed_count == 1 and not genre.button_pressed

func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		visible = false

func _on_save_button_pressed() -> void:
	var preferences: Dictionary = {}
	if genres and animals and horoscope != {}:
		preferences.merge(genres)
		preferences.merge(animals)
		preferences.merge(horoscope)
		BKMREngine.Profile.save_preference(preferences)
	else:
		return

func _on_preference_get_complete(preference_data: Dictionary) -> void:
	for preference_key: String in preference_data.keys():
		if preference_key != "ownership" and preference_key != "horoscopeMatch" and preference_key != "animalMatch":
			var preference_value: String = preference_data[preference_key]
			for check_box: CheckBox in get_tree().get_nodes_in_group("Preferences"):
				if check_box.text == preference_value:
					check_box.button_pressed = true
			animals_selection()
			horoscope_selection()
			genres_selection()

