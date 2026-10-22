extends Node3D

@export var day_length_seconds: float = 300.0
@onready var sun: DirectionalLight3D = $SunLight

var time_passed: float = 0.0

func _ready() -> void:
	add_to_group("day_night")

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
			sun.light_energy = 1.35
		elif daylight >= 0.15:
			# Authentic Myanmar Golden Hour warmth
			var t = (daylight - 0.15) / 0.45
			sun.light_color = Color(1.0, 0.78 + (0.2 * t), 0.48 + (0.44 * t), 1.0)
			sun.light_energy = 0.45 + (0.9 * t)
		else:
			# Cool serene lunar night
			sun.light_color = Color(0.42, 0.52, 0.78, 1.0)
			sun.light_energy = 0.15

		# Dynamic atmospheric procedural sky gradient modulation
		var world_env = get_tree().get_first_node_in_group("world_env")
		if not world_env:
			world_env = get_parent().get_node_or_null("WorldEnvironment")
		if world_env and world_env.environment:
			var env = world_env.environment
			if env.sky and env.sky.sky_material is ProceduralSkyMaterial:
				var sky_mat = env.sky.sky_material
				if daylight >= 0.6:
					# Crisp tropical blue sky
					sky_mat.sky_top_color = Color(0.24, 0.54, 0.88, 1.0)
					sky_mat.sky_horizon_color = Color(0.72, 0.81, 0.90, 1.0)
				elif daylight >= 0.15:
					# Vibrant Myanmar Sunset & Golden Hour gradient
					var t = (daylight - 0.15) / 0.45
					sky_mat.sky_top_color = Color(0.35, 0.22, 0.52, 1.0).lerp(Color(0.24, 0.54, 0.88, 1.0), t)
					sky_mat.sky_horizon_color = Color(0.96, 0.52, 0.28, 1.0).lerp(Color(0.72, 0.81, 0.90, 1.0), t)
				else:
					# Deep starlit tropical night
					sky_mat.sky_top_color = Color(0.04, 0.06, 0.12, 1.0)
					sky_mat.sky_horizon_color = Color(0.12, 0.14, 0.22, 1.0)
			
			# Modulate ambient light energy dynamically
			env.ambient_light_energy = lerpf(0.25, 0.95, daylight)

func get_daylight() -> float:
	if sun:
		var angle = wrapf(sun.rotation.x, 0.0, TAU)
		return clamp(-sin(angle), 0.0, 1.0)
	return 1.0