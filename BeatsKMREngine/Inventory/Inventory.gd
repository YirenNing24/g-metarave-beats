extends Node

# Preloaded scripts for utility functions and logging.
const BKMRUtils: Script = preload("res://BeatsKMREngine/utils/BKMRUtils.gd")
const BKMRLogger: Script = preload("res://BeatsKMREngine/utils/BKMRLogger.gd")

signal get_card_inventory_complete(card_inventory_data: Array)
signal get_bag_inventory_complete(bag_inventory_data: Array)
signal get_card_upgrade_inventory_complete(upgrade_inventory_data: Array)
signal get_card_pack_inventory_complete(card_pack_inventory_data: Array)
signal get_group_card_equipped_complete(card_equipped: Array)

signal group_card_equip_complete(cards: Array)

signal equip_item_complete(message: Dictionary)
signal unequip_item_complete(message: Dictionary)
# var BKMREngine.host: String = BKMREngine.BKMREngine.host

var OpenCardInventory: HTTPRequest
var wrOpenCardInventory: WeakRef

var OpenGroupCardEquipped: HTTPRequest
var wrOpenGroupCardEquipped: WeakRef


var GroupCardEquip: HTTPRequest
var wrGroupCardEquip: WeakRef

var OpenCardUpgradeInventory: HTTPRequest
var wrOpenCardUpgradeInventory: WeakRef

var OpenBagInventory: HTTPRequest
var wrOpenBagInventory: WeakRef


var CardPackInventory: HTTPRequest
var wrCardPackInventory: WeakRef

var EquipItem: HTTPRequest
var wrEquipItem: WeakRef

var UnequipItem: HTTPRequest
var wrUnequipItem: WeakRef

var card_inventory: Dictionary
var bag_inventory: Dictionary


#region Card Inventory
func open_card_inventory() -> void:
	# Prepare an HTTP request for fetching private inbox data.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	OpenCardInventory = prepared_http_req.request
	wrOpenCardInventory  = prepared_http_req.weakref
	
	# Connect the callback function to handle the completion of the private inbox data request.
	var _cards: int = OpenCardInventory.request_completed.connect(_onOpenCardInventory_request_completed)
	
	# Log the initiation of the request to retrieve inbox messages.
	BKMRLogger.info("Calling BKMREngine to get card inventory data")
	
	# Construct the request URL for fetching private inbox data for the specified user.
	var request_url: String = BKMREngine.host + "/api/card/inventory/open"
	
	# Send a GET request to retrieve the private inbox data.
	BKMREngine.send_get_request(OpenCardInventory, request_url)



# Callback function to handle the completion of the private inbox data retrieval request.
func _onOpenCardInventory_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check if the HTTP response indicates success.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)

	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body.has("error"):
			BKMRLogger.info(json_body.error)
		else:
			get_card_inventory_complete.emit(json_body)
	else:
		get_card_inventory_complete.emit({"error": "Unable to retrieve inventory"})


func open_group_card_equipped(group_name: String) -> void:
	# Prepare an HTTP request for fetching private inbox data.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	OpenGroupCardEquipped = prepared_http_req.request
	wrOpenGroupCardEquipped  = prepared_http_req.weakref
	
	var _cards: int = OpenGroupCardEquipped.request_completed.connect(_onOpenGroupCardEquipped_request_completed)
	
	var request_url: String = BKMREngine.host + "/api/card/inventory/group-equipped" + group_name
	BKMREngine.send_get_request(OpenGroupCardEquipped, request_url)


func _onOpenGroupCardEquipped_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check if the HTTP response indicates success.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body.has("error"):
				BKMRLogger.info(json_body.error)
			else:
				get_group_card_equipped_complete.emit(json_body)
		else:
			get_group_card_equipped_complete.emit({"error": "Unable to retrieve inventory"})
	else:
		get_group_card_equipped_complete.emit({"error": "Unable to retrieve inventory"})


func group_card_equipped(group_name: String) -> void:
	# Prepare an HTTP request for fetching private inbox data.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	GroupCardEquip = prepared_http_req.request
	wrGroupCardEquip  = prepared_http_req.weakref
	
	var _cards: int = GroupCardEquip.request_completed.connect(_onGroupCardEquipped_request_completed)
	
	var request_url: String = BKMREngine.host + "/api/card/inventory/equip-group/" + group_name
	BKMREngine.send_get_request(GroupCardEquip, request_url)


