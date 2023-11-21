extends Node


signal completed

@onready var parser: BKMREnv_Parser = BKMREnv_Parser.new()
var env: Dictionary = {};
var apiKey:String = ""
var apiId:String = ""
var gameVersion:String = ""
var logLevel:String = ""

func _ready() -> void:
	env = parser.parse("res://.env")
	apiKey = ENV_VAR.env.apiKey
	apiId = ENV_VAR.env.apiId
	gameVersion = ENV_VAR.env.gameVersion
	logLevel = ENV_VAR.env.logLevel
	var _complete_signal: Error = emit_signal("completed")
	
@warning_ignore("shadowed_variable_base_class")
func get_env(name: String) -> String:
	
	# prioritized os environment variable
	if(OS.has_environment(name)):
		var _env: String = OS.get_environment(name)
		return _env
		
	if(env.has(name)):
		return env[name]
	# return empty
	return ""
