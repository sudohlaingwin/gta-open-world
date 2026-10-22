extends Node3D
## Slice 2 day/night: sun rotates AND gets dark at night.
## (Rotating the sun alone leaves the light on all night, so
## energy follows the sun angle: bright at noon, near-dark at night.)

@export var day_length_seconds: float = 120.0
@export var sun_path: NodePath
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

func _process(delta: float) -> void:
	time += delta
	var angle := fmod(time / day_length_seconds * 360.0, 360.0)
	var sun := get_node_or_null(sun_path)
	if sun == null:
		return
	sun.rotation_degrees.x = angle - 90.0
	var day: float = daylight()
	sun.light_energy = 0.05 + day * 1.15
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
