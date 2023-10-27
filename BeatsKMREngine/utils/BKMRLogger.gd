extends Node

const BKMRUtils:Script = preload("res://BeatsKMREngine/utils/BKMRUtils.gd")

static func get_log_level() -> int:
	var log_level: int = 2 
	return log_level
	
static func error(text: String) -> void:
	printerr(str(text))
	push_error(str(text))

static func info(text: String) -> void:
	if get_log_level() > 0:
		print(str(text))
	
static func debug(text: String) -> void:
	if get_log_level() > 1:
		print(str(text))
		
static func log_time(log_text: String, log_level: String ='INFO') -> void:
	var timestamp: int = BKMRUtils.get_timestamp()
	if log_level == 'ERROR':
		error(log_text + ": " + str(timestamp))
	elif log_level == 'INFO':
		info(log_text + ": " + str(timestamp))
	else:
		debug(log_text + ": " + str(timestamp))
