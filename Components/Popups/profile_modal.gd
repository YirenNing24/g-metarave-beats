extends Control

# Player UI elements
@onready var player_name: Label =  %PlayerName
@onready var level: Label = %Level
@onready var player_rank: Label = %PlayerRank
@onready var wallet_address: Label = %WalletAddress
@onready var animation_player: AnimationPlayer = %AnimationPlayer

# Initialization function called when the node is ready.
func _ready() -> void:
	# Display player statistics
	stat_display()

# Display player statistics.
#
# This function updates UI elements with player statistics, such as player name, level, rank, and wallet address.
# It connects the logout complete signal to the _on_Logout_Complete function for handling logout events.
#
# Parameters:
# - No explicit parameters are passed to this function.
#
# Returns:
# - This function does not return a value; it operates by updating UI elements and connecting signals.
#
# Example usage:
# ```gdscript
# stat_display()
# ```
func stat_display() -> void:
	player_name.text = BKMREngine.Auth.logged_in_player
	level.text = str(PLAYER.level)
	player_rank.text = PLAYER.player_rank
	wallet_address.text = PLAYER.wallet_address
	BKMREngine.Auth.bkmr_logout_complete.connect(_on_Logout_Complete)

# Handle visibility change.
#
# This function is triggered when the visibility of the control changes. 
# It plays a fade-in animation when the control becomes visible.
#
# Parameters:
# - No explicit parameters are passed to this function.
#
# Returns:
# - This function does not return a value; it operates by playing a fade-in animation.
#
# Example usage:
# ```gdscript
# _on_visibility_changed()
# ```
func _on_visibility_changed() -> void:
	if visible:
		animation_player.play("fade-in")

# Handle logout button press.
#
# This function is triggered when the logout button is pressed. 
# It initiates the logout process for the player, quits the game, and waits for the logout to complete.
#
# Parameters:
# - No explicit parameters are passed to this function.
#
# Returns:
# - This function does not return a value; it operates by initiating the logout process and quitting the game.
#
# Example usage:
# ```gdscript
# _on_logout_button_pressed()
# ```
func _on_logout_button_pressed() -> void:
	# Logout the player and quit the game
	BKMREngine.Auth.logout_player()
	await BKMREngine.Auth.bkmr_logout_complete
	get_tree().quit()
	

# Handle logout completion.
#
# This function is triggered when the logout process is complete. 
# It sets the textures for the scene transition, loading the authentication screen scene asynchronously.
#
# Parameters:
# - No explicit parameters are passed to this function.
#
# Returns:
# - This function does not return a value; it operates by setting textures for the scene transition and loading the authentication screen scene.
#
# Example usage:
# ```gdscript
# _on_Logout_Complete()
# ```
func _on_Logout_Complete() -> void:
	# Set textures for scene transition
	LOADER.previous_texture = load("res://UITextures/BGTextures/main.png")
	LOADER.next_texture = load("res://UITextures/BGTextures/auth.png")
	
	# Load the authentication screen scene asynchronously
	var _auth_screen: int = await LOADER.load_scene(self, "res://UIScenes/auth_screen.tscn")
