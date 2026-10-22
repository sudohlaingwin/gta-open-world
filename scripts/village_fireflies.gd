extends GPUParticles3D

# --- Dynamic Diurnal Village Fireflies (ညအချိန်တွင် ပိုးစုန်းကြူးများ ထွက်ပေါ်ခြင်း) ---

func _ready() -> void:
	emitting = false

func _process(delta: float) -> void:
	var day_night = get_tree().get_first_node_in_group("day_night")
	if day_night and day_night.has_method("get_daylight"):
		var daylight = day_night.get_daylight()
		# Emit only at dusk / night when daylight drops below 0.35
		emitting = (daylight < 0.35)
	else:
		emitting = false