func _onGroupCardEquipped_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check if the HTTP response indicates success.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body.has("error"):
				BKMRLogger.info(json_body.error)
			else:
				group_card_equip_complete.emit(json_body)
		else:
			group_card_equip_complete.emit({ "error": "Unable to retrieve inventory" })
	else:
		group_card_equip_complete.emit({"error": "Unable to retrieve inventory"})







#endregion


func open_card_upgrade_inventory() -> void:
	# Prepare an HTTP request for fetching private inbox data.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	OpenCardUpgradeInventory = prepared_http_req.request
	wrOpenCardUpgradeInventory  = prepared_http_req.weakref
	
	# Connect the callback function to handle the completion of the private inbox data request.
	var _cards: int = OpenCardUpgradeInventory.request_completed.connect(_onOpenCardUpgradeInventory_request_completed)
	
	# Log the initiation of the request to retrieve inbox messages.
	BKMRLogger.info("Calling BKMREngine to get card inventory data")
	
	# Construct the request URL for fetching private inbox data for the specified user.
	var request_url: String = BKMREngine.host + "/api/upgrade/inventory/open"
	
	# Send a GET request to retrieve the card upgrade items
	BKMREngine.send_get_request(OpenCardUpgradeInventory, request_url)
	
	
# Callback function to handle the completion of the private inbox data retrieval request.
func _onOpenCardUpgradeInventory_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check if the HTTP response indicates success.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)

	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body.has("error"):
			BKMRLogger.info(json_body.error)
			get_card_upgrade_inventory_complete.emit({"error": json_body.error})
		else:
			get_card_upgrade_inventory_complete.emit(json_body)
	else:
		get_card_upgrade_inventory_complete.emit({"error": "Unable to retrieve inventory"})
#endregion


#region Bag Inventory
func open_bag_inventory() -> Node:
	# Prepare an HTTP request for fetching private inbox data.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	OpenBagInventory = prepared_http_req.request
	wrOpenBagInventory  = prepared_http_req.weakref
	
	# Connect the callback function to handle the completion of the private inbox data request.
	var _cards: int = OpenBagInventory.request_completed.connect(_onOpenBagInventory_request_completed)
	
	# Log the initiation of the request to retrieve inbox messages.
	BKMRLogger.info("Calling BKMREngine to get card inventory data")
	
	# Construct the request URL for fetching private inbox data for the specified user.
	var request_url: String = BKMREngine.host + "/api/bag/inventory/open"
	
	# Send a GET request to retrieve the private inbox data.
	await BKMREngine.send_get_request(OpenBagInventory, request_url)
	
	# Return the current node for method chaining.
	return self as Node


# Callback function to handle the completion of the private inbox data retrieval request.
func _onOpenBagInventory_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check if the HTTP response indicates success.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Free the HTTP request resource if it is still valid.
	if is_instance_valid(OpenBagInventory):
		BKMREngine.free_request(wrOpenBagInventory, OpenBagInventory)
	
	# If the HTTP response indicates success, parse the JSON response body.
	if status_check:
		# Parse the JSON response body.
		var json_body: Dictionary = JSON.parse_string(body.get_string_from_utf8())
		if json_body.has("error"):
			BKMRLogger.info(json_body.error)
		else:
			# Emit the 'get_inbox_messages_complete' signal to notify the completion of private inbox data retrieval.
			get_bag_inventory_complete.emit(json_body)
			bag_inventory = json_body
			
			
func open_card_pack_inventory() -> void:
	# Prepare an HTTP request for fetching private inbox data.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	CardPackInventory = prepared_http_req.request
	wrCardPackInventory = prepared_http_req.weakref
	
	# Connect the callback function to handle the completion of the private inbox data request.
	var _cards: int = CardPackInventory.request_completed.connect(_onOpenCardPackInventory_request_completed)
	
	# Log the initiation of the request to retrieve inbox messages.
	BKMRLogger.info("Calling BKMREngine to get card inventory data")
	
	# Construct the request URL for fetching private inbox data for the specified user.
	var request_url: String = BKMREngine.host + "/api/card-pack/inventory/open"
	
	# Send a GET request to retrieve the private inbox data.
	BKMREngine.send_get_request(CardPackInventory, request_url)


