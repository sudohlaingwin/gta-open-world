extends Node3D
## Slice 126 — every rideable genuinely drivable (2026-10-26).
## AUDIT FIRST (live headless, S125 tip complete):
## - probe126: all 16 vehicles enter/drive/turn/exit (146 checks,
##   1 fail = perf-day artifact, not a regression: the 55 s probe
##   had crossed into DAYTIME, and force_pass correctly returns
##   lights_off_now = 0 by day — S120: day = lights untouched.
##   sim126 forces DayNight time = 0 before the perf stage so the
##   night cull is actually measured).
## - AIRPLANE WEDGE (the one real defect, proven 3 ways):
##   parking spot (15,-15) facing -z: throttle 0.51 after 2 s but
##   moved only 1.77 m, then velocity 0 frozen while throttle rose
##   to 1.0. Open field (-200,0): same throttle flies to vel 50,
##   y 38 — the plane's physics is FINE. Slide collisions NAME the
##   blocker: Stilt13Solid, face at (16,1.0,-18.77) normal (0,0,1)
##   — the stilt-house solid's corner touches the plane's nose
##   box (2x1x4) at x = 16. Facing probe from the SAME spot: west
##   moved 24.97 m dy +4.41, north 18.55 m dy +2.29, east 19.44 m
##   dy +2.57 — all fly. The plane was parked facing into a wall.
## FIX (runtime dressing only, no .tscn edit): re-face the
## Airplane to west (rotation.y = PI/2) at dress time — the
## longest clear run, away from the village — only when it still
## sits at its scene facing (rotation.y ~ 0) and has no driver,
## so a future scene change or an already-driven plane is never
## yanked. Children (propeller, wheels, wings) rotate with it.
## DISCOVERABILITY: all 16 vehicles have minimap dots, but the
## world map had landmarks for only 3 (S125). world_map.gd
## LANDMARKS now covers the whole fleet (labels + colours).
## NO new beacons: map landmarks + minimap dots make every
## vehicle findable; beams on all 16 would be visual noise.
## DRIVING FEEL: camrel dots 0.53-0.94 across classes, joystick
## trace continuous, S125 lag re-run green — no feel changes.
## Bus/minibus/big bus, S119 menu, S121 models, S124 night,
## S125 beacons/ox/smooth-look untouched; no .tscn edits.
## Single pass at frame >= 700, after Realism125's 680.
var _frames: int = 0
var _done: bool = false
var _refaced: bool = false

static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("Realism126") != null:
		return
	var n := Node3D.new()
	n.name = "Realism126"
	n.set_script(load("res://realism126.gd"))
	world.call_deferred("add_child", n)

func _find(node: Node, nm: String) -> Node:
	if node.name == nm:
		return node
	for c in node.get_children():
		var f: Node = _find(c, nm)
		if f != null:
			return f
	return null

func _apply(world: Node3D) -> void:
	var plane: Node3D = _find(world, "Airplane") as Node3D
	if plane == null:
		return
	var driver: Variant = plane.get("driver")
	var rot: float = plane.rotation.y
	var wrapped: float = wrapf(rot, -PI, PI)
	if driver == null and absf(wrapped) < 0.01:
		plane.rotation.y = PI / 2.0
		_refaced = true

func _process(_delta: float) -> void:
	_frames += 1
	if not _done and _frames >= 700:
		_done = true
		var world: Node3D = get_parent() as Node3D
		if world != null:
			_apply(world)
