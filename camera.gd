extends Camera3D
## Slice 2 camera: angled follow + orbit.
## Q/E rotate the view around the player (keyboard orbit, works
## without touch — the opponent's orbit is touch-drag only).
## Touch-drag orbit is a later slice; this is stated, not claimed.

@export var target: NodePath
@export var orbit_angle: float = 0.0

func _process(_delta: float) -> void:
	var t := get_node_or_null(target)
	if t == null:
		return
	if Input.is_physical_key_pressed(KEY_Q):
		orbit_angle += 0.02
	if Input.is_physical_key_pressed(KEY_E):
		orbit_angle -= 0.02
	var off := Vector3(sin(orbit_angle) * 10.0, 10.0, cos(orbit_angle) * 10.0)
	global_position = t.global_position + off
	look_at(t.global_position, Vector3.UP)
