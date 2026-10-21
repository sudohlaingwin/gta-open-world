extends Node3D
## Slice 2 day/night: sun rotates AND gets dark at night.
## (Rotating the sun alone leaves the light on all night, so
## energy follows the sun angle: bright at noon, near-dark at night.)

@export var day_length_seconds: float = 120.0
@export var sun_path: NodePath
var time: float = 0.0

func _process(delta: float) -> void:
	time += delta
	var angle := fmod(time / day_length_seconds * 360.0, 360.0)
	var sun := get_node_or_null(sun_path)
	if sun == null:
		return
	sun.rotation_degrees.x = angle - 90.0
	var daylight: float = clampf(sin(deg_to_rad(angle)), 0.0, 1.0)
	sun.light_energy = 0.05 + daylight * 1.15
	# Slice 17 night sky: the moon and stars show only when dark.
	var moon := get_node_or_null("../Moon17")
	if moon != null:
		moon.visible = daylight < 0.15
	var stars := get_node_or_null("../Stars17")
	if stars != null:
		stars.visible = daylight < 0.15
	# Slice 18 fireflies: glow only when dark, like the moon/stars.
	var flies := get_node_or_null("../Fireflies18")
	if flies != null:
		flies.visible = daylight < 0.15
	# Slice 20 fireflies: same rule for the night-market swarm.
	var flies20 := get_node_or_null("../Fireflies20")
	if flies20 != null:
		flies20.visible = daylight < 0.15
