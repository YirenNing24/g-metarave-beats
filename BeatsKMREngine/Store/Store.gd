extends Node

const BKMRUtils: Script = preload("res://BeatsKMREngine/utils/BKMRUtils.gd")
const BKMRLogger: Script = preload("res://BeatsKMREngine/utils/BKMRLogger.gd")

# HTTPRequests for API calls
var GetValidCardUpgrades: HTTPRequest
var wrGetValidCardUpgrades: WeakRef = null
signal get_valid_card_upgrades_complete(cards: Array)

var GetValidCards: HTTPRequest
var wrGetValidCards: WeakRef = null
signal get_valid_cards_complete(cards: Array)


var GetValidCardPacks: HTTPRequest
var wrGetValidCardPacks: WeakRef = null
signal get_valid_card_packs_complete(cards: Array)

var BuyCard: HTTPRequest
var wrBuyCard: WeakRef = null
signal buy_card_complete(mesasge: Dictionary)

var BuyCardPack: HTTPRequest
var wrBuyCardPack: WeakRef = null
signal buy_card_pack_complete(message: Dictionary)


var BuyCardUpgradeItem: HTTPRequest
var wrBuyCardUpgradeItem: WeakRef = null
signal buy_card_upgrade_item_complete(message: Dictionary)

# Host URL for API calls
var host: String = BKMREngine.host


# Function to get store items based on item type.
func get_valid_cards() -> void:
	# Prepare HTTP request
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	GetValidCards = prepared_http_req.request
	wrGetValidCards = prepared_http_req.weakref
	
	# Connect the request_completed signal to the callback function
	var _get_cards: int = GetValidCards.request_completed.connect(_onGetValidCards_request_completed)
	
	# Log information about the API call
	BKMRLogger.info("Calling BKMREngine to get cards on sale data")
	
	# Construct the request URL
	var request_url: String = host + "/api/store/cards/valid"
	
	# Send the HTTP GET request asynchronously
	await BKMREngine.send_get_request(GetValidCards, request_url)


# Callback function triggered when the get cards request is completed.
func _onGetValidCards_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check if the HTTP response is successful
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Free the request resources if the HTTP request instance is valid
	if is_instance_valid(GetValidCards):
		BKMREngine.free_request(wrGetValidCards, GetValidCards)
	
	# Process the response if the HTTP response is successful
	if status_check:
		# Parse the JSON response body and store the retrieved cards for sale
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body.is_empty():
			get_valid_cards_complete.emit(json_body)
		elif json_body.has("error"):
			get_valid_cards_complete.emit(json_body)
		else:
			get_valid_cards_complete.emit(json_body)
		# Emit the signal indicating that the get cards request is complete
	else:
		get_valid_cards_complete.emit({"error": "Unknown server error"})


func get_valid_card_packs() -> void:
	# Prepare HTTP request
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	GetValidCardPacks = prepared_http_req.request
	wrGetValidCardPacks = prepared_http_req.weakref
	
	# Connect the request_completed signal to the callback function
	var _get_cards: int = GetValidCardPacks.request_completed.connect(_onGetValidCardPacks_request_completed)
	
	# Log information about the API call
	BKMRLogger.info("Calling BKMREngine to get cards on sale data")
	
	# Construct the request URL
	var request_url: String = host + "/api/store/card-packs/valid"
	
	# Send the HTTP GET request asynchronously
	BKMREngine.send_get_request(GetValidCardPacks, request_url)


# Callback function triggered when the get cards request is completed.
func _onGetValidCardPacks_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check if the HTTP response is successful
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Free the request resources if the HTTP request instance is valid
	if is_instance_valid(GetValidCardPacks):
		BKMREngine.free_request(wrGetValidCardPacks, GetValidCardPacks)
	
	# Process the response if the HTTP response is successful
	if status_check:
		# Parse the JSON response body and store the retrieved cards for sale
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body.is_empty():
			get_valid_card_packs_complete.emit([])
		elif json_body.has("error"):
			get_valid_card_packs_complete.emit(json_body)
		else:
			get_valid_card_packs_complete.emit(json_body)
		# Emit the signal indicating that the get cards request is complete
	else:
		get_valid_card_packs_complete.emit({"error": "Unknown server error"})
	
	
func buy_card_pack(uri: String, listing_id: int) -> void:
	# Prepare HTTP request
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	BuyCardPack = prepared_http_req.request
	wrBuyCardPack = prepared_http_req.weakref

	var _connect: int = BuyCardPack.request_completed.connect(_onBuyCardPack_request_completed)
	BKMRLogger.info("Calling BKMREngine to buy a card")
	
	var payload: Dictionary = { "listingId": listing_id, "uri": uri }
	BKMRLogger.debug("Validate buy card payload: " + str(payload))

	var request_url: String = host + "/api/store/card-packs/buy"
	BKMREngine.send_post_request(BuyCardPack, request_url, payload)
	
	
