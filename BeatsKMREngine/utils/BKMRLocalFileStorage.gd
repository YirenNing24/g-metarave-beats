extends Node

const BKMRELogger: Script = preload("res://BeatsKMREngine/utils/BKMRLogger.gd") 

# Retrieves data stored as JSON in local storage
# example path: "user://swsession.save"

# store lookup (not logged in player name) and validator in local file
static func save_data(path: String, data: Dictionary, debug_message: String='Saving data to file in local storage: ') -> bool:
	var save_success:bool = false
	var file:FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(str(data))
	save_success = true
	@warning_ignore("unsafe_method_access")
	BKMRELogger.debug(debug_message + str(data))
	return save_success


static func remove_data(path: String, debug_message: String='Removing data from file in local storage: ') -> bool:
	var delete_success: bool = false
	if FileAccess.file_exists(path):
		var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
		var data: Dictionary = {"deleted": "delete"}
		file.store_var(data)
		delete_success = true
	BKMRELogger.debug(debug_message)
	return delete_success


static func does_file_exist(path: String) -> bool:
	return FileAccess.file_exists(path)


static func get_data(path: String) -> Dictionary:
	var content: Dictionary = {}
	if FileAccess.file_exists(path):
		var file: FileAccess = FileAccess.open(path, FileAccess.READ)
		var text_content: String = file.get_as_text()
		var data: Variant = JSON.parse_string(text_content)
		if typeof(data) == TYPE_DICTIONARY:
			content = data
		else:
			BKMRELogger.debug("Invalid data in local storage")
	else:
		BKMRELogger.debug("Could not find any data at: " + str(path))
	return content
