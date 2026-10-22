extends Control
## Slice 53 joystick, PUBG/MLBB-style: ROUND base and ROUND knob, no
## square panels. The discs are generated in code at _ready (no
## asset files) so their roundness is pixel-verifiable: corner
## pixels are transparent, the centre is opaque, the edge follows
## the disc radius.
##
## Slice 53 root-cause fix (read this before touching _gui_input):
## the old handler tested get_global_rect().has_point(event.position)
## to start a drag. But Godot delivers _gui_input event positions
## RELATIVE TO THE CONTROL'S ORIGIN (official Control docs:
## "The event's position is relative to this control's origin"),
## and the viewport itself already hit-tests delivery: _gui_input
## is only called for events inside the control. The joystick sits
## at canvas (30, 540), so a real touch at its visual centre
## (canvas 105, 615) arrived as local (75, 75), failed the global
## rect test (75 < 540), and fell into the else branch that zeroes
## the vector. EVERY real touch did this: the handle never moved
## and the player never moved, exactly as the owner's video shows.
## Headless probes missed it because they called _gui_input
## directly with GLOBAL coordinates, which passed the rect test.
## The fix: no rect check at all (delivery IS the hit test), and
## the drag math uses only differences, which are identical in
## local or global space, so this handler is correct under either
## coordinate reading. A second fix in the same rewrite: the old
## handler tracked NO touch index, so any second finger's release
## killed the first finger's drag. Now only the grabbing finger
## drives or releases the joystick.
##
## Floating base (PUBG-style): the control's rect is the whole
## left-bottom touch zone. On grab the base centres under the
## finger (clamped inside the zone); on release it returns home
## and the knob centres. The zone contains no other control, so
## the joystick can never be starved by an overlapping panel.
## Works with mouse on desktop because project.godot sets
## pointing/emulate_touch_from_mouse=true, and mouse events are
## also handled directly (sentinel index -2) so desktop works
## even if emulation is off. Emulated touch + raw mouse never
## double-grab: whichever grabs first wins, the other is ignored
## because grab_index is already taken.
## Slice 10 analog deadzone + Slice 32 setting kept verbatim:
## tiny accidental touches (under the setting, default 15% of the
## radius) output zero, the rest rescaled so full deflection is
## still full speed. The deadzone is read from SaveManager on
## every drag, and it is THE single deadzone for the game.

@export var player_path: NodePath
var dragging: bool = false
var grab_index: int = -1
var grab_pos: Vector2 = Vector2.ZERO
var radius: float = 60.0
var deadzone: float = 0.15
var base_home: Vector2 = Vector2.ZERO


func _effective_deadzone() -> float:
	var sm := get_node_or_null("/root/SaveManager")
	if sm == null:
		return deadzone
	return clampf(float(sm.get("joystick_deadzone")), 0.0, 0.4)


func _make_disc_texture(diameter: int, col: Color) -> ImageTexture:
	var img := Image.create(diameter, diameter, false, Image.FORMAT_RGBA8)
	var r := diameter / 2.0
	var centre := Vector2(r, r)
	for y in diameter:
		for x in diameter:
			if Vector2(x + 0.5, y + 0.5).distance_to(centre) <= r:
				img.set_pixel(x, y, col)
	var tex := ImageTexture.create_from_image(img)
	return tex


func _ready() -> void:
	var base := get_node_or_null("Base")
	if base != null:
		base_home = base.position
		base.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if base is TextureRect:
			base.texture = _make_disc_texture(150, Color(1, 1, 1, 0.25))
		var handle := get_node_or_null("Base/Handle")
		if handle != null:
			handle.mouse_filter = Control.MOUSE_FILTER_IGNORE
			if handle is TextureRect:
				handle.texture = _make_disc_texture(50, Color(1, 1, 1, 0.8))


func _to_local(pos: Vector2) -> Vector2:
	# Documented reading: _gui_input positions are already local,
	# and delivery guarantees they lie inside this rect, so they
	# pass through untouched. Defensive branch only: a position
	# outside the local rect but inside the canvas rect can only
	# be a canvas-space position (the old probe's reading); convert
	# it so the floating base still lands under the finger. This
	# branch never runs on a real device (docs rule it out), but it
	# makes the handler correct under either reading instead of
	# silently dead under one of them, as the old code was.
	if Rect2(Vector2.ZERO, size).has_point(pos):
		return pos
	return pos - get_global_position()


func _grab(index: int, pos: Vector2) -> void:
	if grab_index != -1:
		return
	grab_index = index
	dragging = true
	# Raw position is kept for the drag math: differences are
	# identical in local or canvas space, so the vector is correct
	# under either reading even when the finger drags outside the
	# zone (drag events keep coming to the grabbed control). The
	# converted position is used ONLY to place the floating base.
	grab_pos = pos
	var local_pos := _to_local(pos)
	var base := get_node_or_null("Base")
	if base != null and base is Control:
		var half := Vector2(base.size.x * 0.5, base.size.y * 0.5)
		var want := local_pos - half
		base.position = Vector2(
			clampf(want.x, 0.0, size.x - base.size.x),
			clampf(want.y, 0.0, size.y - base.size.y))


func _drag_to(pos: Vector2) -> void:
	var player := get_node_or_null(player_path)
	var diff: Vector2 = pos - grab_pos
	var dist: float = diff.length()
	if dist > radius:
		diff = diff.normalized() * radius
		dist = radius
	var handle := get_node_or_null("Base/Handle")
	if handle != null:
		handle.position = Vector2(50, 50) + diff
	if player != null:
		var dz: float = _effective_deadzone()
		var norm: float = dist / radius
		if norm < dz:
			player.touch_vector = Vector2.ZERO
		else:
			var scaled: float = (norm - dz) / (1.0 - dz)
			player.touch_vector = diff.normalized() * scaled


func _release(index: int) -> void:
	if grab_index != index:
		return
	grab_index = -1
	dragging = false
	var player := get_node_or_null(player_path)
	if player != null:
		player.touch_vector = Vector2.ZERO
	var base := get_node_or_null("Base")
	if base != null:
		base.position = base_home
	var handle := get_node_or_null("Base/Handle")
	if handle != null:
		handle.position = Vector2(50, 50)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_grab(event.index, event.position)
		else:
			_release(event.index)
	elif event is InputEventScreenDrag:
		if dragging and event.index == grab_index:
			_drag_to(event.position)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_grab(-2, event.position)
			else:
				_release(-2)
	elif event is InputEventMouseMotion:
		if dragging and grab_index == -2:
			_drag_to(event.position)
