extends Node3D
## Slice 2 day/night: sun rotates AND gets dark at night.
## (Rotating the sun alone leaves the light on all night, so
## energy follows the sun angle: bright at noon, near-dark at night.)

@export var day_length_seconds: float = 1200.0
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

## Slice 62 seasons: the sun + sky tint by Myanmar season (summer
## warm-golden, rainy cool-dim, winter pale-clear). Energy is
## untouched, so the Slice 61 night floor (0.35) and the <0.15 dark
## rule hold in every season; ground/leaf tints + rain live in
## chill_controller62.gd. Falls back to summer without SaveManager.
func _season_mul() -> Color:
	var sm := get_node_or_null("/root/SaveManager")
	if sm == null or sm.get("season62") == null:
		return Color(1.0, 0.96, 0.86, 1.0)
	match clampi(int(sm.get("season62")), 0, 2):
		1:
			return Color(0.88, 0.93, 1.0, 1.0)
		2:
			return Color(0.96, 0.97, 1.0, 1.0)
		_:
			return Color(1.0, 0.96, 0.86, 1.0)

func _sky_top_for_daylight(day: float) -> Color:
	var noon := Color(0.30, 0.58, 0.95, 1.0)
	# Slice 99 dusk variant (owner OpenTaxi-look order): the
	# evening band (daylight 0.15..0.6) now leans warm pink
	# instead of the old violet, so dusk reads orange-pink
	# at the horizon fading to blue up top. Noon (day >= 0.6
	# endpoint) and deep night (day = 0) are UNCHANGED.
	var dusk := Color(0.62, 0.30, 0.52, 1.0)
	var night := Color(0.02, 0.03, 0.12, 1.0)
	if day >= 0.6:
		return dusk.lerp(noon, (day - 0.6) / 0.4)
	if day >= 0.15:
		return dusk.lerp(noon, (day - 0.15) / 0.45)
	return night.lerp(dusk, day / 0.15)

func _sky_horizon_for_daylight(day: float) -> Color:
	var noon := Color(0.70, 0.82, 1.0, 1.0)
	var dusk := Color(1.0, 0.58, 0.32, 1.0)
	var night := Color(0.07, 0.07, 0.18, 1.0)
	if day >= 0.6:
		return dusk.lerp(noon, (day - 0.6) / 0.4)
	if day >= 0.15:
		return dusk.lerp(noon, (day - 0.15) / 0.45)
	return night.lerp(dusk, day / 0.15)

func _process(delta: float) -> void:
	time += delta
	var angle := fmod(time / day_length_seconds * 360.0, 360.0)
	var sun := get_node_or_null(sun_path)
	if sun == null:
		return
	sun.rotation_degrees.x = angle - 90.0
	var day: float = daylight()
	sun.light_energy = 0.35 + day * 0.85  # Slice 61 addendum: night floor 0.05 -> 0.35 so the world reads at night; noon stays 1.20, daylight value (and the <0.15 dark rule) unchanged.
	# Visual atmosphere part 1: sun COLOUR follows time of day.
	# Noon is neutral white; low sun goes warm gold (golden hour);
	# night is a cool dim tint. Energy is unchanged, so the < 0.15
	# dark rule used by moon/stars/fireflies/headlights still holds.
	var dl := sun as DirectionalLight3D
	if dl != null:
		var base_c := _sun_color_for_daylight(day)
		var smul := _season_mul()
		dl.light_color = Color(base_c.r * smul.r, base_c.g * smul.g, base_c.b * smul.b, 1.0)
	# Slice 56 sky: gradient sky colours follow the same daylight
	# value (noon blue, low-sun pink/orange sunset, night dark).
	# The WorldEnvironment56 node is created at runtime by
	# city_visual56.dress(); if it is absent this is a no-op.
	var env56 := get_parent().get_node_or_null("WorldEnvironment56") as WorldEnvironment
	if env56 != null and env56.environment != null and env56.environment.sky != null:
		var smat := env56.environment.sky.sky_material as ProceduralSkyMaterial
		if smat != null:
			var skul := _season_mul()
			var top := _sky_top_for_daylight(day)
			var hor := _sky_horizon_for_daylight(day)
			smat.sky_top_color = Color(top.r * skul.r, top.g * skul.g, top.b * skul.b, 1.0)
			smat.sky_horizon_color = Color(hor.r * skul.r, hor.g * skul.g, hor.b * skul.b, 1.0)
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
