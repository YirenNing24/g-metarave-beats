extends Node

static func hash_values(values: Array) -> String:
	var to_be_hashed: String = ""
	for value: String in values:
		to_be_hashed = to_be_hashed + str(value)
	var hashed: String = to_be_hashed.md5_text()
	#print("Computed hashed: " + str(hashed))
	return hashed
