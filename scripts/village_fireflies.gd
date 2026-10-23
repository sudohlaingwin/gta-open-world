extends GPUParticles3D

# --- Dynamic Diurnal Village Fireflies (ညအချိန်တွင် ပိုးစုန်းကြူးများ ထွက်ပေါ်ခြင်း) ---

@onready var firefly_light: OmniLight3D = get_node_or_null("FireflyAmbientGlow")

var _pulse_timer: float = 0.0

func _ready() -> void:
	emitting = false
	if firefly_light:
		firefly_light.visible = false

func _process(delta: float) -> void:
	_pulse_timer += delta * 1.5
	var day_night = get_tree().get_first_node_in_group("day_night")
	var is_night: bool = false
	var darkness_factor: float = 0.0

	if day_night and day_night.has_method("get_daylight"):
		var daylight = day_night.get_daylight()
		# Emit only at dusk / night when daylight drops below 0.40
		is_night = (daylight < 0.40)
		darkness_factor = clampf((0.40 - daylight) / 0.40, 0.0, 1.0)
	else:
		is_night = false

	emitting = is_night

	if firefly_light:
		firefly_light.visible = is_night
		if is_night:
			var pulse = 0.65 + 0.35 * sin(_pulse_timer)
			firefly_light.light_energy = 0.85 * darkness_factor * pulse

