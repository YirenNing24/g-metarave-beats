class_name BKMREnv_Parser


func _init() -> void:
	pass
	
func parse(filename: String) -> Dictionary:
	var file: FileAccess = FileAccess.open("res://.env", FileAccess.READ)
	if(!FileAccess.file_exists(filename)):
		return {};
	
	var env: Dictionary = {};
	var line: String = "";

	while !file.eof_reached():
		line = file.get_line();
		var o: PackedStringArray = line.split("=");
		env[o[0]] = o[1].lstrip("\"").rstrip("\"");
	return env;
