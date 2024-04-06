extends Node2D

const VU_COUNT: float = 16
const FREQ_MAX: float = 11050.0

const WIDTH: int = 800
const HEIGHT: int = 250

const MIN_DB: int = 60


var spectrum: AudioEffectInstance

func _draw() -> void:

	var w: float = WIDTH / VU_COUNT
	var prev_hz: float = 0
	for i: float in range(1, VU_COUNT + 1):
		var hz: float = i * FREQ_MAX / VU_COUNT
		var magnitude: float = spectrum.get_magnitude_for_frequency_range(prev_hz, hz).length()
		var energy: float = clampf((MIN_DB + linear_to_db(magnitude)) / MIN_DB, 0, 1)
		var height: float = energy * HEIGHT
		draw_rect(
				Rect2(w * i, HEIGHT - height, w - 2, height),
				Color.from_hsv(float(VU_COUNT * 0.6 + i * 0.5) / VU_COUNT, 0.5, 0.6)
		)
		draw_line(
				Vector2(w * i, HEIGHT - height),
				Vector2(w * i + w - 2, HEIGHT - height),
				Color.from_hsv(float(VU_COUNT * 0.6 + i * 0.5) / VU_COUNT, 0.5, 1.0),
				2.0,
				true
		)

		# Draw a reflection of the bars with lower opacity.
		draw_rect(
				Rect2(w * i, HEIGHT, w - 2, height),
				Color.from_hsv(float(VU_COUNT * 0.6 + i * 0.5) / VU_COUNT, 0.5, 0.6) * Color(1, 1, 1, 0.125)
		)
		draw_line(
				Vector2(w * i, HEIGHT + height),
				Vector2(w * i + w - 2, HEIGHT + height),
				Color.from_hsv(float(VU_COUNT * 0.6 + i * 0.5) / VU_COUNT, 0.5, 1.0) * Color(1, 1, 1, 0.125),
				2.0,
				true
		)
		prev_hz = hz

func _process(_delta: float) -> void:
	queue_redraw()


func _ready() -> void:
	spectrum = AudioServer.get_bus_effect_instance(0, 0)
	
