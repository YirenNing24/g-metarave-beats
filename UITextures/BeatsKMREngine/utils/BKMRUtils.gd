extends Node

const BKMRLogger = preload("res://utils/BKMRLogger.gd")

static func get_timestamp() -> int:
	
	var unix_time: float = Time.get_unix_time_from_system()
	@warning_ignore("narrowing_conversion")
	var unix_time_int: int = unix_time
	var timestamp = round((unix_time - unix_time_int) * 1000.0)
	return timestamp


static func check_http_response(response_code, headers, body):
	
	BKMRLogger.debug("response code: " + str(response_code))
	BKMRLogger.debug("response headers: " + str(headers))
	BKMRLogger.debug("response body: " + str(body.get_string_from_utf8()))

	var check_ok = true
	if response_code == 0:
		no_connection_error()
		check_ok = false
	elif response_code == 403:
		forbidden_error()
	elif response_code == 401:
		forbidden_error()

	return check_ok


static func no_connection_error():
	BKMRLogger.error("Beats couldn't connect to the server. There are several reasons why this might happen. See https://www.kmetarave.com/troubleshooting for more details. If the problem persists you can reach out to us: https://silentwolf.com/contact")


static func forbidden_error():
	BKMRLogger.error("You are not authorized to call the BKMREngine - check your device, game version or account or contact us at https://www.kmetarave.com/contact")


static func obfuscate_string(string: String) -> String:
	return string.replace(".", "*")