func _onBuyCardPack_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	if is_instance_valid(BuyCardPack):
		BKMREngine.free_request(wrBuyCardPack, BuyCardPack)
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
		# Check if the purchase was successful and log accordingly
			if json_body.has("success"):
				buy_card_pack_complete.emit(json_body)
			else:
				BKMRLogger.error("Purchase failed: " + str(json_body.error))
				buy_card_pack_complete.emit(json_body)
			# Emit the 'buy_card_complete' signal with the response body
			buy_card_pack_complete.emit(json_body)
		else:
			buy_card_pack_complete.emit({"error": "Unknown server error"})
	else:
		buy_card_pack_complete.emit({"error": "Unknown server error"})
	
	
# Function to initiate the purchase of a card from the store.
func buy_card(uri: String, listing_id: int) -> void:
	# Prepare HTTP request
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	BuyCard = prepared_http_req.request
	wrBuyCard = prepared_http_req.weakref

	var _connect: int = BuyCard.request_completed.connect(_onBuyCard_request_completed)
	BKMRLogger.info("Calling BKMREngine to buy a card")
	
	var payload: Dictionary = {"listingId": listing_id, "uri": uri}
	BKMRLogger.debug("Validate buy card payload: " + str(payload))

	var request_url: String = host + "/api/store/cards/buy"
	BKMREngine.send_post_request(BuyCard, request_url, payload)


# Callback function triggered upon the completion of the buy card request.
func _onBuyCard_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			print("hey hey hey1")
		# Check if the purchase was successful and log accordingly
			if json_body.has("error"):
				buy_card_complete.emit(json_body)
			else:
				buy_card_complete.emit(json_body)
				print("hey hey hey2")
		else:
			buy_card_complete.emit({"error": "Unknown server error"})
			
	else:
		buy_card_complete.emit({"error": "Unknown server error"})



# Function to initiate the purchase of a card from the store.
func buy_card_upgrade(card_upgrade_data: Dictionary) -> void:
	# Prepare HTTP request
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	BuyCardUpgradeItem = prepared_http_req.request
	wrBuyCardUpgradeItem = prepared_http_req.weakref

	var _connect: int = BuyCardUpgradeItem.request_completed.connect(_onBuyCardUpgrade_request_completed)
	BKMRLogger.info("Calling BKMREngine to buy a card")
	
	var payload: Dictionary = card_upgrade_data
	BKMRLogger.debug("Validate buy card payload: " + str(payload))

	var request_url: String = host + "/api/store/card-upgrade/buy"
	BKMREngine.send_post_request(BuyCardUpgradeItem, request_url, payload)
	

# Callback function triggered upon the completion of the buy card request.
func _onBuyCardUpgrade_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	# Process the result if the response is successful
	if status_check:
		# Parse the JSON response body
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		
		# Check if the purchase was successful and log accordingly
		if json_body.has("success"):
			BKMRLogger.info("Card upgrade purchase was successful.")
		else:
			BKMRLogger.error("Purchase failed: " + str(json_body.error))
		
		# Emit the 'buy_card_complete' signal with the response body
		buy_card_upgrade_item_complete.emit(json_body)


# Function to get store items based on item type.
func get_valid_card_upgrades() -> void:
	# Prepare HTTP request
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	GetValidCardUpgrades = prepared_http_req.request
	wrGetValidCardUpgrades = prepared_http_req.weakref
	
	# Connect the request_completed signal to the callback function
	var _get_cards: int = GetValidCardUpgrades.request_completed.connect(_onGetValidCardUpgrades_request_completed)
	
	# Log information about the API call
	BKMRLogger.info("Calling BKMREngine to get cards on sale data")
	
	# Construct the request URL
	var request_url: String = host + "/api/store/card-upgrades/valid"
	
	# Send the HTTP GET request asynchronously
	await BKMREngine.send_get_request(GetValidCardUpgrades, request_url)


# Callback function triggered when the get cards request is completed.
func _onGetValidCardUpgrades_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check if the HTTP response is successful
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Free the request resources if the HTTP request instance is valid
	if is_instance_valid(GetValidCardUpgrades):
		BKMREngine.free_request(wrGetValidCardUpgrades, GetValidCardUpgrades)
	
	# Process the response if the HTTP response is successful
	if status_check:
		# Parse the JSON response body and store the retrieved cards for sale
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body.is_empty():
			get_valid_card_upgrades_complete.emit(json_body)
		elif json_body.has("error"):
			get_valid_card_upgrades_complete.emit(json_body)
		else:
			get_valid_card_upgrades_complete.emit(json_body)
		# Emit the signal indicating that the get cards request is complete
	else:
		get_valid_card_upgrades_complete.emit({"error": "Unknown server error"})
	
