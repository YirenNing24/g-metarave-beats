extends Node

const BKMRUtils: Script = preload("res://BeatsKMREngine/utils/BKMRUtils.gd")
const BKMRLogger: Script = preload("res://BeatsKMREngine/utils/BKMRLogger.gd")

# HTTPRequests for API calls
var GetCards: HTTPRequest
var wrGetCards: WeakRef = null
signal get_cards_complete

var BuyCard: HTTPRequest
var wrBuyCard: WeakRef = null
signal buy_card_complete

# Host URL for API calls
var host: String = BKMREngine.host

# Weak references



# Function to get store items based on item type.
func get_valid_cards() -> Node:
	# Prepare HTTP request
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	GetCards = prepared_http_req.request
	wrGetCards = prepared_http_req.weakref
	
	# Connect the request_completed signal to the callback function
	var _get_cards: int = GetCards.request_completed.connect(_onGetValidCards_request_completed)
	
	# Log information about the API call
	BKMRLogger.info("Calling BKMREngine to get cards on sale data")
	
	# Construct the request URL
	var request_url: String = host + "/api/store/cards/get"
	
	# Send the HTTP GET request asynchronously
	await BKMREngine.send_get_request(GetCards, request_url)
	
	# Return the current Node
	return self

# Callback function triggered when the get cards request is completed.
func _onGetValidCards_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check if the HTTP response is successful
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Free the request resources if the HTTP request instance is valid
	if is_instance_valid(GetCards):
		BKMREngine.free_request(wrGetCards, GetCards)
	
	# Process the response if the HTTP response is successful
	if status_check:
		# Parse the JSON response body and store the retrieved cards for sale
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body.is_empty():
			get_cards_complete.emit(json_body)
		elif json_body.has("error"):
			get_cards_complete.emit(json_body)
		else:
			get_cards_complete.emit(json_body)
		# Emit the signal indicating that the get cards request is complete
	else:
		get_cards_complete.emit({"error": "Unknown server error"})
		

# Function to initiate the purchase of a card from the store.
func buy_card(token_id: String, card_name: String, username: String) -> Node:
	# Prepare HTTP request
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	BuyCard = prepared_http_req.request
	wrBuyCard = prepared_http_req.weakref

	# Connect the callback function to the request completion signal
	var _connect: int = BuyCard.request_completed.connect(_onBuyCard_request_completed)
	
	# Log the initiation of the card purchase
	BKMRLogger.info("Calling BKMREngine to buy a card")
	
	# Prepare payload for the purchase request
	var payload: Dictionary = {"tokenId": token_id, "cardName": card_name, "username": username}
	BKMRLogger.debug("Validate buy card payload: " + str(payload))
	
	# Define the request URL for purchasing a card
	var request_url: String = host + "/api/store/cards/buy"
	
	# Send the POST request to initiate the card purchase
	BKMREngine.send_post_request(BuyCard, request_url, payload)
	
	# Return the current node
	return self


# Callback function triggered upon the completion of the buy card request.
# Parameters:
#   - _result: The result of the HTTP request.
#   - response_code: The HTTP response code received.
#   - headers: An array containing the HTTP response headers.
#   - body: PackedByteArray containing the response body.
# Returns:
#   - void
func _onBuyCard_request_completed(_result: Dictionary, response_code: int, headers: Array, body: PackedByteArray) -> void:
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
			BKMRLogger.info("Purchase was successful.")
		else:
			BKMRLogger.error("Purchase failed: " + str(json_body.error))
		
		# Emit the 'buy_card_complete' signal with the response body
		buy_card_complete.emit(json_body)
