extends Node


signal completed

@onready var parser: BKMREnv_Parser = BKMREnv_Parser.new()
var env: Dictionary = {};
var apiKey: String = ""
var apiId: String = ""
var gameVersion: String = ""
var logLevel: String = ""

func _ready() -> void:
	env = parser.parse("res://.env")
	apiKey = "1"
	apiId = "Hello World"
	gameVersion = "0.1"
	logLevel = "2"
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
	
