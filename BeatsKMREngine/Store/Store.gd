extends Node

const BKMRUtils: Script = preload("res://BeatsKMREngine/utils/BKMRUtils.gd")
const BKMRLogger: Script = preload("res://BeatsKMREngine/utils/BKMRLogger.gd")

# Signals
signal get_cards_complete
signal buy_card_complete

# HTTPRequests for API calls
var GetCards: HTTPRequest
var BuyCard: HTTPRequest

# Host URL for API calls
var host: String = BKMREngine.host

# Weak references
var wrGetCards: WeakRef = null
var wrBuyCard: WeakRef = null

# Item Arrays
var cards_for_sale: Array = []

# Function to get store items based on item type.
# This function sends an HTTP GET request to the BKMREngine API to retrieve store items of the specified type.
# Parameters:
#   - item_type: The type of store items to retrieve.
# Returns:
#   - Node: The current Node.
func get_store_items(item_type: String) -> Node:
	# Prepare HTTP request
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	GetCards = prepared_http_req.request
	wrGetCards = prepared_http_req.weakref
	
	# Connect the request_completed signal to the callback function
	var _get_cards: int = GetCards.request_completed.connect(_onGetCards_request_completed)
	
	# Log information about the API call
	BKMRLogger.info("Calling BKMREngine to get cards on sale data")
	
	# Construct the request URL
	var request_url: String = host + "/api/store/cards/get?itemType=" + item_type
	
	# Send the HTTP GET request asynchronously
	var _get_store_cards: Error = await BKMREngine.send_get_request(GetCards, request_url)
	
	# Return the current Node
	return self

# Callback function triggered when the get cards request is completed.
# This function handles the response from the BKMREngine API after requesting store items.
# Parameters:
#   - _result: The result of the HTTP request.
#   - response_code: The HTTP response code.
#   - headers: The response headers.
#   - body: The response body containing store item data in a packed byte array.
# Returns:
#   - void
func _onGetCards_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check if the HTTP response is successful
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Free the request resources if the HTTP request instance is valid
	if is_instance_valid(GetCards):
		BKMREngine.free_request(wrGetCards, GetCards)
	
	# Process the response if the HTTP response is successful
	if status_check:
		# Parse the JSON response body and store the retrieved cards for sale
		var json_body: Array = JSON.parse_string(body.get_string_from_utf8())
		cards_for_sale = json_body
		
		# Emit the signal indicating that the get cards request is complete
		get_cards_complete.emit()

# Function to initiate the purchase of a card from the store.
# Parameters:
#   - token_id: The unique identifier of the card to be purchased.
#   - card_name: The name of the card being purchased.
#   - username: The username of the user making the purchase.
# Returns:
#   - Node: The current node (self).
func buy_card(token_id: String, card_name: String, username: String) -> Node:
	# Prepare HTTP request
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	BuyCard = prepared_http_req.request
	var buy_card: HTTPRequest = BuyCard
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
	BKMREngine.send_post_request(buy_card, request_url, payload)
	
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
