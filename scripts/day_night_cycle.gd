extends Node3D

@export var day_length_seconds: float = 120.0
@onready var sun: DirectionalLight3D = $SunLight

var time_passed: float = 0.0

func _process(delta: float) -> void:
	time_passed += delta
	if sun:
		var rotation_rate = 360.0 / day_length_seconds
		sun.rotate_x(deg_to_rad(rotation_rate * delta))
		
		# Compute dynamic daylight intensity (0.0 night -> 1.0 noon)
		var angle = wrapf(sun.rotation.x, 0.0, TAU)
		var daylight = clamp(-sin(angle), 0.0, 1.0)
		
		# Dynamic Golden Hour sunlight color palette
		if daylight >= 0.6:
			# High noon clean tropical sunlight
			sun.light_color = Color(1.0, 0.98, 0.92, 1.0)
			sun.light_energy = 1.2
		elif daylight >= 0.15:
			# Authentic Myanmar Golden Hour warmth
			var t = (daylight - 0.15) / 0.45
			sun.light_color = Color(1.0, 0.78 + (0.2 * t), 0.48 + (0.44 * t), 1.0)
			sun.light_energy = 0.4 + (0.8 * t)
		else:
			# Cool serene lunar night
			sun.light_color = Color(0.42, 0.52, 0.78, 1.0)
			sun.light_energy = 0.12

func get_daylight() -> float:
	if sun:
		var angle = wrapf(sun.rotation.x, 0.0, TAU)
		return clamp(-sin(angle), 0.0, 1.0)
	return 1.0