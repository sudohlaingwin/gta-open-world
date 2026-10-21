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
var deadzone: float = 0.15

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
			var norm: float = dist / radius
			if norm < deadzone:
				player.touch_vector = Vector2.ZERO
			else:
				var scaled: float = (norm - deadzone) / (1.0 - deadzone)
				player.touch_vector = diff.normalized() * scaled
