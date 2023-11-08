extends Node

var data: Dictionary = {}
var inventory_powerup: Dictionary
var player_stats: Dictionary
var inventory_card: Dictionary
var wallet_data: Dictionary
var profile_pics: Array
var username: String
var firstname: String
var lastname: String
var email: String
var wallet_address: String
var kmr_balance: String
var native_balance: String
var beats_balance: String
var thump_balance: String
var level: int
var player_experience: int
var player_rank: String
var stat_points: int
var stat_points_saved: Dictionary

func _ready() -> void:
	await BKMREngine.Auth.bkmr_session_check_complete
	# Check if data is empty and initialize it
	if data == {}:
		await BKMREngine.Auth.bkmr_login_complete
	# Check again after login, if data is still empty, return
	if data == {}:
		return
		
	# Parse and assign values to variables
	var powerup_inventory: String = data.powerUpInventory
	inventory_powerup = JSON.parse_string(powerup_inventory)
	
	var player_statistics: String = data.playerStats
	player_stats = JSON.parse_string(player_statistics)
	
	var card_inventory: String = data.cardInventory
	inventory_card = JSON.parse_string(card_inventory)
	
	wallet_data = data.wallet
	var smartwallet_address: String = wallet_data.smartWalletAddress
	wallet_address = formatAddress( smartwallet_address)
	var beats: String = wallet_data.beatsBalance
	beats_balance = format_balance(beats)
	var native: String = wallet_data.nativeBalance
	native_balance = format_balance(native)
	var kmr: String  = wallet_data.kmrBalance
	kmr_balance = format_balance(kmr)
	var thump_balance: String = wallet_data.thumpBalance
	thump_balance = format_balance(thump_balance)
	
	username = data.username
	firstname = data.firstName
	lastname = data.lastName
	email = data.email
	

	level = player_stats.level
	player_experience = player_stats.playerExp
	player_rank = player_stats.rank
	stat_points = player_stats.availStatPoints
	stat_points_saved = player_stats.statPointsSaved

func formatAddress(address: String) -> String:
	var firstFour: String = address.left(6)
	var lastFour: String = address.right(4)
	return firstFour + "..." + lastFour
	
func format_balance(value: String) -> String:
	var parts: Array = value.split(".")
	var wholePart: String = parts[0]
	
	# Add commas for every three digits in the whole part
	var formattedWholePart: String = ""
	var digitCount:int = 0
	for i: int in range(wholePart.length() - 1, -1, -1):
		formattedWholePart = wholePart[i] + formattedWholePart
		digitCount += 1
		if digitCount == 3 and i != 0:
			formattedWholePart = "," + formattedWholePart
			digitCount = 0
	return formattedWholePart
