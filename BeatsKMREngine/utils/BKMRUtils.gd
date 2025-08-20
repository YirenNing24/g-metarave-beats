extends Node

const BKMRLogger:Script = preload("res://BeatsKMREngine/utils/BKMRLogger.gd")

static func get_timestamp() -> float:
	var unix_time: float = Time.get_unix_time_from_system()
	@warning_ignore("narrowing_conversion")
	var unix_time_int: int = unix_time
	var timestamp: float = round((unix_time - unix_time_int) * 1000.0)
	return timestamp

static func check_http_response(response_code: int, headers: Array, _body: PackedByteArray) -> bool:
	BKMRLogger.debug("response code: " + str(response_code))
	BKMRLogger.debug("response headers: " + str(headers))
	#BKMRLogger.debug("response body: " + str(body.get_string_from_utf8()))
	var check_ok:bool = true
	if response_code == 0:
		no_connection_error()
		check_ok = false
	elif response_code == 403:
		forbidden_error()
		check_ok = false
	elif response_code == 401:
		forbidden_error()
		check_ok = false
	
	elif response_code == 422:
		forbidden_error()
		check_ok = false
		
	elif response_code == 500:
		forbidden_error()
		check_ok = false
	return check_ok


static func no_connection_error() -> void:
	BKMRLogger.error("Beats couldn't connect to the server. There are several reasons why this might happen. See https://www.gmetarave.com/troubleshooting for more details. If the problem persists you can reach out to us: https://www.gmetarave.com/contact")

static func forbidden_error() -> void:
	BKMRLogger.error("You are not authorized to call the BKMREngine - check your device, game version or account or contact us at https://www.gmetarave.com/contact")

static func validation_error() -> void:
	BKMRLogger.error("Your credentials entered or used are invalid")

static func obfuscate_string(string: String) -> String:
	return string.replace(".", "*")
