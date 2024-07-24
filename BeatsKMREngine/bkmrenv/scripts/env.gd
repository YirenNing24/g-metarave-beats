extends Node


signal completed

@onready var parser: BKMREnv_Parser = BKMREnv_Parser.new()
var env: Dictionary = {};


func _ready() -> void:
	env = parser.parse("res://.env")
	var _complete_signal: Error = emit_signal("completed")
	

func get_env(names: String) -> String:
	
	# prioritized os environment variable
	if(OS.has_environment(names)):
		var _env: String = OS.get_environment(names)
		completed.emit()
		return _env
		
	if(env.has(names)):
		return env[names]
	# return empty
	return ""
	
