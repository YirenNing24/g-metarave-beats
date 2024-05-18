extends Node

const BKMRUtils: Script = preload("res://BeatsKMREngine/utils/BKMRUtils.gd")
const BKMRLogger: Script = preload("res://BeatsKMREngine/utils/BKMRLogger.gd")



var UpgradeCard: HTTPRequest
var wrUpgradeCard: WeakRef = null
signal upgrade_card_complete

# Host URL for API calls
var host: String = BKMREngine.host

# Function to initiate the purchase of a card from the store.
func upgrade_card(upgrade_cards: Dictionary) -> void:
	# Prepare HTTP request
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	UpgradeCard = prepared_http_req.request
	wrUpgradeCard = prepared_http_req.weakref

	var _connect: int = UpgradeCard.request_completed.connect(_onUpgradeCard_request_completed)
	BKMRLogger.info("Calling BKMREngine to buy a card")
	
	var payload: Dictionary = upgrade_cards
	BKMRLogger.debug("Validate buy card payload: " + str(payload))

	var request_url: String = host + "/api/upgrade/card"
	BKMREngine.send_post_request(UpgradeCard, request_url, payload)

# Callback function triggered upon the completion of the buy card request.
func _onUpgradeCard_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Process the result if the response is successful
	if status_check:
		# Parse the JSON response body
		var json_body: Dictionary = JSON.parse_string(body.get_string_from_utf8())
		
		# Build a result dictionary using BKMREngine utility function
		var _bkmr_result: Dictionary = BKMREngine.build_result(json_body)
		
		# Check if the purchase was successful and log accordingly
		if json_body.success:
			BKMRLogger.info("Card Upgrade was successful.")
		else:
			BKMRLogger.error("Card Upgrade failed: " + str(json_body.error))
		
		# Emit the 'buy_card_complete' signal with the response body
		upgrade_card_complete.emit(json_body)
