extends StaticBody3D

# --- Dynamic Diurnal Night Market Lighting (ညအချိန်တွင် မီးသီးမီးလုံးများ လင်းထိန်ခြင်း) ---

@onready var lights: Array = [
	$VisualMesh/Bulb1/OmniLight3D,
	$VisualMesh/Bulb2/OmniLight3D,
	$VisualMesh/Bulb3/OmniLight3D
]

func _ready() -> void:
	_update_lights()

func _process(delta: float) -> void:
	_update_lights()

func _update_lights() -> void:
	var day_night = get_parent().get_node_or_null("DayNightCycle")
	var is_night = true
	if day_night and day_night.has_method("get_daylight"):
		is_night = (day_night.get_daylight() < 0.35)

	for l in lights:
		if l:
			l.visible = is_night
