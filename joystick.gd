extends Control
## Slice 2 joystick: WIRED to the player (unlike an unconnected
## signal). Drag inside this control; the player walks that way.
## Works with mouse on desktop because project.godot sets
## pointing/emulate_touch_from_mouse=true.

@export var player_path: NodePath
var dragging: bool = false
var start_pos: Vector2 = Vector2.ZERO
var radius: float = 60.0
# Slice 10 analog deadzone: tiny accidental touches (under 15% of
# the radius) output zero instead of creeping, and the rest of the
# range is rescaled so full deflection still means full speed.
# Slice 32: the deadzone is a setting, not a constant. It is read
# from SaveManager on every drag, so a change made in the pause
# Settings screen takes effect immediately, and it is THE single
# deadzone for the whole game: player movement and every vehicle
# (car, motorcycle, tuk-tuk, and the rest) all steer from
# touch_vector, which is what this filter produces. Falls back to
# 0.15 when SaveManager is absent (headless test without autoloads).
var deadzone: float = 0.15


func _effective_deadzone() -> float:
	var sm := get_node_or_null("/root/SaveManager")
	if sm == null:
		return deadzone
	return clampf(float(sm.get("joystick_deadzone")), 0.0, 0.4)

func _gui_input(event: InputEvent) -> void:
	var player := get_node_or_null(player_path)
	if event is InputEventScreenTouch:
		if event.pressed and get_global_rect().has_point(event.position):
			dragging = true
			start_pos = event.position
		else:
			dragging = false
			if player != null:
				player.touch_vector = Vector2.ZERO
			$Base/Handle.position = Vector2(50, 50)
	elif event is InputEventScreenDrag and dragging:
		var diff: Vector2 = event.position - start_pos
		var dist: float = diff.length()
		if dist > radius:
			diff = diff.normalized() * radius
			dist = radius
		$Base/Handle.position = Vector2(50, 50) + diff
		if player != null:
			var dz: float = _effective_deadzone()
			var norm: float = dist / radius
			if norm < dz:
				player.touch_vector = Vector2.ZERO
			else:
				var scaled: float = (norm - dz) / (1.0 - dz)
				player.touch_vector = diff.normalized() * scaled
