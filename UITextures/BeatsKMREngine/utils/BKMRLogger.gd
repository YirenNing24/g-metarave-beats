extends Node

const BKMRUtils = preload("res://utils/BKMRUtils.gd")

static func get_log_level():
	var log_level = 2 
	return log_level
	
static func error(text):
	printerr(str(text))
	push_error(str(text))

static func info(text):
	if get_log_level() > 0:
		print(str(text))
	
static func debug(text):
	if get_log_level() > 1:
		print(str(text))
		
static func log_time(log_text, log_level='INFO'):
	var timestamp = BKMRUtils.get_timestamp()
	if log_level == 'ERROR':
		error(log_text + ": " + str(timestamp))
	elif log_level == 'INFO':
		info(log_text + ": " + str(timestamp))
	else:
		debug(log_text + ": " + str(timestamp))
