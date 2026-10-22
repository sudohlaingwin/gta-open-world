extends Node3D
## Slice 2 day/night: sun rotates AND gets dark at night.
## (Rotating the sun alone leaves the light on all night, so
## energy follows the sun angle: bright at noon, near-dark at night.)

@export var day_length_seconds: float = 120.0
@export var sun_path: NodePath
@export var window_material: StandardMaterial3D
var time: float = 0.0

## Milestone 6 (part 2): one shared daylight value for every system
## that cares about time of day (traffic density/speed, villager
## schedules, headlights, moon/stars/fireflies). 0.0 is deep night,
## 1.0 is noon. The < 0.15 "dark" rule below is the same rule the
## moon, stars, fireflies, and Slice 22 headlights already used.
func daylight() -> float:
	if day_length_seconds <= 0.0:
		return 0.0
	var angle := fmod(time / day_length_seconds * 360.0, 360.0)
	return clampf(sin(deg_to_rad(angle)), 0.0, 1.0)

func _sun_color_for_daylight(day: float) -> Color:
	if day >= 0.6:
		return Color(1.0, 1.0, 1.0)
	if day >= 0.15:
		var t := (day - 0.15) / 0.45
		return Color(1.0, 0.75, 0.45).lerp(Color(1.0, 1.0, 1.0), t)
	return Color(0.45, 0.55, 0.85)

func _sky_top_for_daylight(day: float) -> Color:
	var noon := Color(0.30, 0.58, 0.95, 1.0)
	var sunset := Color(0.42, 0.32, 0.62, 1.0)
	var night := Color(0.02, 0.03, 0.12, 1.0)
	if day >= 0.6:
		return sunset.lerp(noon, (day - 0.6) / 0.4)
	if day >= 0.15:
		return sunset.lerp(noon, (day - 0.15) / 0.45)
	return night.lerp(sunset, day / 0.15)

func _sky_horizon_for_daylight(day: float) -> Color:
	var noon := Color(0.70, 0.82, 1.0, 1.0)
	var sunset := Color(1.0, 0.52, 0.30, 1.0)
	var night := Color(0.07, 0.07, 0.18, 1.0)
	if day >= 0.6:
		return sunset.lerp(noon, (day - 0.6) / 0.4)
	if day >= 0.15:
		return sunset.lerp(noon, (day - 0.15) / 0.45)
	return night.lerp(sunset, day / 0.15)

func _process(delta: float) -> void:
	time += delta
	var angle := fmod(time / day_length_seconds * 360.0, 360.0)
	var sun := get_node_or_null(sun_path)
	if sun == null:
		return
	sun.rotation_degrees.x = angle - 90.0
	var day: float = daylight()
	sun.light_energy = 0.05 + day * 1.15
	# Visual atmosphere part 1: sun COLOUR follows time of day.
	# Noon is neutral white; low sun goes warm gold (golden hour);
	# night is a cool dim tint. Energy is unchanged, so the < 0.15
	# dark rule used by moon/stars/fireflies/headlights still holds.
	var dl := sun as DirectionalLight3D
	if dl != null:
		dl.light_color = _sun_color_for_daylight(day)
	# Slice 56 sky: gradient sky colours follow the same daylight
	# value (noon blue, low-sun pink/orange sunset, night dark).
	# The WorldEnvironment56 node is created at runtime by
	# city_visual56.dress(); if it is absent this is a no-op.
	var env56 := get_parent().get_node_or_null("WorldEnvironment56") as WorldEnvironment
	if env56 != null and env56.environment != null and env56.environment.sky != null:
		var smat := env56.environment.sky.sky_material as ProceduralSkyMaterial
		if smat != null:
			smat.sky_top_color = _sky_top_for_daylight(day)
			smat.sky_horizon_color = _sky_horizon_for_daylight(day)
			smat.ground_bottom_color = Color(0.02, 0.03, 0.12, 1.0) if day < 0.15 else Color(0.25, 0.35, 0.25, 1.0)
			smat.ground_horizon_color = Color(0.07, 0.07, 0.18, 1.0) if day < 0.15 else Color(0.55, 0.60, 0.55, 1.0)
	# Night window lights: one shared emissive material on every
	# window mesh, toggled by the same < 0.15 dark rule. No new
	# lights per window, so this costs one material flag flip.
	if window_material != null:
		window_material.emission_enabled = day < 0.15
	# Slice 17 night sky: the moon and stars show only when dark.
	var moon := get_node_or_null("../Moon17")
	if moon != null:
		moon.visible = day < 0.15
	var stars := get_node_or_null("../Stars17")
	if stars != null:
		stars.visible = day < 0.15
	# Slice 18 fireflies: glow only when dark, like the moon/stars.
	var flies := get_node_or_null("../Fireflies18")
	if flies != null:
		flies.visible = day < 0.15
	# Slice 20 fireflies: same rule for the night-market swarm.
	var flies20 := get_node_or_null("../Fireflies20")
	if flies20 != null:
		flies20.visible = day < 0.15
