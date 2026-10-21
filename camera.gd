extends Camera3D
## Slice 2 camera: angled follow + orbit.
## Q/E rotate the view around the player (keyboard orbit, works
## without touch — the opponent's orbit is touch-drag only).
## Touch-drag orbit is a later slice; this is stated, not claimed.

@export var target: NodePath
@export var orbit_angle: float = 0.0
# Slice 10 camera controls (touch-first): zoom factor for the
# Zoom + / - buttons, and touch-drag orbit on the right half of
# the screen (the joystick lives on the left, so the halves do not
# fight). Q/E remain desktop fallbacks only.
var zoom: float = 1.0

func zoom_in() -> void:
	zoom = clamp(zoom - 0.2, 0.6, 1.8)

func zoom_out() -> void:
	zoom = clamp(zoom + 0.2, 0.6, 1.8)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		var vp := get_viewport().get_visible_rect().size
		if event.position.x > vp.x * 0.5:
			orbit_angle += event.relative.x * 0.005

func _process(_delta: float) -> void:
	var t := get_node_or_null(target)
	if t == null:
		return
	if Input.is_physical_key_pressed(KEY_Q):
		orbit_angle += 0.02
	if Input.is_physical_key_pressed(KEY_E):
		orbit_angle -= 0.02
	var dist := 10.0 * zoom
	var off := Vector3(sin(orbit_angle) * dist, 10.0 * zoom, cos(orbit_angle) * dist)
	global_position = t.global_position + off
	look_at(t.global_position, Vector3.UP)
