extends Control

var id: String


func signal_connect() -> void:
	BKMREngine.Profile.get_player_profile_pic_complete.connect(_on_get_player_profile_pic_complete)


func notification_slot_data(notif: Dictionary) -> void:
	signal_connect()
	id = notif.id
	match notif.type:
		"followed":
			set_type_followed_label(notif)
			
	
func set_type_followed_label(notif: Dictionary) -> void:
	%PlayerName.text = notif.sender
	%Type.text = "Followed you"
	
	var date: String = notif.date
	set_time_or_date(date)
	BKMREngine.Profile.get_player_profile_pic(notif.sender)
	

func set_time_or_date(date_time: String) -> void:
	# Get current UTC time
	var now: Dictionary = Time.get_time_dict_from_system(true)
	
	# Parse notification time (already in UTC)
	var notif_time: Dictionary = Time.get_datetime_dict_from_datetime_string(date_time, false)

	# Calculate the elapsed time in seconds
	var now_total_seconds: int = now["hour"] * 3600 + now["minute"] * 60 + now["second"]
	var notif_total_seconds: int = notif_time["hour"] * 3600 + notif_time["minute"] * 60 + notif_time["second"]
	var elapsed_seconds: int = now_total_seconds - notif_total_seconds

	# Handle case if the notification was sent on a different day
	if elapsed_seconds < 0:
		elapsed_seconds += 86400 # Add one day's worth of seconds if negative
	
	# Display the relative time
	if elapsed_seconds < 60:
		%Time.text = str(elapsed_seconds) + " seconds ago"
	elif elapsed_seconds < 3600:
		%Time.text = str(int(elapsed_seconds / 60.0)) + " minutes ago"
	elif elapsed_seconds < 86400:
		%Time.text = str(int(elapsed_seconds / 3600.0)) + " hours ago"
	else:
		var days_ago: int = int(elapsed_seconds / 86400.0)
		if days_ago < 7:
			%Time.text = str(days_ago) + " days ago"
		else:
			%Time.text = str(int(days_ago / 7.0)) + " weeks ago"


func _on_get_player_profile_pic_complete(profile_pics: Variant) -> void:
		if typeof(profile_pics) != TYPE_ARRAY:
			return
		for pic: Dictionary in profile_pics:
				var image: Image = Image.new()
				var first_image: String = profile_pics[0].profilePicture
				var display_image: PackedByteArray = JSON.parse_string(first_image)
				var error: Error = image.load_png_from_buffer(display_image)
				if error != OK:
					print("Error loading image", error)
				else:
					var display_pic: Texture =  ImageTexture.create_from_image(image)
					%ProfilePic.texture = display_pic
