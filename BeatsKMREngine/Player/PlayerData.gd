extends Node

var player_stats: Dictionary
var wallet_data: Dictionary
var profile_pics: Array

var username: String

var wallet_address: String
var gmr_balance: String
var native_balance: String
var beats_balance: String
var thump_balance: String

var level: int
var player_experience: int
var player_rank: String
var stat_points: int
var stat_points_saved: Dictionary

var current_energy: int 
var max_energy: int
var time_until_next_recharge: int 

var inventory_size: int 
var card_reward: Dictionary
var peer_id: int



func _ready() -> void:
	BKMREngine.Reward.get_available_card_reward_completed.connect(_on_get_available_card_reward)
	BKMREngine.Auth.bkmr_session_check_complete.connect(populate_player_data)
	BKMREngine.Auth.bkmr_login_complete.connect(populate_player_data)
	
	BKMREngine.Auth.bkmr_google_login_complete.connect(populate_player_data)
	
	BKMREngine.Auth.bkmr_google_login_passkey_verify_complete.connect(populate_player_data)
	BKMREngine.Auth.bkmr_google_registration_passkey_complete.connect(populate_player_data)
	

	
func _on_get_available_card_reward(reward_data: Dictionary) -> void:
	card_reward = reward_data


func populate_player_data(data: Dictionary) -> void:
	if !data.is_empty():
		if data.has("error"):
			return
		player_stats = data.playerStats
		current_energy = data.energy.energy
		max_energy = data.energy.maxEnergy
		
		
		print("energyy: ", data.energy)
		if data.energy.timeUntilNextRecharge != null:
			time_until_next_recharge = data.energy.timeUntilNextRecharge
		
		
		wallet_data = data.wallet
		var smartwallet_address: String = wallet_data.smartWalletAddress
		wallet_address = formatAddress(smartwallet_address)
		
		var beats: String = wallet_data.beatsBalance
		beats_balance = format_balance(beats)
		
		var native: String = wallet_data.nativeBalance
		native_balance = format_balance(native)
		
		var gmr: String  = wallet_data.gmrBalance
		gmr_balance = format_balance(gmr)
		
		username = data.username
		
		level = player_stats.level
		player_experience = player_stats.playerExp
		player_rank = player_stats.rank
		stat_points = player_stats.availStatPoints
		stat_points_saved = player_stats.statPointsSaved
		inventory_size = data.safeProperties.inventorySize.low
	else:
		return
		
		
# Function to format a wallet address for display.
func formatAddress(address: String) -> String:
	var firstFour: String = address.left(6)
	var lastFour: String = address.right(4)
	return firstFour + "..." + lastFour
	
	
# Function to format a balance value with commas for thousands.
func format_balance(value: String) -> String:
	var parts: Array = value.split(".")
	var wholePart: String = parts[0]
	
	# Add commas for every three digits in the whole part.
	var formattedWholePart: String = ""
	var digitCount: int = 0
	for i: int in range(wholePart.length() - 1, -1, -1):
		formattedWholePart = wholePart[i] + formattedWholePart
		digitCount += 1
		if digitCount == 3 and i != 0:
			formattedWholePart = "," + formattedWholePart
			digitCount = 0
	return formattedWholePart