# Callback function to handle the completion of the private inbox data retrieval request.
func _onOpenCardPackInventory_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check if the HTTP response indicates success.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# Free the HTTP request resource if it is still valid.
	if is_instance_valid(CardPackInventory):
		BKMREngine.free_request(wrCardPackInventory, CardPackInventory)
	
	# If the HTTP response indicates success, parse the JSON response body.
	if status_check:
		# Parse the JSON response body.
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body.has("error"):
				BKMRLogger.info(json_body.error)
			else:
				# Emit the 'get_inbox_messages_complete' signal to notify the completion of private inbox data retrieval.
				get_card_pack_inventory_complete.emit(json_body)
		else:
			get_card_pack_inventory_complete.emit({"error": "Unknown server error" })
			
	else:
		get_card_pack_inventory_complete.emit({"error": "Unknown server error" })
			
			
			
#endregion


#region Equip / Unequip Item
func equip_item(equip_item_data: Array) -> void:
	# Prepare an HTTP request for fetching private inbox data.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	EquipItem = prepared_http_req.request
	wrEquipItem = prepared_http_req.weakref
	
	# Connect the callback function to handle the completion of the private inbox data request.
	var _cards: int = EquipItem.request_completed.connect(_onEquipItem_request_completed)
	
	# Log the initiation of the request to retrieve inbox messages.
	BKMRLogger.info("Calling BKMREngine to get card inventory data")
	
	# Construct the request URL for fetching private inbox data for the specified user.
	var request_url: String = BKMREngine.host + "/api/card/inventory/equip-item"
	var payload: Array = equip_item_data
	# Send a GET request to retrieve the private inbox data.
	BKMREngine.send_post_request(EquipItem, request_url, payload)
	
func _onEquipItem_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check if the HTTP response indicates success.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# If the HTTP response indicates success, parse the JSON response body.
	if status_check:
		# Parse the JSON response body.
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body.has("error"):
				BKMRLogger.info(json_body.error)
			else:
				# Emit the 'get_inbox_messages_complete' signal to notify the completion of private inbox data retrieval.
				equip_item_complete.emit(json_body)
		else:
			equip_item_complete.emit({"error": "Unknown server error"})
	else:
		equip_item_complete.emit({"error": "Unknown server error"})


func unequip_item(unequip_item_data: Array) -> void:
	# Prepare an HTTP request for fetching private inbox data.
	var prepared_http_req: Dictionary = BKMREngine.prepare_http_request()
	UnequipItem = prepared_http_req.request
	wrUnequipItem = prepared_http_req.weakref
	
	# Connect the callback function to handle the completion of the private inbox data request.
	var _cards: int = UnequipItem.request_completed.connect(_onUnequipItem_request_completed)
	
	# Log the initiation of the request to retrieve inbox messages.
	BKMRLogger.info("Calling BKMREngine to get card inventory data")
	
	# Construct the request URL for fetching private inbox data for the specified user.
	var request_url: String = BKMREngine.host + "/api/card/inventory/unequip-item"
	var payload: Array = unequip_item_data
	# Send a GET request to retrieve the private inbox data.
	BKMREngine.send_post_request(UnequipItem, request_url, payload)


func _onUnequipItem_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check if the HTTP response indicates success.
	var status_check: bool = BKMRUtils.check_http_response(response_code, headers, body)
	
	# If the HTTP response indicates success, parse the JSON response body.
	if status_check:
		# Parse the JSON response body.
		var json_body: Dictionary = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body.has("error"):
				BKMRLogger.info(json_body.error)
			else:
				# Emit the 'get_inbox_messages_complete' signal to notify the completion of private inbox data retrieval.
				unequip_item_complete.emit(json_body)
		else:
			unequip_item_complete.emit({"error": "Unknown server error"})
	else:
		unequip_item_complete.emit({"error": "Unknown server error"})
#endregion
