extends Control

@export var max_health: int = 100
@onready var ui_icon: Array = []
@onready var featured_icon = $"%FeaturedIcon"

var score_date
var score_time
var score
var score_acc: int = 0
var combo
var max_combo: int = 0
var acc
var perfect_note
var verygood_note
var good_note
var bad_note
var miss_note
var map
var health: int = 100
var final_stats
var note_stats
var song_length
var artist
var doubleup = 1
var string

var scoreboost: int = 0
var position_score: int = 0

func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
